/// Pessoa do Flag Platform.
///
/// Shape de `/api/v1/persons`.
class Person {
  final String id;
  final String name;
  final String? cpf;
  final String? photoUrl;
  final String? status;
  final DateTime? birthDate;
  final String? gender;
  final String? city;
  final String role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Person({
    required this.id,
    required this.name,
    this.cpf,
    this.photoUrl,
    this.status,
    this.birthDate,
    this.gender,
    this.city,
    this.role = '',
    this.createdAt,
    this.updatedAt,
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'] as String,
      name: json['name'] as String,
      cpf: json['cpf'] as String?,
      photoUrl: json['photoUrl'] as String?,
      status: json['status'] as String?,
      birthDate: json['birthDate'] is String
          ? DateTime.tryParse(json['birthDate'] as String)
          : null,
      gender: json['gender'] as String?,
      city: json['city'] as String?,
      role: (json['role'] as String?) ?? '',
      createdAt: json['createdAt'] is String
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] is String
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Posicoes agora ficam no roster, nao na pessoa.
  /// Retorna string vazia para manter compatibilidade comtelas que chamam esse getter.
  String get positionsLabel => '';

  /// Retorna o nome traduzido do role da pessoa.
  String get roleLabel {
    return switch (role) {
      'ATHLETE' => 'Atleta',
      'COACH' => 'Técnico',
      'TECHNICAL_STAFF' => 'Comissão Técnica',
      'REFEREE' => 'Árbitro',
      'DELEGATE' => 'Delegado',
      'COMMISSIONER' => 'Comissário',
      _ => role,
    };
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        if (cpf != null) 'cpf': cpf,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (status != null) 'status': status,
        if (birthDate != null)
          'birthDate': birthDate!.toIso8601String(),
        if (gender != null) 'gender': gender,
        if (city != null) 'city': city,
        'role': role,
      };
}
