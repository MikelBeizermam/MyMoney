import Foundation
import SwiftData

enum CardType: String, Codable, CaseIterable {
    case isracard = "ישראכארט"
    case cal = "כאל"

    var colorHex: String {
        switch self {
        case .isracard: return "FF6B6B"
        case .cal: return "60A5FA"
        }
    }
}

enum Category: String, Codable, CaseIterable {
    case supermarket = "סופרמרקט"
    case restaurants = "מסעדות"
    case fuel = "דלק ותחבורה"
    case health = "בריאות"
    case shopping = "קניות"
    case entertainment = "בידור"
    case education = "חינוך"
    case housing = "דיור"
    case coffee = "קפה"
    case other = "בית עסק לא מוכר"

    var emoji: String {
        switch self {
        case .supermarket:   return "🛒"
        case .restaurants:   return "🍔"
        case .fuel:          return "⛽"
        case .health:        return "💊"
        case .shopping:      return "👕"
        case .entertainment: return "🎬"
        case .education:     return "📚"
        case .housing:       return "🏠"
        case .coffee:        return "☕"
        case .other:         return "💳"
        }
    }

    var colorHex: String {
        switch self {
        case .supermarket:   return "4ADE80"
        case .restaurants:   return "FB923C"
        case .fuel:          return "60A5FA"
        case .health:        return "F472B6"
        case .shopping:      return "A78BFA"
        case .entertainment: return "FBBF24"
        case .education:     return "34D399"
        case .housing:       return "F87171"
        case .coffee:        return "D97706"
        case .other:         return "9CA3AF"
        }
    }
}

@Model
final class Transaction {
    var id: UUID
    var amount: Double
    var merchant: String
    var date: Date
    var categoryRaw: String
    var cardRaw: String
    var notes: String

    // MARK: Sync metadata (defaults allow lightweight migration of existing stores)
    /// Owner in Supabase. `nil` for data created before the user ever signed in.
    var userId: UUID? = nil
    /// Last local modification – used for last-write-wins conflict resolution.
    var updatedAt: Date = Date.now
    /// Soft delete marker so deletions can be synced to other devices.
    var deletedAt: Date? = nil
    /// `true` while the row has local changes not yet pushed to the cloud.
    var needsSync: Bool = true

    init(
        amount: Double,
        merchant: String,
        date: Date = .now,
        category: Category = .other,
        card: CardType,
        notes: String = ""
    ) {
        self.id = UUID()
        self.amount = amount
        self.merchant = merchant
        self.date = date
        self.categoryRaw = category.rawValue
        self.cardRaw = card.rawValue
        self.notes = notes
        self.updatedAt = .now
        self.needsSync = true
    }

    var category: Category {
        get { Category(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var card: CardType {
        get { CardType(rawValue: cardRaw) ?? .isracard }
        set { cardRaw = newValue.rawValue }
    }

    func markChanged() {
        updatedAt = .now
        needsSync = true
    }

    func softDelete() {
        deletedAt = .now
        markChanged()
    }
}
