import SwiftUI
import SwiftData

/// Decides between the login flow and the main app, wires auth to sync,
/// and handles every `mymoney://` deep link.
struct RootView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(SyncService.self) private var sync
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @State private var selectedTab = 0
    /// A Shortcut "add transaction" link that arrived while signed out – applied after login.
    @State private var pendingAddURL: URL?
    @State private var linkError: String?

    var body: some View {
        @Bindable var auth = auth

        Group {
            switch auth.phase {
            case .loading:
                SplashView()
            case .signedOut:
                LoginView()
            case .signedIn:
                ContentView(selectedTab: $selectedTab)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: auth.phase)
        .task { auth.start() }
        .onChange(of: auth.userId, initial: true) { _, newId in
            Task {
                if let newId {
                    await sync.activate(userId: newId)
                    if let url = pendingAddURL {
                        pendingAddURL = nil
                        addTransaction(from: url)
                    }
                } else if auth.phase == .signedOut {
                    sync.deactivate()
                }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { sync.requestSync() }
        }
        .onOpenURL(perform: handleDeepLink)
        .sheet(isPresented: $auth.isRecoveringPassword) {
            NewPasswordView(context: .recovery)
        }
        .alert("הקישור לא תקין", isPresented: Binding(get: { linkError != nil }, set: { if !$0 { linkError = nil } })) {
            Button("אישור", role: .cancel) {}
        } message: {
            Text(linkError ?? "")
        }
    }

    // MARK: - Deep links

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "mymoney" else { return }
        switch url.host {
        case "auth-callback":
            Task { linkError = await auth.handleAuthCallback(url) }
        case "add":
            if auth.phase == .signedIn {
                addTransaction(from: url)
            } else {
                pendingAddURL = url
            }
        default:
            break
        }
    }

    /// Receives: mymoney://add?amount=150&merchant=שופרסל&card=cal
    private func addTransaction(from url: URL) {
        let params = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .reduce(into: [String: String]()) { $0[$1.name] = $1.value } ?? [:]

        guard let amountStr = params["amount"], let amount = Double(amountStr) else { return }

        let merchant = params["merchant"]?.removingPercentEncoding ?? "עסקה"
        let cardRaw = params["card"] ?? ""
        let card: CardType = (cardRaw.contains("cal") || cardRaw.contains("כאל")) ? .cal : .isracard
        let category = CategoryClassifier.classify(merchant)

        let transaction = Transaction(amount: amount, merchant: merchant, category: category, card: card)
        transaction.userId = auth.userId
        modelContext.insert(transaction)
        sync.requestSync()

        selectedTab = 0
    }
}

private struct SplashView: View {
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ProgressView().tint(.accentGreen)
        }
        .preferredColorScheme(.dark)
    }
}
