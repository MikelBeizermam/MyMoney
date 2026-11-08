import Foundation
import Observation
import Supabase

/// Owns the authentication state of the app and wraps Supabase Auth calls.
@MainActor
@Observable
final class AuthManager {
    enum Phase: Equatable {
        case loading
        case signedOut
        case signedIn
    }

    private(set) var phase: Phase = .loading
    private(set) var currentUser: User?
    /// Set when the user opened a password-reset link; the UI shows the "new password" screen.
    var isRecoveringPassword = false

    private var listenTask: Task<Void, Never>?
    private var auth: AuthClient { SupabaseService.client.auth }

    var userId: UUID? { currentUser?.id }
    var email: String { currentUser?.email ?? "" }
    var displayName: String {
        if case let .string(name)? = currentUser?.userMetadata["full_name"], !name.isEmpty {
            return name
        }
        return email.components(separatedBy: "@").first ?? ""
    }

    // MARK: - Lifecycle

    func start() {
        guard listenTask == nil else { return }
        listenTask = Task { [weak self] in
            guard let auth = self?.auth else { return }
            for await (event, session) in auth.authStateChanges {
                self?.handle(event: event, session: session)
            }
        }
    }

    private func handle(event: AuthChangeEvent, session: Session?) {
        switch event {
        case .initialSession, .signedIn, .tokenRefreshed, .userUpdated, .mfaChallengeVerified:
            apply(session)
        case .passwordRecovery:
            apply(session)
            isRecoveringPassword = true
        case .signedOut, .userDeleted:
            apply(nil)
        @unknown default:
            break
        }
    }

    private func apply(_ session: Session?) {
        currentUser = session?.user
        phase = session == nil ? .signedOut : .signedIn
        if session == nil { isRecoveringPassword = false }
    }

    // MARK: - Actions

    func signIn(email: String, password: String) async throws {
        do {
            let session = try await auth.signIn(email: email.normalizedEmail, password: password)
            apply(session)
        } catch {
            throw AuthFailure(error)
        }
    }

    /// Returns `true` when the account was created but the user must confirm their email first.
    func signUp(fullName: String, email: String, password: String) async throws -> Bool {
        do {
            let response = try await auth.signUp(
                email: email.normalizedEmail,
                password: password,
                data: ["full_name": .string(fullName.trimmingCharacters(in: .whitespacesAndNewlines))],
                redirectTo: AppConfig.authRedirectURL
            )
            if let session = response.session {
                apply(session)
                return false
            }
            return true
        } catch {
            throw AuthFailure(error)
        }
    }

    func sendPasswordReset(email: String) async throws {
        do {
            try await auth.resetPasswordForEmail(email.normalizedEmail, redirectTo: AppConfig.authRedirectURL)
        } catch {
            throw AuthFailure(error)
        }
    }

    func updatePassword(_ newPassword: String) async throws {
        do {
            let user = try await auth.update(user: UserAttributes(password: newPassword))
            currentUser = user
            isRecoveringPassword = false
        } catch {
            throw AuthFailure(error)
        }
    }

    func signOut() async {
        do {
            try await auth.signOut()
        } catch {
            // Even if revoking the token on the server fails (e.g. offline), drop the local session.
            try? await auth.signOut(scope: .local)
        }
        apply(nil)
    }

    /// Handles `mymoney://auth-callback?...` links from confirmation / reset emails.
    func handleAuthCallback(_ url: URL) async -> String? {
        do {
            let session = try await auth.session(from: url)
            apply(session)
            return nil
        } catch {
            return AuthFailure(error).message
        }
    }
}

// MARK: - Errors

/// A user-facing (Hebrew) wrapper around Supabase / network errors.
struct AuthFailure: LocalizedError {
    let message: String

    init(message: String) { self.message = message }

    init(_ error: Error) {
        if let failure = error as? AuthFailure {
            message = failure.message
            return
        }
        if error is URLError {
            message = "אין חיבור לאינטרנט. נסה שוב."
            return
        }
        if let authError = error as? AuthError {
            switch authError.errorCode {
            case .invalidCredentials:
                message = "אימייל או סיסמה שגויים."
            case .emailNotConfirmed:
                message = "צריך לאשר את כתובת האימייל. בדוק את תיבת הדואר."
            case .userAlreadyExists, .emailExists:
                message = "כבר קיים משתמש עם האימייל הזה."
            case .weakPassword:
                message = "הסיסמה חלשה מדי. בחר סיסמה של 8 תווים לפחות."
            case .samePassword:
                message = "הסיסמה החדשה חייבת להיות שונה מהקודמת."
            case .overEmailSendRateLimit, .overRequestRateLimit:
                message = "יותר מדי ניסיונות. נסה שוב בעוד כמה דקות."
            case .otpExpired, .flowStateExpired, .flowStateNotFound, .badCodeVerifier:
                message = "הקישור פג תוקף או כבר נוצל. בקש קישור חדש."
            case .sessionNotFound, .sessionExpired:
                message = "פג תוקף ההתחברות. התחבר מחדש."
            default:
                message = "משהו השתבש. נסה שוב."
            }
            return
        }
        message = "משהו השתבש. נסה שוב."
    }

    var errorDescription: String? { message }
}

extension String {
    var normalizedEmail: String {
        trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    var isValidEmail: Bool {
        range(of: #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#, options: .regularExpression) != nil
    }
}
