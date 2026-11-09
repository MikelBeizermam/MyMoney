import Foundation
import LocalAuthentication
import Observation
import SwiftUI

/// Optional Face ID / Touch ID / passcode lock that protects the app when it returns from the background.
@MainActor
@Observable
final class AppLock {
    private static let key = "appLock.enabled"

    private(set) var isEnabled: Bool
    private(set) var isLocked: Bool
    private var isAuthenticating = false

    init() {
        let enabled = UserDefaults.standard.bool(forKey: Self.key)
        isEnabled = enabled
        isLocked = enabled
    }

    /// "Face ID", "Touch ID" or a generic name, for the settings label.
    var biometryName: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        default: return "קוד המכשיר"
        }
    }

    var isAvailable: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }

    func lockIfNeeded() {
        if isEnabled { isLocked = true }
    }

    func unlock() async {
        guard isLocked, !isAuthenticating else { return }
        if await authenticate(reason: "פתח את MyMoney") { isLocked = false }
    }

    /// Turning the lock on requires a successful authentication first.
    func setEnabled(_ enabled: Bool) async {
        if enabled {
            guard await authenticate(reason: "הפעל נעילה עם \(biometryName)") else { return }
        }
        isEnabled = enabled
        isLocked = false
        UserDefaults.standard.set(enabled, forKey: Self.key)
    }

    /// Called on sign-out so the next user isn't locked by the previous user's setting.
    func reset() {
        isEnabled = false
        isLocked = false
        UserDefaults.standard.removeObject(forKey: Self.key)
    }

    private func authenticate(reason: String) async -> Bool {
        isAuthenticating = true
        defer { isAuthenticating = false }
        let context = LAContext()
        context.localizedCancelTitle = "ביטול"
        do {
            return try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
        } catch {
            return false
        }
    }
}

/// Full-screen cover shown while the app is locked (and in the app switcher).
struct LockView: View {
    @Environment(AppLock.self) private var lock

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(spacing: 18) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.accentGreen)
                Text("MyMoney נעולה")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Button {
                    Task { await lock.unlock() }
                } label: {
                    Label("פתח עם \(lock.biometryName)", systemImage: "faceid")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 24)
                        .frame(height: 50)
                        .background(Color.accentGreen)
                        .clipShape(Capsule())
                }
            }
        }
        .task { await lock.unlock() }
        .preferredColorScheme(.dark)
        .environment(\.layoutDirection, .rightToLeft)
    }
}
