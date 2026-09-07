/// Tipo de agremiação esportiva (apenas Clubes e Universidades).
enum InstitutionType {
  club,
  university;

  static InstitutionType fromJson(String value) => switch (value.toUpperCase()) {
        'CLUB' => InstitutionType.club,
        'UNIVERSITY' => InstitutionType.university,
        _ => throw FormatException('Tipo de agremiação desconhecido: $value'),
      };

  String toJson() => switch (this) {
        InstitutionType.club => 'CLUB',
        InstitutionType.university => 'UNIVERSITY',
      };

  String get label => switch (this) {
        InstitutionType.club => 'Clube',
        InstitutionType.university => 'Universidade',
      };
}

/// Agremiação esportiva (Clube ou Universidade) do Flag Platform.
class Institution {
  final String id;
  final String name;
  final InstitutionType type;
  final List<String> colors;
  final List<String> organizations;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Institution({
    required this.id,
    required this.name,
    required this.type,
    this.colors = const [],
    this.organizations = const [],
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Institution.fromJson(Map<String, dynamic> json) => Institution(
        id: json['id'] as String,
        name: json['name'] as String,
        type: InstitutionType.fromJson(json['type'] as String),
        colors: (json['colors'] as List?)?.cast<String>() ?? const [],
        organizations:
            (json['organizations'] as List?)?.cast<String>() ?? const [],
        status: json['status'] as String?,
        createdAt: _tryParseDate(json['createdAt']),
        updatedAt: _tryParseDate(json['updatedAt']),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type.toJson(),
        'colors': colors,
        'organizations': organizations,
      };
}

DateTime? _tryParseDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
