import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) private var auth
    @Environment(SyncService.self) private var sync

    @State private var amount = ""
    @State private var merchant = ""
    @State private var selectedCard: CardType = .isracard
    @State private var selectedCategory: Category = .other
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                Form {
                    Section("פרטי עסקה") {
                        TextField("סכום ב-₪", text: $amount)
                            .keyboardType(.decimalPad)
                        TextField("שם בית עסק", text: $merchant)
                            .onChange(of: merchant) { _, new in
                                if selectedCategory == .other && !new.isEmpty {
                                    selectedCategory = CategoryClassifier.classify(new)
                                }
                            }
                        DatePicker("תאריך", selection: $date, displayedComponents: .date)
                            .environment(\.locale, Locale(identifier: "he_IL"))
                    }
                    .listRowBackground(Color.cardBG)

                    Section("כרטיס") {
                        Picker("כרטיס", selection: $selectedCard) {
                            ForEach(CardType.allCases, id: \.self) { card in
                                Text(card.rawValue).tag(card)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .listRowBackground(Color.cardBG)

                    Section("קטגוריה") {
                        Picker("קטגוריה", selection: $selectedCategory) {
                            ForEach(Category.allCases, id: \.self) { category in
                                Text("\(category.emoji) \(category.rawValue)").tag(category)
                            }
                        }
                    }
                    .listRowBackground(Color.cardBG)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("עסקה חדשה")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("שמור", action: save)
                        .bold()
                        .foregroundStyle(.accentGreen)
                        .disabled(amount.isEmpty || merchant.isEmpty)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("ביטול") { dismiss() }
                        .foregroundStyle(.textSecondary)
                }
            }
            .environment(\.layoutDirection, .rightToLeft)
        }
    }

    private func save() {
        let cleaned = amount.replacingOccurrences(of: ",", with: ".")
        guard let amountDouble = Double(cleaned) else { return }
        let transaction = Transaction(
            amount: amountDouble,
            merchant: merchant,
            date: date,
            category: selectedCategory,
            card: selectedCard
        )
        transaction.userId = auth.userId
        modelContext.insert(transaction)
        sync.requestSync()
        dismiss()
    }
}
