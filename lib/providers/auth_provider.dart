import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/user_model.dart';
import '../data/repositories/user_repository.dart';

/// Provider global para o UserRepository
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

/// Estado da Autenticação
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? errorMessage;

  AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Notifier do Riverpod que substitui o antigo AuthViewModel
class AuthNotifier extends StateNotifier<AuthState> {
  final UserRepository _userRepo;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  AuthNotifier(this._userRepo) : super(AuthState()) {
    _checkAuthState();
  }

  /// Verifica se o usuário já está logado no Firebase ao abrir o app
  Future<void> _checkAuthState() async {
    state = state.copyWith(isLoading: true);
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null) {
      // Sincroniza com SQLite
      final localUser = await _userRepo.getUserById(firebaseUser.uid);
      if (localUser != null) {
        state = state.copyWith(user: localUser, isLoading: false);
        return;
      }
    }
    state = state.copyWith(isLoading: false);
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // 1. Firebase Auth login
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Busca dados complementares no SQLite local (Offline-First)
      UserModel? user = await _userRepo.getUserById(userCredential.user!.uid);
      
      // Se não existir localmente, pode buscar do Firestore (implementaremos no futuro)
      if (user == null) {
        user = UserModel(
          id: userCredential.user!.uid,
          name: userCredential.user!.displayName ?? 'Usuário',
          email: email,
          password: password, // Mantido apenas por compatibilidade com regra anterior
        );
        await _userRepo.insertUser(user);
      }

      state = state.copyWith(user: user, isLoading: false);
      return true;
    } on FirebaseAuthException catch (e) {
      String msg = 'Erro de autenticação';
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        msg = 'Email ou senha inválidos';
      }
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // 1. Cria usuário no Firebase
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user!.updateDisplayName(name);

      // 2. Salva no banco local (SQLite)
      final newUser = UserModel(
        id: userCredential.user!.uid,
        name: name,
        email: email,
        password: password,
      );
      await _userRepo.insertUser(newUser);

      state = state.copyWith(user: newUser, isLoading: false);
      return true;
    } on FirebaseAuthException catch (e) {
      String msg = 'Erro ao cadastrar';
      if (e.code == 'email-already-in-use') {
        msg = 'Este email já está em uso';
      }
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
    state = AuthState();
  }
}

/// Provider que expõe o AuthNotifier
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(userRepositoryProvider);
  return AuthNotifier(repo);
});
