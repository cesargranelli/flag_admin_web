import 'package:flutter/foundation.dart';
import 'package:flag_admin_web/config/app_l10n.dart';
import 'package:flag_admin_web/data/repositories/auth_repository.dart';
import 'package:flag_admin_web/data/services/auth_service.dart';
import 'package:flag_admin_web/data/api/repository_exception.dart';
import 'package:flag_admin_web/domain/enums/user_role.dart';

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

  String? _role;
  String? get role => _role;

  static List<UserRole> get availableRoles =>
      UserRole.values.where((r) => r != UserRole.admin && r != UserRole.fan).toList();

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

  void setRole(String? value) {
    _role = value;
    notifyListeners();
  }

  /// Realiza o cadastro do organizador. Retorna true se concluído com sucesso.
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _isSuccess = false;
    notifyListeners();

    // Validação do papel
    if (_role == null) {
      _errorMessage = 'Selecione o perfil de acesso na plataforma';
      _isLoading = false;
      notifyListeners();
      return false;
    }
    final role = UserRole.fromJson(_role!);
    if (!availableRoles.contains(role)) {
      _errorMessage = 'Perfil de acesso inválido';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      // 1. Firebase Auth
      await _repository.signUp(
        name: name.trim().isEmpty ? 'Organizador' : name.trim(),
        email: email.trim(),
        password: password,
      );

      // 2. Backend — cria perfil do usuário
      await _repository.createUser(
        name: name.trim().isEmpty ? 'Organizador' : name.trim(),
        email: email.trim(),
        role: role.toJson(),
        status: 'PROVISIONAL',
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
