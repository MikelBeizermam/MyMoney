import SwiftUI

struct LoginView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case signIn = "התחברות"
        case signUp = "הרשמה"
        var id: String { rawValue }
    }

    @Environment(AuthManager.self) private var auth

    @State private var mode: Mode = .signIn
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var error: String?
    @State private var info: String?
    @State private var showForgotPassword = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    header

                    Picker("", selection: modeSelection) {
                        ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    VStack(spacing: 14) {
                        if mode == .signUp {
                            AuthField(title: "שם מלא", systemImage: "person", text: $fullName, contentType: .name)
                        }
                        AuthField(title: "אימייל", systemImage: "envelope", text: $email,
                                  keyboard: .emailAddress, contentType: .username, forceLTR: true)
                        AuthField(title: "סיסמה", systemImage: "lock", text: $password, isSecure: true,
                                  contentType: mode == .signUp ? .newPassword : .password, forceLTR: true)
                        if mode == .signUp {
                            AuthField(title: "אימות סיסמה", systemImage: "lock.rotation", text: $confirmPassword,
                                      isSecure: true, contentType: .newPassword, forceLTR: true)
                            Text("לפחות \(PasswordPolicy.minLength) תווים, אותיות ומספרים")
                                .font(.caption)
                                .foregroundStyle(.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    if let error { MessageBanner(text: error, kind: .error) }
                    if let info { MessageBanner(text: info, kind: .success) }

                    PrimaryButton(title: mode.rawValue, isLoading: isLoading, isEnabled: canSubmit, action: submit)

                    if mode == .signIn {
                        Button("שכחתי סיסמה") { showForgotPassword = true }
                            .font(.subheadline)
                            .foregroundStyle(.accentGreen)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 40)
                .animation(.easeInOut(duration: 0.2), value: mode)
                .animation(.easeInOut(duration: 0.2), value: error)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView(initialEmail: email)
        }
        .preferredColorScheme(.dark)
        .environment(\.layoutDirection, .rightToLeft)
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "creditcard.and.123")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(.accentGreen)
                .frame(width: 88, height: 88)
                .background(Color.accentGreen.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 24))
            Text("MyMoney")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(mode == .signIn ? "ברוך שובך! התחבר כדי לראות את ההוצאות שלך" : "צור חשבון והנתונים שלך יסונכרנו לכל המכשירים")
                .font(.subheadline)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }

    /// Switching tabs by hand clears old messages; switching programmatically (after sign-up) does not.
    private var modeSelection: Binding<Mode> {
        Binding(get: { mode }, set: { newValue in
            mode = newValue
            error = nil
            info = nil
        })
    }

    private var canSubmit: Bool {
        let basic = email.isValidEmail && !password.isEmpty
        return mode == .signIn ? basic : basic && !fullName.trimmingCharacters(in: .whitespaces).isEmpty && !confirmPassword.isEmpty
    }

    private func submit() {
        error = nil
        info = nil

        if mode == .signUp {
            if let problem = PasswordPolicy.problem(password) { error = problem; return }
            if password != confirmPassword { error = "הסיסמאות אינן תואמות."; return }
        }

        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                switch mode {
                case .signIn:
                    try await auth.signIn(email: email, password: password)
                case .signUp:
                    let needsConfirmation = try await auth.signUp(fullName: fullName, email: email, password: password)
                    if needsConfirmation {
                        mode = .signIn
                        info = "שלחנו אליך מייל לאישור החשבון. לחץ על הקישור שבמייל כדי להיכנס."
                        password = ""
                        confirmPassword = ""
                    }
                }
            } catch {
                self.error = (error as? AuthFailure)?.message ?? AuthFailure(error).message
            }
        }
    }
}
