import SwiftUI
import SwiftData

@main
struct MyMoneyApp: App {
    private let container: ModelContainer
    @State private var auth = AuthManager()
    @State private var sync: SyncService

    init() {
        do {
            container = try ModelContainer(for: Transaction.self, SavingsGoal.self)
        } catch {
            fatalError("Could not open the local database: \(error)")
        }
        _sync = State(initialValue: SyncService(context: container.mainContext))
    }

    var body: some Scene {
        WindowGroup {
            if AppConfig.isConfigured {
                RootView()
                    .environment(auth)
                    .environment(sync)
            } else {
                MissingConfigView()
            }
        }
        .modelContainer(container)
    }
}

/// Shown when Config/Config.xcconfig was not filled in (e.g. a fresh clone of the repo).
private struct MissingConfigView: View {
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(spacing: 14) {
                Image(systemName: "gearshape.2").font(.largeTitle).foregroundStyle(.accentGreen)
                Text("חסרה הגדרת Supabase").font(.title3.bold()).foregroundStyle(.white)
                Text("העתק את Config/Config.example.xcconfig ל-Config/Config.xcconfig ומלא את SUPABASE_URL ו-SUPABASE_ANON_KEY.")
                    .font(.subheadline)
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(32)
        }
        .preferredColorScheme(.dark)
        .environment(\.layoutDirection, .rightToLeft)
    }
}
