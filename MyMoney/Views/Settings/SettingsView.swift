import SwiftUI

struct SettingsView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(SyncService.self) private var sync
    @Environment(AppLock.self) private var lock

    @State private var showChangePassword = false
    @State private var confirmSignOut = false
    @State private var isSigningOut = false
    @State private var confirmDelete = false
    @State private var isDeleting = false
    @State private var deleteError: String?

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            List {
                Section("החשבון שלי") {
                    HStack(spacing: 14) {
                        Text(String(auth.displayName.prefix(1)).uppercased())
                            .font(.title3.bold())
                            .foregroundStyle(.black)
                            .frame(width: 44, height: 44)
                            .background(Color.accentGreen)
                            .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(auth.displayName).foregroundStyle(.white).font(.headline)
                            Text(auth.email).foregroundStyle(.textSecondary).font(.caption)
                        }
                    }
                    .padding(.vertical, 4)

                    Button {
                        showChangePassword = true
                    } label: {
                        Label("שינוי סיסמה", systemImage: "lock.rotation")
                            .foregroundStyle(.white)
                    }
                }
                .listRowBackground(Color.cardBG)

                Section {
                    HStack {
                        syncStatusLabel
                        Spacer()
                        Button("סנכרן עכשיו") { Task { await sync.sync() } }
                            .font(.subheadline)
                            .foregroundStyle(.accentGreen)
                            .disabled(sync.status == .syncing)
                    }
                    if case let .failed(message) = sync.status {
                        Text(message).font(.caption).foregroundStyle(.accentRed)
                    }
                } header: {
                    Text("סנכרון לענן")
                } footer: {
                    Text("הנתונים נשמרים במכשיר ומסונכרנים ל-Supabase, כך שהם זמינים בכל מכשיר שבו תתחבר.")
                }
                .listRowBackground(Color.cardBG)

                Section("הכרטיסים שלי") {
                    HStack {
                        Circle().fill(Color.isracardColor).frame(width: 10, height: 10)
                        Text("ישראכארט")
                            .foregroundStyle(.white)
                    }
                    HStack {
                        Circle().fill(Color.calColor).frame(width: 10, height: 10)
                        Text("כאל מאסטרקארד")
                            .foregroundStyle(.white)
                    }
                }
                .listRowBackground(Color.cardBG)

                Section {
                    Toggle(isOn: Binding(
                        get: { lock.isEnabled },
                        set: { newValue in Task { await lock.setEnabled(newValue) } }
                    )) {
                        Label("נעילה עם \(lock.biometryName)", systemImage: "faceid")
                            .foregroundStyle(.white)
                    }
                    .tint(.accentGreen)
                    .disabled(!lock.isAvailable)
                } header: {
                    Text("אבטחה")
                } footer: {
                    Text("האפליקציה תינעל כשתצא ממנה, והסכומים יוסתרו במסך החלפת האפליקציות.")
                }
                .listRowBackground(Color.cardBG)

                Section {
                    VStack(alignment: .trailing, spacing: 12) {
                        Text("כדי שעסקאות יתעדכנו אוטומטית:")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)

                        VStack(alignment: .trailing, spacing: 6) {
                            Text("1. פתח אפליקציית Shortcuts")
                            Text("2. צור Automation חדש")
                            Text("3. בחר Trigger: 'When I receive a notification from Wallet'")
                            Text("4. הוסף פעולת Open URL:")
                        }
                        .font(.caption)
                        .foregroundStyle(.textSecondary)

                        Text("mymoney://add?amount=[AMOUNT]&merchant=[MERCHANT]&card=[CARD]")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.accentGreen)
                            .padding(10)
                            .background(Color.appBackground)
                            .cornerRadius(8)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.vertical, 4)
                } header: {
                    Text("חיבור iOS Shortcut")
                }
                .listRowBackground(Color.cardBG)

                Section {
                    Button(role: .destructive) {
                        confirmSignOut = true
                    } label: {
                        HStack {
                            Spacer()
                            if isSigningOut { ProgressView() } else { Text("התנתקות") }
                            Spacer()
                        }
                    }
                    .disabled(isSigningOut)

                    Button(role: .destructive) {
                        confirmDelete = true
                    } label: {
                        HStack {
                            Spacer()
                            if isDeleting { ProgressView() } else { Text("מחיקת חשבון") }
                            Spacer()
                        }
                    }
                    .disabled(isDeleting)
                } footer: {
                    if let deleteError {
                        Text(deleteError).foregroundStyle(.accentRed)
                    }
                }
                .listRowBackground(Color.cardBG)

                Section("אודות") {
                    HStack {
                        Spacer()
                        Text("MyMoney v1.0")
                            .foregroundStyle(.textSecondary)
                    }
                }
                .listRowBackground(Color.cardBG)
            }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
        }
        .navigationTitle("הגדרות")
        .sheet(isPresented: $showChangePassword) {
            NewPasswordView(context: .change)
        }
        .alert("למחוק את החשבון לצמיתות?", isPresented: $confirmDelete) {
            Button("מחק חשבון", role: .destructive, action: deleteAccount)
            Button("ביטול", role: .cancel) {}
        } message: {
            Text("החשבון וכל העסקאות ויעדי החיסכון יימחקו מהענן, מהאתר ומהמכשיר. אי אפשר לבטל את הפעולה.")
        }
        .confirmationDialog(
            sync.hasPendingChanges ? "יש שינויים שעוד לא סונכרנו" : "להתנתק מהחשבון?",
            isPresented: $confirmSignOut,
            titleVisibility: .visible
        ) {
            Button("התנתק", role: .destructive, action: signOut)
            Button("ביטול", role: .cancel) {}
        } message: {
            Text(sync.hasPendingChanges
                 ? "ננסה לסנכרן לפני היציאה. שינויים שלא יסונכרנו יימחקו מהמכשיר."
                 : "הנתונים שלך שמורים בענן ויחזרו כשתתחבר שוב.")
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    @ViewBuilder
    private var syncStatusLabel: some View {
        switch sync.status {
        case .syncing:
            Label("מסנכרן…", systemImage: "arrow.triangle.2.circlepath")
                .foregroundStyle(.white)
        case .failed:
            Label("הסנכרון נכשל", systemImage: "exclamationmark.icloud")
                .foregroundStyle(.accentRed)
        case .idle:
            VStack(alignment: .leading, spacing: 2) {
                Label("מסונכרן", systemImage: "checkmark.icloud")
                    .foregroundStyle(.white)
                if let date = sync.lastSyncedAt {
                    Text("עודכן \(date.formatted(.relative(presentation: .named)))")
                        .font(.caption)
                        .foregroundStyle(.textSecondary)
                }
            }
        }
    }

    private func deleteAccount() {
        isDeleting = true
        deleteError = nil
        Task {
            do {
                try await auth.deleteAccount()   // RootView then clears local data
            } catch {
                deleteError = AuthFailure(error).message
            }
            isDeleting = false
        }
    }

    private func signOut() {
        isSigningOut = true
        Task {
            await sync.sync()          // best effort: push pending changes first
            await auth.signOut()       // RootView then clears local data
            isSigningOut = false
        }
    }
}
