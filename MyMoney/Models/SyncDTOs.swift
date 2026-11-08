import Foundation

/// Row shape of `public.transactions` in Supabase.
struct TransactionDTO: Codable {
    let id: UUID
    let userId: UUID
    let amount: Double
    let merchant: String
    let date: Date
    let category: String
    let card: String
    let notes: String
    let updatedAt: Date
    let deletedAt: Date?
    /// Server-assigned write time (kept as the raw string for exact microsecond precision),
    /// used as the incremental pull cursor. Never sent by the client.
    let syncedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, amount, merchant, date, category, card, notes
        case userId = "user_id"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case syncedAt = "synced_at"
    }

    init(_ model: Transaction, userId: UUID) {
        id = model.id
        self.userId = userId
        amount = model.amount
        merchant = model.merchant
        date = model.date
        category = model.categoryRaw
        card = model.cardRaw
        notes = model.notes
        updatedAt = model.updatedAt
        deletedAt = model.deletedAt
        syncedAt = nil
    }

    // Explicit encoder: always send `deleted_at` (even as null) so every object in a
    // bulk upsert has the same keys, and never send `synced_at`.
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(userId, forKey: .userId)
        try c.encode(amount, forKey: .amount)
        try c.encode(merchant, forKey: .merchant)
        try c.encode(date, forKey: .date)
        try c.encode(category, forKey: .category)
        try c.encode(card, forKey: .card)
        try c.encode(notes, forKey: .notes)
        try c.encode(updatedAt, forKey: .updatedAt)
        try c.encode(deletedAt, forKey: .deletedAt)
    }

    func apply(to model: Transaction) {
        model.amount = amount
        model.merchant = merchant
        model.date = date
        model.categoryRaw = category
        model.cardRaw = card
        model.notes = notes
        model.updatedAt = updatedAt
        model.deletedAt = deletedAt
        model.userId = userId
        model.needsSync = false
    }

    func makeModel() -> Transaction {
        let model = Transaction(
            amount: amount,
            merchant: merchant,
            date: date,
            category: Category(rawValue: category) ?? .other,
            card: CardType(rawValue: card) ?? .isracard,
            notes: notes
        )
        model.id = id
        apply(to: model)
        return model
    }
}

/// Row shape of `public.savings_goals` in Supabase (one row per user, `id == user_id`).
struct SavingsGoalDTO: Codable {
    let id: UUID
    let userId: UUID
    let monthlyIncome: Double
    let savingsTargetPercent: Double
    let createdAt: Date
    let updatedAt: Date
    let syncedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case monthlyIncome = "monthly_income"
        case savingsTargetPercent = "savings_target_percent"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case syncedAt = "synced_at"
    }

    init(_ model: SavingsGoal, userId: UUID) {
        id = userId
        self.userId = userId
        monthlyIncome = model.monthlyIncome
        savingsTargetPercent = model.savingsTargetPercent
        createdAt = model.createdAt
        updatedAt = model.updatedAt
        syncedAt = nil
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(userId, forKey: .userId)
        try c.encode(monthlyIncome, forKey: .monthlyIncome)
        try c.encode(savingsTargetPercent, forKey: .savingsTargetPercent)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(updatedAt, forKey: .updatedAt)
    }

    func apply(to model: SavingsGoal) {
        model.id = id
        model.userId = userId
        model.monthlyIncome = monthlyIncome
        model.savingsTargetPercent = savingsTargetPercent
        model.createdAt = createdAt
        model.updatedAt = updatedAt
        model.needsSync = false
    }
}
