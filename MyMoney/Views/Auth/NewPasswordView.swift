import SwiftUI

/// Step 2 of password reset (opened from the email link), also used for "change password" in Settings.
struct NewPasswordView: View {
    enum Context { case recovery, change }

    let context: Context

    @Environment(AuthManager.self) private var auth
    @Environment(\.dismiss) private var dismiss

    @State private var password = ""
    @State private var confirm = ""
    @State private var isLoading = false
    @State private var error: String?
    @State private var done = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 20) {
                    Image(systemName: done ? "checkmark.seal.fill" : "lock.rotation")
                        .font(.system(size: 40))
                        .foregroundStyle(.accentGreen)
                        .padding(.top, 24)

                    Text(done ? "הסיסמה עודכנה" : "בחר סיסמה חדשה")
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    if done {
                        Text("מעכשיו התחבר עם הסיסמה החדשה.")
                            .foregroundStyle(.textSecondary)
                        PrimaryButton(title: "המשך") { finish() }
                    } else {
                        AuthField(title: "סיסמה חדשה", systemImage: "lock", text: $password,
                                  isSecure: true, contentType: .newPassword, forceLTR: true)
                        AuthField(title: "אימות סיסמה", systemImage: "lock.rotation", text: $confirm,
                                  isSecure: true, contentType: .newPassword, forceLTR: true)
                        Text("לפחות \(PasswordPolicy.minLength) תווים, אותיות ומספרים")
                            .font(.caption)
                            .foregroundStyle(.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if let error { MessageBanner(text: error, kind: .error) }

                        PrimaryButton(title: "שמור סיסמה", isLoading: isLoading,
                                      isEnabled: !password.isEmpty && !confirm.isEmpty, action: save)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .toolbar {
                if !done {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("ביטול") { finish() }.foregroundStyle(.textSecondary)
                    }
                }
            }
        }
        .interactiveDismissDisabled(context == .recovery && !done)
        .preferredColorScheme(.dark)
        .environment(\.layoutDirection, .rightToLeft)
    }

    private func save() {
        error = nil
        if let problem = PasswordPolicy.problem(password) { error = problem; return }
        guard password == confirm else { error = "הסיסמאות אינן תואמות."; return }

        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                try await auth.updatePassword(password)
                withAnimation { done = true }
            } catch {
                self.error = AuthFailure(error).message
            }
        }
    }

    private func finish() {
        auth.isRecoveringPassword = false
        dismiss()
    }
}
