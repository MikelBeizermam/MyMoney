import SwiftUI

/// Dark, rounded input field used by all auth screens.
struct AuthField: View {
    let title: String
    let systemImage: String
    @Binding var text: String
    var isSecure = false
    var keyboard: UIKeyboardType = .default
    var contentType: UITextContentType?
    var forceLTR = false

    @State private var reveal = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(.textSecondary)
                .frame(width: 20)

            Group {
                if isSecure && !reveal {
                    SecureField("", text: $text, prompt: prompt)
                } else {
                    TextField("", text: $text, prompt: prompt)
                }
            }
            .textContentType(contentType)
            .keyboardType(keyboard)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .foregroundStyle(.white)
            .environment(\.layoutDirection, forceLTR ? .leftToRight : .rightToLeft)
            .multilineTextAlignment(forceLTR && text.isEmpty ? .trailing : .leading)

            if isSecure {
                Button {
                    reveal.toggle()
                } label: {
                    Image(systemName: reveal ? "eye.slash" : "eye")
                        .foregroundStyle(.textSecondary)
                }
                .accessibilityLabel(reveal ? "הסתר סיסמה" : "הצג סיסמה")
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 54)
        .background(Color.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.06)))
    }

    private var prompt: Text {
        Text(title).foregroundStyle(Color.textSecondary)
    }
}

struct PrimaryButton: View {
    let title: String
    var isLoading = false
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView().tint(.black)
                } else {
                    Text(title).font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .foregroundStyle(.black)
            .background(Color.accentGreen.opacity(isEnabled ? 1 : 0.35))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!isEnabled || isLoading)
    }
}

struct MessageBanner: View {
    enum Kind { case error, success }
    let text: String
    let kind: Kind

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: kind == .error ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
            Text(text).frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.subheadline)
        .foregroundStyle(kind == .error ? Color.accentRed : Color.accentGreen)
        .padding(14)
        .background((kind == .error ? Color.accentRed : Color.accentGreen).opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

/// Password rules shared by sign-up and reset (mirrors `minimum_password_length` in supabase/config.toml).
enum PasswordPolicy {
    static let minLength = 8

    static func problem(_ password: String) -> String? {
        if password.count < minLength { return "הסיסמה צריכה להכיל לפחות \(minLength) תווים." }
        let hasLetter = password.rangeOfCharacter(from: .letters) != nil
        let hasDigit = password.rangeOfCharacter(from: .decimalDigits) != nil
        if !(hasLetter && hasDigit) { return "הסיסמה צריכה לכלול אותיות ומספרים." }
        return nil
    }
}
