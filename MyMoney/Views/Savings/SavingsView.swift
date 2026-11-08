import SwiftUI
import SwiftData

struct SavingsView: View {
    @Query private var goals: [SavingsGoal]
    @Query(filter: #Predicate<Transaction> { $0.deletedAt == nil }, sort: \Transaction.date, order: .reverse)
    private var transactions: [Transaction]
    @Environment(\.modelContext) private var modelContext
    @State private var showSetup = false

    private var goal: SavingsGoal? { goals.first }

    private var spentThisMonth: Double {
        let start = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: .now))!
        return transactions.filter { $0.date >= start }.reduce(0) { $0 + $1.amount }
    }

    private var safeToSpend: Double {
        (goal?.spendingBudget ?? 0) - spentThisMonth
    }

    private var savingsProgress: Double {
        guard let g = goal, g.savingsTarget > 0 else { return 0 }
        let saved = max(0, g.monthlyIncome - spentThisMonth)
        return min(1.0, saved / g.savingsTarget)
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    if let g = goal {
                        goalCard(g)
                        safeToSpendCard
                        progressCard
                        budgetBreakdownCard(g)
                    } else {
                        emptyState
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("חיסכון")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showSetup = true
                } label: {
                    Image(systemName: goal == nil ? "plus.circle.fill" : "pencil.circle.fill")
                        .foregroundStyle(.accentGreen)
                        .font(.title3)
                }
            }
        }
        .sheet(isPresented: $showSetup) {
            SavingsSetupView(existing: goal)
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    // MARK: - Cards

    private func goalCard(_ g: SavingsGoal) -> some View {
        VStack(spacing: 8) {
            Text("יעד חיסכון חודשי")
                .font(.subheadline)
                .foregroundStyle(.textSecondary)
            Text("₪\(g.savingsTarget, specifier: "%.0f")")
                .font(.system(size: 50, weight: .bold, design: .rounded))
                .foregroundStyle(.accentGreen)
            Text("\(Int(g.savingsTargetPercent * 100))% מההכנסה")
                .font(.caption)
                .foregroundStyle(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(Color.cardBG)
        .cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.accentGreen.opacity(0.3), lineWidth: 1.5))
    }

    private var safeToSpendCard: some View {
        VStack(spacing: 8) {
            Text("בטוח להוציא עוד החודש")
                .font(.subheadline)
                .foregroundStyle(.textSecondary)
            Text("₪\(max(0, safeToSpend), specifier: "%.0f")")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(safeToSpend >= 0 ? .accentGreen : .accentRed)
            if safeToSpend < 0 {
                Text("חרגת ב-₪\(abs(safeToSpend), specifier: "%.0f") מהתקציב")
                    .font(.caption.bold())
                    .foregroundStyle(.accentRed)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.cardBG)
        .cornerRadius(24)
    }

    private var progressCard: some View {
        VStack(alignment: .trailing, spacing: 14) {
            HStack {
                Text("\(Int(savingsProgress * 100))%")
                    .font(.title3.bold())
                    .foregroundStyle(.accentGreen)
                Spacer()
                Text("התקדמות חיסכון")
                    .font(.subheadline)
                    .foregroundStyle(.white)
            }
            ProgressView(value: savingsProgress)
                .tint(.accentGreen)
                .scaleEffect(x: 1, y: 2.5, anchor: .center)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.cardBG)
        .cornerRadius(24)
    }

    private func budgetBreakdownCard(_ g: SavingsGoal) -> some View {
        VStack(alignment: .trailing, spacing: 14) {
            Text("פירוט תקציב")
                .font(.headline)
                .foregroundStyle(.white)

            BudgetRow(label: "הכנסה חודשית", amount: g.monthlyIncome, color: .accentGreen)
            Divider().background(Color.white.opacity(0.08))
            BudgetRow(label: "יעד חיסכון", amount: g.savingsTarget, color: .accentBlue)
            BudgetRow(label: "תקציב הוצאות", amount: g.spendingBudget, color: .white)
            Divider().background(Color.white.opacity(0.08))
            BudgetRow(label: "הוצאתי עד כה", amount: spentThisMonth, color: .accentRed)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(20)
        .background(Color.cardBG)
        .cornerRadius(24)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "piggybank.fill")
                .font(.system(size: 64))
                .foregroundStyle(.textSecondary)
            Text("הגדר יעד חיסכון")
                .font(.title3.bold())
                .foregroundStyle(.white)
            Text("הזן את ההכנסה החודשית שלך ויעד החיסכון\nכדי שנדע כמה בטוח להוציא")
                .font(.subheadline)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
            Button("הגדרת יעד") { showSetup = true }
                .buttonStyle(.borderedProminent)
                .tint(.accentGreen)
                .foregroundStyle(.black)
                .bold()
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color.cardBG)
        .cornerRadius(24)
    }
}

struct BudgetRow: View {
    let label: String
    let amount: Double
    let color: Color

    var body: some View {
        HStack {
            Text("₪\(amount, specifier: "%.0f")")
                .font(.subheadline.bold())
                .foregroundStyle(color)
            Spacer()
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.textSecondary)
        }
    }
}

// MARK: - Setup Sheet

struct SavingsSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) private var auth
    @Environment(SyncService.self) private var sync
    let existing: SavingsGoal?

    @State private var income = ""
    @State private var savingsPercent = 20.0

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                VStack(spacing: 24) {
                    incomeInput
                    savingsSlider
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("הגדרת חיסכון")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("שמור", action: save)
                        .bold()
                        .foregroundStyle(.accentGreen)
                        .disabled(income.isEmpty)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("ביטול") { dismiss() }
                        .foregroundStyle(.textSecondary)
                }
            }
            .environment(\.layoutDirection, .rightToLeft)
            .onAppear {
                if let e = existing {
                    income = String(Int(e.monthlyIncome))
                    savingsPercent = e.savingsTargetPercent * 100
                }
            }
        }
    }

    private var incomeInput: some View {
        VStack(spacing: 8) {
            Text("הכנסה חודשית נטו")
                .font(.subheadline)
                .foregroundStyle(.textSecondary)
            TextField("₪ 0", text: $income)
                .keyboardType(.numberPad)
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.cardBG)
        .cornerRadius(20)
    }

    private var savingsSlider: some View {
        VStack(spacing: 14) {
            HStack {
                if let d = Double(income) {
                    Text("₪\(d * savingsPercent / 100, specifier: "%.0f")")
                        .font(.title3.bold())
                        .foregroundStyle(.accentGreen)
                }
                Spacer()
                Text("יעד חיסכון: \(Int(savingsPercent))%")
                    .font(.subheadline)
                    .foregroundStyle(.white)
            }
            Slider(value: $savingsPercent, in: 5...50, step: 5)
                .tint(.accentGreen)
        }
        .padding(20)
        .background(Color.cardBG)
        .cornerRadius(20)
    }

    private func save() {
        guard let d = Double(income) else { return }
        if let e = existing {
            e.monthlyIncome = d
            e.savingsTargetPercent = savingsPercent / 100
            e.markChanged()
        } else {
            let goal = SavingsGoal(monthlyIncome: d, savingsTargetPercent: savingsPercent / 100)
            if let userId = auth.userId {
                goal.id = userId          // one goal per user – id mirrors the cloud row
                goal.userId = userId
            }
            modelContext.insert(goal)
        }
        sync.requestSync()
        dismiss()
    }
}
