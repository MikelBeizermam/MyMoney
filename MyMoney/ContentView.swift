import SwiftUI

struct ContentView: View {
    @Binding var selectedTab: Int

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                DashboardView()
                    .navigationTitle("MyMoney")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem { Label("בית", systemImage: "house.fill") }
            .tag(0)

            NavigationStack {
                TransactionsView()
            }
            .tabItem { Label("עסקאות", systemImage: "list.bullet.rectangle.fill") }
            .tag(1)

            NavigationStack {
                SavingsView()
            }
            .tabItem { Label("חיסכון", systemImage: "piggybank.fill") }
            .tag(2)

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("הגדרות", systemImage: "gear") }
            .tag(3)
        }
        .tint(.accentGreen)
        .preferredColorScheme(.dark)
        .environment(\.layoutDirection, .rightToLeft)
    }
}
