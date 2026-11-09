import SwiftUI
import SwiftData

/// Adds a new transaction, or edits an existing one when `existing` is set.
struct AddTransactionView: View {
    var existing: Transaction? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) private var auth
    @Environment(SyncService.self) private var sync

    @State private var amount = ""
    @State private var merchant = ""
    @State private var selectedCard: CardType = .isracard
    @State private var selectedCategory: Category = .other
    /// Once the user picks a category by hand, stop auto-classifying from the merchant name.
    @State private var categoryTouched = false
    @State private var date = Date()
    @State private var notes = ""
    @State private var confirmDelete = false
    @State private var loaded = false

    private var isEditing: Bool { existing != nil }
    private var parsedAmount: Double? {
        Double(amount.replacingOccurrences(of: ",", with: ".")).flatMap { $0 > 0 ? $0 : nil }
    }

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
                                if !categoryTouched && !new.isEmpty {
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

                    Section {
                        Picker("קטגוריה", selection: Binding(
                            get: { selectedCategory },
                            set: { selectedCategory = $0; categoryTouched = true }
                        )) {
                            ForEach(Category.allCases, id: \.self) { category in
                                Text("\(category.emoji) \(category.rawValue)").tag(category)
                            }
                        }
                    } header: {
                        Text("קטגוריה")
                    } footer: {
                        if !categoryTouched && !merchant.isEmpty && !isEditing {
                            Text("זוהתה אוטומטית לפי שם בית העסק")
                        }
                    }
                    .listRowBackground(Color.cardBG)

                    Section("הערה") {
                        TextField("לא חובה", text: $notes, axis: .vertical)
                            .lineLimit(1...4)
                    }
                    .listRowBackground(Color.cardBG)

                    if isEditing {
                        Section {
                            Button("מחק עסקה", role: .destructive) { confirmDelete = true }
                                .frame(maxWidth: .infinity)
                        }
                        .listRowBackground(Color.cardBG)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(isEditing ? "עריכת עסקה" : "עסקה חדשה")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("שמור", action: save)
                        .bold()
                        .foregroundStyle(.accentGreen)
                        .disabled(parsedAmount == nil || merchant.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("ביטול") { dismiss() }
                        .foregroundStyle(.textSecondary)
                }
            }
            .confirmationDialog("למחוק את העסקה?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("מחק", role: .destructive, action: delete)
                Button("ביטול", role: .cancel) {}
            }
            .environment(\.layoutDirection, .rightToLeft)
        }
        .onAppear(perform: loadExisting)
    }

    private func loadExisting() {
        guard let existing, !loaded else { return }
        loaded = true
        amount = existing.amount.formatted(.number.grouping(.never).precision(.fractionLength(0...2)))
        merchant = existing.merchant
        selectedCard = existing.card
        selectedCategory = existing.category
        categoryTouched = true
        date = existing.date
        notes = existing.notes
    }

    private func save() {
        guard let value = parsedAmount else { return }
        let name = merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        let note = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        if let existing {
            existing.amount = value
            existing.merchant = name
            existing.date = date
            existing.card = selectedCard
            existing.category = selectedCategory
            existing.notes = note
            existing.markChanged()
        } else {
            let transaction = Transaction(
                amount: value,
                merchant: name,
                date: date,
                category: selectedCategory,
                card: selectedCard,
                notes: note
            )
            transaction.userId = auth.userId
            modelContext.insert(transaction)
        }
        sync.requestSync()
        dismiss()
    }

    private func delete() {
        existing?.softDelete()
        sync.requestSync()
        dismiss()
    }
}
