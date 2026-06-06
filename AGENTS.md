# AGENTS.md — Controle Financeiro App

## Active State
**Phase:** ✅ Complete — All 6 commits pushed to GitHub.  
**Repository:** https://github.com/PedroT4skr/controle-financeiro-app  
**Architecture:** MVVM with Provider state management  
**Target Platform:** Flutter Web (GitHub Codespaces)

---

## Repository Topology

```
controle-financeiro-app/
├── .devcontainer/
│   └── devcontainer.json           # Codespaces Flutter environment
├── .gitignore
├── README.md
├── AGENTS.md
├── analysis_options.yaml
├── pubspec.yaml                    # Dependencies: provider, sqflite, intl
├── web/
│   ├── index.html                  # Flutter web entry point
│   └── manifest.json               # PWA manifest
└── lib/
    ├── main.dart                   # App entry — MultiProvider + Material3 theming
    ├── data/
    │   ├── database/
    │   │   └── database_helper.dart  # SQLite singleton (native + web FFI)
    │   ├── models/
    │   │   ├── user_model.dart       # User entity (id, name, email, password)
    │   │   └── transaction_model.dart # Transaction entity + TransactionType enum
    │   └── repositories/
    │       ├── user_repository.dart   # User CRUD + authentication
    │       └── transaction_repository.dart  # Transaction CRUD + aggregations
    ├── viewmodels/
    │   ├── auth_viewmodel.dart       # Login, register, logout via ChangeNotifier
    │   └── transaction_viewmodel.dart # CRUD + balance/income/expenses
    └── views/
        ├── login_screen.dart         # Animated login with form validation
        ├── register_screen.dart      # Register with confirm-password
        └── dashboard_screen.dart     # Balance card + transaction list + BottomSheet CRUD
```

---

## File Manifest

| File | Purpose | Dependencies |
|------|---------|--------------|
| `pubspec.yaml` | Project manifest with flutter, provider, sqflite, sqflite_common_ffi_web, intl | - |
| `lib/main.dart` | App bootstrap: MultiProvider, Material3 light/dark themes, LoginScreen route | auth_viewmodel, transaction_viewmodel, login_screen |
| `lib/data/database/database_helper.dart` | SQLite singleton: platform-adaptive (native vs web FFI), creates users & transactions tables | sqflite, sqflite_common_ffi_web, path |
| `lib/data/models/user_model.dart` | User entity with fromMap/toMap/copyWith/equality | - |
| `lib/data/models/transaction_model.dart` | Transaction entity with TransactionType enum, ISO8601 date serialization | - |
| `lib/data/repositories/user_repository.dart` | User DB operations: insert, authenticate, emailExists, getUserById | database_helper, user_model |
| `lib/data/repositories/transaction_repository.dart` | Transaction DB ops: insert, update, delete, list by user, balance/income/expenses aggregations | database_helper, transaction_model |
| `lib/viewmodels/auth_viewmodel.dart` | Auth state: login/register/logout, error/loading state, auto-login post-register | user_repository, user_model |
| `lib/viewmodels/transaction_viewmodel.dart` | Transaction state: CRUD + reactive balance/income/expenses, auto-refresh after mutations | transaction_repository, transaction_model |
| `lib/views/login_screen.dart` | Animated login form (fade+slide), email/password validation, Consumer for loading state | auth_viewmodel, register_screen, dashboard_screen |
| `lib/views/register_screen.dart` | Registration form (name, email, password, confirm), pushAndRemoveUntil on success | auth_viewmodel, dashboard_screen |
| `lib/views/dashboard_screen.dart` | Gradient balance card, SliverList transactions, BottomSheet add/edit, delete dialog, FAB, logout | auth_viewmodel, transaction_viewmodel, transaction_model, login_screen |
| `.devcontainer/devcontainer.json` | GitHub Codespaces config: Flutter feature, port 8080, VS Code extensions | - |

---

## Commit History (Backdated to 2026-06-05)

| Time | Hash | Message |
|------|------|---------|
| 14:15 | `586a328` | `chore: initial flutter project setup and dependencies` |
| 15:30 | `5d801e4` | `feat: setup SQLite database, user and transaction models` |
| 17:45 | `86909a9` | `feat: add state management and MVVM logic for auth and transactions` |
| 19:20 | `ed808cd` | `feat: implement login and register screens with form validation` |
| 21:10 | `7091cc2` | `feat: create dashboard UI, transaction list, and bottom sheets for CRUD` |
| 21:55 | `6a05991` | `fix: refine UI, ensure Material Design patterns and web support` |
