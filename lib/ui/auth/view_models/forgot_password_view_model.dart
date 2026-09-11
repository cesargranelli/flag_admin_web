import 'package:flutter/foundation.dart';
import 'package:flag_admin_web/data/repositories/auth_repository.dart';
import 'package:flag_admin_web/data/services/auth_service.dart';
import 'package:flag_admin_web/data/api/repository_exception.dart';
import 'package:flag_admin_web/config/app_l10n.dart';

/// ViewModel para a tela de Esqueci a Senha (ADR-001 / MVVM 1:1).
class ForgotPasswordViewModel extends ChangeNotifier {
  final AuthRepository _repository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isSent = false;
  bool get isSent => _isSent;

  ForgotPasswordViewModel({required AuthRepository repository})
    : _repository = repository;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void reset() {
    _isLoading = false;
    _errorMessage = null;
    _isSent = false;
    notifyListeners();
  }

  /// Envia e-mail de redefinição de senha. Retorna 	rue se enviado.
  Future<bool> sendPasswordReset(String email) async {
    _isLoading = true;
    _errorMessage = null;
    _isSent = false;
    notifyListeners();

    try {
      await _repository.sendPasswordReset(email.trim());
      _isLoading = false;
      _isSent = true;
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
