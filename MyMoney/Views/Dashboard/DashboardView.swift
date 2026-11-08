import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Query(filter: #Predicate<Transaction> { $0.deletedAt == nil }, sort: \Transaction.date, order: .reverse)
    private var transactions: [Transaction]

    private var thisMonthTransactions: [Transaction] {
        let start = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: .now))!
        return transactions.filter { $0.date >= start }
    }

    private var total: Double { thisMonthTransactions.reduce(0) { $0 + $1.amount } }
    private var isracardTotal: Double { thisMonthTransactions.filter { $0.card == .isracard }.reduce(0) { $0 + $1.amount } }
    private var calTotal: Double { thisMonthTransactions.filter { $0.card == .cal }.reduce(0) { $0 + $1.amount } }

    private var categoryTotals: [(Category, Double)] {
        let grouped = Dictionary(grouping: thisMonthTransactions) { $0.category }
        return grouped.map { ($0.key, $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.1 > $1.1 }
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    headerView
                    totalCard
                    cardBreakdown
                    if !categoryTotals.isEmpty { categoryChartCard }
                    recentTransactionsCard
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    // MARK: - Sections

    private var headerView: some View {
        HStack {
            VStack(alignment: .trailing, spacing: 2) {
                Text("שלום 👋")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text(currentMonthLabel)
                    .font(.subheadline)
                    .foregroundStyle(.textSecondary)
            }
            Spacer()
        }
        .padding(.top, 8)
    }

    private var totalCard: some View {
        VStack(spacing: 8) {
            Text("סה\"כ הוצאות החודש")
                .font(.subheadline)
                .foregroundStyle(.textSecondary)
            Text("₪\(total, specifier: "%.0f")")
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(Color.cardBG)
        .cornerRadius(24)
    }

    private var cardBreakdown: some View {
        HStack(spacing: 12) {
            CardSummaryTile(name: "ישראכארט", amount: isracardTotal, color: .isracardColor)
            CardSummaryTile(name: "כאל", amount: calTotal, color: .calColor)
        }
    }

    private var categoryChartCard: some View {
        VStack(alignment: .trailing, spacing: 16) {
            Text("לפי קטגוריה")
                .font(.headline)
                .foregroundStyle(.white)

            Chart(categoryTotals, id: \.0) { item in
                BarMark(
                    x: .value("סכום", item.1),
                    y: .value("קטגוריה", "\(item.0.emoji) \(item.0.rawValue)")
                )
                .foregroundStyle(Color(hex: item.0.colorHex))
                .cornerRadius(6)
            }
            .chartXAxis(.hidden)
            .frame(height: CGFloat(min(categoryTotals.count, 6)) * 44)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(20)
        .background(Color.cardBG)
        .cornerRadius(24)
    }

    private var recentTransactionsCard: some View {
        VStack(alignment: .trailing, spacing: 14) {
            Text("עסקאות אחרונות")
                .font(.headline)
                .foregroundStyle(.white)

            if transactions.isEmpty {
                Text("אין עסקאות עדיין")
                    .foregroundStyle(.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            } else {
                ForEach(transactions.prefix(5)) { transaction in
                    TransactionRowView(transaction: transaction)
                    if transaction.id != transactions.prefix(5).last?.id {
                        Divider().background(Color.white.opacity(0.08))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(20)
        .background(Color.cardBG)
        .cornerRadius(24)
    }

    private var currentMonthLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "he_IL")
        f.dateFormat = "MMMM yyyy"
        return f.string(from: .now)
    }
}

struct CardSummaryTile: View {
    let name: String
    let amount: Double
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(name)
                .font(.caption)
                .foregroundStyle(.textSecondary)
            Text("₪\(amount, specifier: "%.0f")")
                .font(.title2.bold())
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.cardBG)
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(color.opacity(0.35), lineWidth: 1.5))
    }
}
