import 'package:flutter/foundation.dart';
import 'package:flag_admin_web/data/repositories/auth_repository.dart';
import 'package:flag_admin_web/data/services/auth_service.dart';
import 'package:flag_admin_web/data/api/repository_exception.dart';
import 'package:flag_admin_web/src/core/l10n/app_strings.dart';

/// ViewModel para a tela de Login (ADR-001 / MVVM 1:1).
class LoginViewModel extends ChangeNotifier {
  final AuthRepository _repository;
  final VoidCallback? _onAuthStateChanged;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _obscurePassword = true;
  bool get obscurePassword => _obscurePassword;

  bool _keepConnected = false;
  bool get keepConnected => _keepConnected;

  LoginViewModel({
    required AuthRepository repository,
    VoidCallback? onAuthStateChanged,
  })  : _repository = repository,
        _onAuthStateChanged = onAuthStateChanged;

  void toggleObscurePassword() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void setKeepConnected(bool value) {
    _keepConnected = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Realiza o login do usuário. Retorna 	rue em caso de sucesso.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.login(
        email: email.trim(),
        password: password,
        keepConnected: _keepConnected,
      );
      _isLoading = false;
      _onAuthStateChanged?.call();
      notifyListeners();
      return true;
    } on AuthServiceException catch (e) {
      _errorMessage = e.message;
    } on RepositoryException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = AppStrings.loginConnectionError;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }
}
