# Plano de Execução Nível Máximo (16 Pontos)

## Especificação Técnica da Arquitetura
1. **State Management & DI**: Migração completa de `Provider` para `flutter_riverpod`. Os ViewModels se tornarão `StateNotifier` ou `AsyncNotifier` exportados via Providers injetáveis.
2. **Nuvem + Local (Offline-First)**: Integração do **Firebase (Auth e Firestore)** em paralelo com o **SQLite**. As operações de leitura dão prioridade ao SQLite, mas rodam sincronização assíncrona com o Firestore no background.
3. **Consumo de API Externa**: Integração com a API pública do **CoinGecko** (Trending Cryptos) ou uma API Mockada de notícias financeiras para evitar bloqueios de chaves pagas, exibindo um feed nativo na aba inferior do Dashboard.
4. **UX Premium**: 
   - Transições de tela em `FadeThrough` (animations).
   - Telas de Skeleton via biblioteca `shimmer`.
   - SnackBar responsiva para falha de rede/queda de Firebase.
5. **Release APK**: Configuração de script de build isolado.

## Fases de Implementação (Tasks)

- [ ] **Task 1: Setup do Riverpod e Firebase CLI**
  - Instalar `flutter_riverpod`, `firebase_core`, `cloud_firestore`, `firebase_auth`, `http`, `shimmer`, `connectivity_plus`.
  - Conectar Firebase (Necessita CLI do usuário ou mock configs).
  - Remover `Provider` do `pubspec.yaml` e reestruturar o `main.dart` com `ProviderScope`.

- [ ] **Task 2: Refatoração da Camada de Autenticação (Auth)**
  - Criar `auth_provider.dart` via Riverpod.
  - Implementar dupla gravação: Salva SQLite + Autentica Firebase.

- [ ] **Task 3: Refatoração da Camada de Transações (Offline-First)**
  - Criar `transaction_provider.dart` com `AsyncNotifier` para lidar com Skeleton/Shimmer state.
  - Sincronização Firestore <-> SQLite_Local.

- [ ] **Task 4: Integração de API Externa (Dicas / Notícias)**
  - Criar `news_repository.dart` e `news_provider.dart` usando pacote `http`.
  - Integrar widget de "Feed Financeiro" no `dashboard_screen.dart`.

- [ ] **Task 5: Refinamento de UX (Shimmer & Animations)**
  - Trocar CircularProgressIndicators por Skeletons (Shimmer).
  - Adicionar detecção de erro de rede.

- [ ] **Task 6: Build do APK**
  - Ajustar chaves e build.gradle e gerar `app-release.apk`.
