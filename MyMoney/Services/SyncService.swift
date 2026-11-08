import Foundation
import Observation
import SwiftData
import Supabase

/// Offline-first sync between the local SwiftData store and Supabase.
///
/// * Every local change marks the row `needsSync`.
/// * A sync cycle first **pulls** rows changed on the server since the last cursor
///   (server-assigned `synced_at`), merging with last-write-wins on `updated_at`,
///   then **pushes** dirty rows with a bulk upsert.
/// * Deletions are soft (`deleted_at`) so they propagate to other devices.
/// * The database also enforces last-write-wins with a trigger, so a stale device can
///   never overwrite newer data.
@MainActor
@Observable
final class SyncService {
    enum Status: Equatable {
        case idle
        case syncing
        case failed(String)
    }

    private(set) var status: Status = .idle
    private(set) var lastSyncedAt: Date?

    private let context: ModelContext
    private var userId: UUID?
    private var isRunning = false
    private var rerunRequested = false
    private var debounceTask: Task<Void, Never>?

    private static let pageSize = 500

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Session lifecycle

    /// Called after sign-in. Claims data created before login and runs a full sync.
    func activate(userId: UUID) async {
        guard self.userId != userId else { return }
        self.userId = userId
        lastSyncedAt = UserDefaults.standard.object(forKey: lastSyncKey(userId)) as? Date
        claimLocalData(for: userId)
        await sync()
    }

    /// Called after sign-out. Removes the previous user's data from this device.
    func deactivate() {
        debounceTask?.cancel()
        userId = nil
        lastSyncedAt = nil
        status = .idle
        try? context.delete(model: Transaction.self)
        try? context.delete(model: SavingsGoal.self)
        try? context.save()
    }

    var hasPendingChanges: Bool {
        let tx = (try? context.fetchCount(FetchDescriptor<Transaction>(predicate: #Predicate { $0.needsSync }))) ?? 0
        let goals = (try? context.fetchCount(FetchDescriptor<SavingsGoal>(predicate: #Predicate { $0.needsSync }))) ?? 0
        return tx + goals > 0
    }

    // MARK: - Triggering

    /// Coalesces bursts of local edits into one network round-trip.
    func requestSync() {
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(800))
            guard !Task.isCancelled else { return }
            await self?.sync()
        }
    }

    func sync() async {
        guard let userId else { return }
        if isRunning {
            rerunRequested = true
            return
        }
        isRunning = true
        status = .syncing
        defer { isRunning = false }

        do {
            try context.save()
            try await pull(userId: userId)
            try await push(userId: userId)
            try context.save()
            let now = Date.now
            lastSyncedAt = now
            UserDefaults.standard.set(now, forKey: lastSyncKey(userId))
            status = .idle
        } catch is CancellationError {
            status = .idle
        } catch {
            status = .failed(Self.describe(error))
        }

        if rerunRequested {
            rerunRequested = false
            isRunning = false
            await sync()
        }
    }

    // MARK: - Claiming anonymous data

    /// Data created before the first login has no owner – attach it to this user.
    /// Data that belongs to a different user (should never survive sign-out) is removed.
    private func claimLocalData(for userId: UUID) {
        let transactions = (try? context.fetch(FetchDescriptor<Transaction>())) ?? []
        for t in transactions {
            if t.userId == nil {
                t.userId = userId
                t.markChanged()
            } else if t.userId != userId {
                context.delete(t)
            }
        }

        let goals = (try? context.fetch(FetchDescriptor<SavingsGoal>())) ?? []
        for g in goals {
            if g.userId == nil {
                g.userId = userId
                g.id = userId
                g.markChanged()
            } else if g.userId != userId {
                context.delete(g)
            }
        }
        try? context.save()
    }

    // MARK: - Pull

    private func pull(userId: UUID) async throws {
        try await pullTransactions(userId: userId)
        try await pullGoal(userId: userId)
    }

    private func pullTransactions(userId: UUID) async throws {
        var cursor = UserDefaults.standard.string(forKey: cursorKey("transactions", userId))

        var local: [UUID: Transaction] = [:]
        for t in try context.fetch(FetchDescriptor<Transaction>()) { local[t.id] = t }

        while true {
            var query = SupabaseService.client
                .from("transactions")
                .select()
                .eq("user_id", value: userId)
            if let cursor { query = query.gt("synced_at", value: cursor) }

            let page: [TransactionDTO] = try await query
                .order("synced_at", ascending: true)
                .limit(Self.pageSize)
                .execute()
                .value

            for dto in page {
                if let existing = local[dto.id] {
                    // Local unsynced edit is newer – keep it, it will be pushed next.
                    if existing.needsSync && existing.updatedAt > dto.updatedAt { continue }
                    if dto.deletedAt != nil {
                        context.delete(existing)
                        local[dto.id] = nil
                    } else {
                        dto.apply(to: existing)
                    }
                } else if dto.deletedAt == nil {
                    let model = dto.makeModel()
                    context.insert(model)
                    local[dto.id] = model
                }
            }

            if let last = page.last?.syncedAt {
                cursor = Self.cursorString(last)
                UserDefaults.standard.set(cursor, forKey: cursorKey("transactions", userId))
            }
            if page.count < Self.pageSize { break }
        }
    }

    private func pullGoal(userId: UUID) async throws {
        let rows: [SavingsGoalDTO] = try await SupabaseService.client
            .from("savings_goals")
            .select()
            .eq("user_id", value: userId)
            .limit(1)
            .execute()
            .value
        guard let remote = rows.first else { return }

        let goals = try context.fetch(FetchDescriptor<SavingsGoal>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]))
        if let current = goals.first {
            // Only one goal per user – drop any duplicates.
            goals.dropFirst().forEach { context.delete($0) }
            if current.needsSync && current.updatedAt > remote.updatedAt { return }
            remote.apply(to: current)
        } else {
            let model = SavingsGoal(monthlyIncome: remote.monthlyIncome, savingsTargetPercent: remote.savingsTargetPercent)
            remote.apply(to: model)
            context.insert(model)
        }
    }

    // MARK: - Push

    private func push(userId: UUID) async throws {
        let dirty = try context.fetch(FetchDescriptor<Transaction>(predicate: #Predicate { $0.needsSync }))
        for chunk in dirty.chunked(into: Self.pageSize) {
            let snapshot = chunk.map { ($0, $0.updatedAt) }
            let payload = chunk.map { TransactionDTO($0, userId: userId) }
            try await SupabaseService.client.from("transactions").upsert(payload).execute()

            for (model, sentVersion) in snapshot where model.updatedAt == sentVersion {
                if model.deletedAt != nil {
                    context.delete(model)          // tombstone is now on the server
                } else {
                    model.needsSync = false
                }
            }
        }

        let dirtyGoals = try context.fetch(FetchDescriptor<SavingsGoal>(predicate: #Predicate { $0.needsSync }))
        if let goal = dirtyGoals.max(by: { $0.updatedAt < $1.updatedAt }) {
            goal.id = userId
            goal.userId = userId
            let sentVersion = goal.updatedAt
            try await SupabaseService.client.from("savings_goals").upsert(SavingsGoalDTO(goal, userId: userId)).execute()
            if goal.updatedAt == sentVersion { goal.needsSync = false }
        }
    }

    // MARK: - Helpers

    private func lastSyncKey(_ userId: UUID) -> String { "sync.lastSyncedAt.\(userId.uuidString)" }
    private func cursorKey(_ table: String, _ userId: UUID) -> String { "sync.cursor.\(table).\(userId.uuidString)" }

    /// PostgREST returns e.g. `2026-11-08T10:00:00.123456+00:00`; a literal `+` in a query
    /// string can be read as a space, so normalise the UTC offset to `Z`.
    private static func cursorString(_ raw: String) -> String {
        raw.hasSuffix("+00:00") ? String(raw.dropLast(6)) + "Z" : raw
    }

    private static func describe(_ error: Error) -> String {
        if error is URLError { return "אין חיבור לאינטרנט – השינויים נשמרו במכשיר ויסונכרנו בהמשך." }
        return "הסנכרון נכשל. ננסה שוב אוטומטית."
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map { Array(self[$0..<Swift.min($0 + size, count)]) }
    }
}
