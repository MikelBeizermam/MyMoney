# MyMoney 💳

An offline-first iOS app for tracking credit-card spending and savings goals. It has email/password accounts and cloud sync through **Supabase**.

🌐 **[Live interactive demo](https://mikelbeizermam.github.io/MyMoney/)**: open it on your phone for the full-screen experience<br>
📄 **[Product & technical spec (Hebrew)](docs/SPEC.md)**

<img src="docs/screenshots/login.png" width="280" alt="Login screen" />

## Features

- **Dashboard**: total spent this month, a spending-by-category chart (Swift Charts) and recent transactions.
- **Transactions**: filter by card and category, add manually, swipe to delete.
- **Auto-categorisation**: Hebrew and English merchant names are classified into categories.
- **Automatic capture**: an iOS Shortcuts automation turns Wallet notifications into `mymoney://add?...` deep links.
- **Savings goal**: set income and a target percentage, then see how much is still safe to spend this month.
- **Accounts**: sign up with email confirmation, sign in, forgot/reset password via email deep link, change password.
- **Cloud sync**: data stays available offline and syncs across devices.

## Tech stack

| Layer | Technology |
|---|---|
| UI | SwiftUI (RTL, Hebrew), Swift Charts |
| Local storage | SwiftData |
| Auth | Supabase Auth (email + password, PKCE, deep-link callbacks) |
| Backend | Supabase Postgres + PostgREST, Row Level Security |
| Project | XcodeGen (`project.yml`), Swift Package Manager |

## Architecture highlights

- **Offline-first sync engine** ([`SyncService.swift`](MyMoney/Services/SyncService.swift)): the app always reads and writes SwiftData; a sync cycle *pulls* server changes since a cursor and then *pushes* dirty rows with a bulk upsert.
- **Conflict resolution**: last-write-wins on `updated_at`, enforced on the client *and* by a Postgres trigger, so a stale device can never overwrite newer data.
- **Server-side cursor**: `synced_at` is set by the database with `clock_timestamp()`, which makes the cursor independent of device clocks and unique within a bulk write.
- **Soft deletes** (`deleted_at`) so deletions reach other devices.
- **Security**: RLS limits every user to their own rows, the `anon` role has no table access, and keys live in a git-ignored `.xcconfig`.
- **Migration-safe**: new SwiftData fields have defaults, and data created before the first login is claimed by the account on sign-in.

## Getting started

### 1. Supabase

1. Create a project at [supabase.com](https://supabase.com).
2. Apply the schema, either with the CLI:
   ```bash
   supabase link --project-ref <your-project-ref>
   supabase db push
   ```
   or by pasting [`supabase/migrations/20261108000000_init_sync_schema.sql`](supabase/migrations/20261108000000_init_sync_schema.sql) into the SQL editor.
3. In **Authentication → URL Configuration**, add `mymoney://auth-callback` to **Redirect URLs**, or run `supabase config push` to apply [`supabase/config.toml`](supabase/config.toml).

### 2. App

```bash
cp Config/Config.example.xcconfig Config/Config.xcconfig
# edit SUPABASE_URL and SUPABASE_ANON_KEY (Project Settings → API)
open MyMoney.xcodeproj
```

Requires Xcode 16+ and iOS 17+. If you change `project.yml`, regenerate the project with `xcodegen generate`.

## Project structure

```
MyMoney/
├── MyMoneyApp.swift          # App entry, model container, environment
├── RootView.swift            # Auth routing + deep links
├── Models/                   # SwiftData models + Supabase DTOs
├── Services/                 # AuthManager, SyncService, classifiers
├── Supabase/                 # Client configuration
└── Views/                    # Auth, Dashboard, Transactions, Savings, Settings
supabase/                     # Postgres migration + local config
docs/SPEC.md                  # Hebrew product & technical spec
```

---

Built by Miki Beizerman.
