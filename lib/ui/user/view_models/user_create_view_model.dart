import 'package:flutter/foundation.dart';
import 'package:flag_admin_web/data/repositories/user_repository.dart';
import 'package:flag_admin_web/domain/enums/user_role.dart';

/// ViewModel para a criação de um novo Usuário (ADR-011 / MVVM).
class UserCreateViewModel extends ChangeNotifier {
  final UserRepository _repository;

  UserCreateViewModel({required UserRepository repository})
      : _repository = repository;

  // Form state
  String? _name;
  String? _email;
  String? _role;

  // Getters
  String? get name => _name;
  String? get email => _email;
  String? get role => _role;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Inicializa o formulário para criação.
  void init() {
    _name = null;
    _email = null;
    _role = UserRole.organizer.toJson();
    notifyListeners();
  }

  // Setters
  void setName(String? value) {
    _name = value;
    notifyListeners();
  }

  void setEmail(String? value) {
    _email = value;
    notifyListeners();
  }

  void setRole(String? value) {
    _role = value;
    notifyListeners();
  }

  /// Salva o novo usuário.
  Future<bool> save() async {
    final name = _name;
    final email = _email;
    final role = _role;

    if (name == null || name.isEmpty || email == null || email.isEmpty) {
      _errorMessage = 'Preencha todos os campos obrigatórios.';
      notifyListeners();
      return false;
    }

    // Valida que o role é um UserRole válido
    if (role == null || role.isEmpty || !UserRole.values.map((r) => r.toJson()).contains(role)) {
      _errorMessage = 'Selecione um perfil de usuário válido.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.createUser(
        name: name,
        email: email,
        role: role,
      );
      return true;
    } catch (e) {
      _errorMessage = 'Não foi possível criar o usuário.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}