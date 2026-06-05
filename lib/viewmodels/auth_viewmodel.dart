import 'package:flutter/foundation.dart';
import '../data/models/user_model.dart';
import '../data/repositories/user_repository.dart';

/// ViewModel responsável pela autenticação (login/cadastro).
/// Segue o padrão MVVM: a View observa mudanças via ChangeNotifier.
class AuthViewModel extends ChangeNotifier {
  final UserRepository _userRepository = UserRepository();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  // ---------------------------------------------------------------------------
  // Login
  // ---------------------------------------------------------------------------

  /// Tenta autenticar o usuário com email e senha.
  /// Retorna true se o login for bem-sucedido.
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _userRepository.authenticate(email, password);

      if (user == null) {
        _setError('Email ou senha inválidos.');
        return false;
      }

      _currentUser = user;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erro ao realizar login: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // Cadastro
  // ---------------------------------------------------------------------------

  /// Registra um novo usuário.
  /// Retorna true se o cadastro for bem-sucedido.
  Future<bool> register(String name, String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      // Verifica unicidade do email antes de inserir
      final exists = await _userRepository.emailExists(email);
      if (exists) {
        _setError('Este email já está cadastrado.');
        return false;
      }

      final user = UserModel(name: name, email: email, password: password);
      final id = await _userRepository.insertUser(user);

      // Auto-login após cadastro bem-sucedido
      _currentUser = user.copyWith(id: id);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erro ao cadastrar: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // Logout
  // ---------------------------------------------------------------------------

  /// Limpa a sessão do usuário.
  void logout() {
    _currentUser = null;
    _clearError();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Helpers internos
  // ---------------------------------------------------------------------------

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
