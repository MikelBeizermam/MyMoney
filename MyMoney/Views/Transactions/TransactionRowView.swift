import SwiftUI

struct TransactionRowView: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: transaction.category.colorHex).opacity(0.2))
                    .frame(width: 46, height: 46)
                Text(transaction.category.emoji)
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.merchant)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("₪\(transaction.amount, specifier: "%.0f")")
                    .font(.subheadline.bold())
                    .foregroundStyle(.accentRed)
                Text(transaction.card.rawValue)
                    .font(.caption)
                    .foregroundStyle(transaction.card == .isracard ? .isracardColor : .calColor)
            }
        }
        .padding(.vertical, 6)
    }
}
