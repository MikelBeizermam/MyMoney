import SwiftUI
import SwiftData

struct TransactionsView: View {
    @Query(filter: #Predicate<Transaction> { $0.deletedAt == nil }, sort: \Transaction.date, order: .reverse)
    private var transactions: [Transaction]
    @Environment(\.modelContext) private var modelContext
    @Environment(SyncService.self) private var sync
    @State private var selectedCard: CardType? = nil
    @State private var selectedCategory: Category? = nil
    @State private var showAddSheet = false

    private var filtered: [Transaction] {
        transactions.filter {
            (selectedCard == nil || $0.card == selectedCard) &&
            (selectedCategory == nil || $0.category == selectedCategory)
        }
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                filterBar

                if filtered.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(filtered) { transaction in
                            TransactionRowView(transaction: transaction)
                                .listRowBackground(Color.cardBG)
                                .listRowSeparatorTint(Color.white.opacity(0.08))
                        }
                        .onDelete(perform: delete)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .navigationTitle("עסקאות")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.accentGreen)
                        .font(.title3)
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddTransactionView()
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "הכל", isSelected: selectedCard == nil && selectedCategory == nil) {
                    selectedCard = nil; selectedCategory = nil
                }
                FilterChip(title: "ישראכארט", isSelected: selectedCard == .isracard, color: .isracardColor) {
                    selectedCard = selectedCard == .isracard ? nil : .isracard
                }
                FilterChip(title: "כאל", isSelected: selectedCard == .cal, color: .calColor) {
                    selectedCard = selectedCard == .cal ? nil : .cal
                }
                Divider().frame(height: 18).padding(.horizontal, 4)
                ForEach(Category.allCases, id: \.self) { category in
                    FilterChip(title: "\(category.emoji) \(category.rawValue)", isSelected: selectedCategory == category) {
                        selectedCategory = selectedCategory == category ? nil : category
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color.cardBG)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(.textSecondary)
            Text("אין עסקאות")
                .font(.title3.bold())
                .foregroundStyle(.white)
            Text("הוסף עסקה ידנית או הגדר Shortcut")
                .font(.subheadline)
                .foregroundStyle(.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func delete(at offsets: IndexSet) {
        // Soft delete so the deletion also reaches the cloud and other devices.
        for index in offsets {
            filtered[index].softDelete()
        }
        sync.requestSync()
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var color: Color = .accentGreen
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color : Color.appBackground)
                .foregroundStyle(isSelected ? .black : .white)
                .cornerRadius(20)
        }
    }
}
