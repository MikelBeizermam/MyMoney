import Foundation
import SwiftData

@Model
final class SavingsGoal {
    var monthlyIncome: Double
    var savingsTargetPercent: Double
    var createdAt: Date

    // MARK: Sync metadata
    /// Each user has a single goal, so in the cloud its id equals the user's id.
    var id: UUID = UUID()
    var userId: UUID? = nil
    var updatedAt: Date = Date.now
    var needsSync: Bool = true

    init(monthlyIncome: Double, savingsTargetPercent: Double) {
        self.monthlyIncome = monthlyIncome
        self.savingsTargetPercent = savingsTargetPercent
        self.createdAt = .now
        self.id = UUID()
        self.updatedAt = .now
        self.needsSync = true
    }

    var savingsTarget: Double {
        monthlyIncome * savingsTargetPercent
    }

    var spendingBudget: Double {
        monthlyIncome - savingsTarget
    }

    func markChanged() {
        updatedAt = .now
        needsSync = true
    }
}
