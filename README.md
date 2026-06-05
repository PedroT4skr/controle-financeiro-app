# 💰 Controle Financeiro App

Aplicativo de Controle Financeiro Pessoal desenvolvido em **Flutter** com arquitetura **MVVM**.

## 📋 Funcionalidades

- ✅ Login e Cadastro com validação de formulários
- ✅ Dashboard com saldo total (Receitas - Despesas)
- ✅ CRUD completo de Transações (Adicionar, Editar, Listar, Excluir)
- ✅ Persistência local com SQLite
- ✅ Material Design 3
- ✅ Suporte Web para GitHub Codespaces

## 🏗️ Arquitetura

- **Padrão:** MVVM (Model-View-ViewModel)
- **Estado:** Provider
- **Banco:** SQLite (`sqflite` + `sqflite_common_ffi_web`)

## 🚀 Como executar

### Localmente
```bash
flutter pub get
flutter run -d chrome
```

### No GitHub Codespaces
1. Abra o Codespace a partir deste repositório
2. O ambiente Flutter será configurado automaticamente via `.devcontainer`
3. Execute `flutter run -d web-server --web-port=8080 --web-hostname=0.0.0.0`

## 📁 Estrutura do Projeto

```
lib/
├── main.dart
├── data/
│   ├── database/
│   │   └── database_helper.dart
│   ├── models/
│   │   ├── user_model.dart
│   │   └── transaction_model.dart
│   └── repositories/
│       ├── user_repository.dart
│       └── transaction_repository.dart
├── viewmodels/
│   ├── auth_viewmodel.dart
│   └── transaction_viewmodel.dart
└── views/
    ├── login_screen.dart
    ├── register_screen.dart
    └── dashboard_screen.dart
```

## 🛠️ Tecnologias

- Flutter 3.x
- Dart 3.x
- Provider
- SQLite
- Material Design 3
