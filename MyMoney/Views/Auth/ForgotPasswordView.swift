import SwiftUI

/// Step 1 of password reset: send a reset link to the user's email.
struct ForgotPasswordView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(\.dismiss) private var dismiss

    @State private var email: String
    @State private var isLoading = false
    @State private var error: String?
    @State private var sent = false

    init(initialEmail: String = "") {
        _email = State(initialValue: initialEmail)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 22) {
                    Image(systemName: sent ? "envelope.badge" : "key.horizontal")
                        .font(.system(size: 40))
                        .foregroundStyle(.accentGreen)
                        .padding(.top, 24)

                    Text(sent ? "בדוק את תיבת המייל" : "איפוס סיסמה")
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    Text(sent
                         ? "אם קיים חשבון עם \(email.normalizedEmail), נשלח אליו קישור לאיפוס הסיסמה. פתח את הקישור מהאייפון הזה."
                         : "הזן את האימייל שאיתו נרשמת ונשלח לך קישור לבחירת סיסמה חדשה.")
                        .font(.subheadline)
                        .foregroundStyle(.textSecondary)
                        .multilineTextAlignment(.center)

                    if !sent {
                        AuthField(title: "אימייל", systemImage: "envelope", text: $email,
                                  keyboard: .emailAddress, contentType: .username, forceLTR: true)
                    }

                    if let error { MessageBanner(text: error, kind: .error) }

                    if sent {
                        PrimaryButton(title: "חזרה להתחברות") { dismiss() }
                    } else {
                        PrimaryButton(title: "שלח קישור", isLoading: isLoading, isEnabled: email.isValidEmail, action: send)
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("סגור") { dismiss() }.foregroundStyle(.textSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
        .environment(\.layoutDirection, .rightToLeft)
    }

    private func send() {
        error = nil
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                try await auth.sendPasswordReset(email: email)
                withAnimation { sent = true }
            } catch {
                self.error = AuthFailure(error).message
            }
        }
    }
}
