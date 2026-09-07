import 'package:flutter/foundation.dart';
import 'package:flag_admin_web/data/repositories/auth_repository.dart';
import 'package:flag_admin_web/data/services/auth_service.dart';
import 'package:flag_admin_web/src/api/repository_exception.dart';
import 'package:flag_admin_web/src/core/l10n/app_strings.dart';

/// ViewModel para a tela de Cadastro de Organizador (ADR-001 / MVVM 1:1).
class SignupViewModel extends ChangeNotifier {
  final AuthRepository _repository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isSuccess = false;
  bool get isSuccess => _isSuccess;

  bool _obscurePassword = true;
  bool get obscurePassword => _obscurePassword;

  bool _obscureConfirm = true;
  bool get obscureConfirm => _obscureConfirm;

  SignupViewModel({required AuthRepository repository})
      : _repository = repository;

  void toggleObscurePassword() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void toggleObscureConfirm() {
    _obscureConfirm = !_obscureConfirm;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Realiza o cadastro do organizador. Retorna 	rue se concluído com sucesso.
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _isSuccess = false;
    notifyListeners();

    try {
      await _repository.signUp(
        name: name.trim().isEmpty ? 'Organizador' : name.trim(),
        email: email.trim(),
        password: password,
      );
      _isLoading = false;
      _isSuccess = true;
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
