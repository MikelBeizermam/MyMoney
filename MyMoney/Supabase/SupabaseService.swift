import Foundation
import Supabase

/// Reads Supabase settings injected into Info.plist from Config/Config.xcconfig.
enum AppConfig {
    /// Deep link Supabase redirects to after email confirmation / password reset.
    static let authRedirectURL = URL(string: "mymoney://auth-callback")!

    static var supabaseURL: URL? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              !raw.isEmpty, !raw.contains("YOUR-PROJECT-REF"),
              let url = URL(string: raw), url.host != nil
        else { return nil }
        return url
    }

    static var supabaseAnonKey: String? {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
              !key.isEmpty, !key.hasPrefix("YOUR-")
        else { return nil }
        return key
    }

    static var isConfigured: Bool { supabaseURL != nil && supabaseAnonKey != nil }
}

enum SupabaseService {
    /// Shared client. Only touch it after checking `AppConfig.isConfigured`.
    static let client: SupabaseClient = {
        guard let url = AppConfig.supabaseURL, let key = AppConfig.supabaseAnonKey else {
            fatalError("Supabase is not configured. Copy Config/Config.example.xcconfig to Config/Config.xcconfig.")
        }
        return SupabaseClient(
            supabaseURL: url,
            supabaseKey: key,
            options: SupabaseClientOptions(
                auth: .init(
                    redirectToURL: AppConfig.authRedirectURL,
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }()
}
