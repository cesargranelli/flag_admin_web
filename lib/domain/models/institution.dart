import 'package:flag_admin_web/domain/models/organization.dart';

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

/// Agremiação esportiva (Clube ou Universidade) do Flag Platform (Domain Model - ADR-001).
class Institution {
  final String id;
  final String name;
  final String legalName;
  final String tradeName;
  final InstitutionType type;
  final String? abbreviation;
  final String? document;
  final DocumentType? documentType;
  final String? presidentName;
  final String? presidentCpf;
  final String? email;
  final String? phone;
  final String? website;
  final String? instagram;
  final String country;
  final String? state;
  final String? city;
  final String? logoUrl;
  final String? primaryColor;
  final String? secondaryColor;
  final String? tertiaryColor;
  final String? quaternaryColor;
  final List<String> colors;
  final List<String> organizations;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Institution({
    required this.id,
    required this.name,
    required this.legalName,
    required this.tradeName,
    required this.type,
    this.abbreviation,
    this.document,
    this.documentType,
    this.presidentName,
    this.presidentCpf,
    this.email,
    this.phone,
    this.website,
    this.instagram,
    this.country = 'BR',
    this.state,
    this.city,
    this.logoUrl,
    this.primaryColor,
    this.secondaryColor,
    this.tertiaryColor,
    this.quaternaryColor,
    this.colors = const [],
    this.organizations = const [],
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Institution.fromJson(Map<String, dynamic> json) {
    final tradeName = (json['tradeName'] as String?) ?? (json['name'] as String? ?? '');
    final legalName = (json['legalName'] as String?) ?? tradeName;

    return Institution(
      id: json['id'] as String,
      name: tradeName,
      tradeName: tradeName,
      legalName: legalName,
      type: InstitutionType.fromJson(json['type'] as String),
      abbreviation: json['abbreviation'] as String?,
      document: json['document'] as String?,
      documentType: json['documentType'] is String
          ? DocumentType.fromJson(json['documentType'] as String)
          : null,
      presidentName: json['presidentName'] as String?,
      presidentCpf: json['presidentCpf'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      instagram: json['instagram'] as String?,
      country: (json['country'] as String?) ?? 'BR',
      state: json['state'] as String?,
      city: json['city'] as String?,
      logoUrl: json['logoUrl'] as String?,
      primaryColor: json['primaryColor'] as String?,
      secondaryColor: json['secondaryColor'] as String?,
      tertiaryColor: json['tertiaryColor'] as String?,
      quaternaryColor: json['quaternaryColor'] as String?,
      colors: (json['colors'] as List?)?.cast<String>() ?? const [],
      organizations: (json['organizations'] as List?)?.cast<String>() ?? const [],
      status: json['status'] as String?,
      createdAt: _tryParseDate(json['createdAt']),
      updatedAt: _tryParseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': tradeName.isNotEmpty ? tradeName : name,
        'tradeName': tradeName.isNotEmpty ? tradeName : name,
        'legalName': legalName.isNotEmpty ? legalName : tradeName,
        'type': type.toJson(),
        if (abbreviation != null) 'abbreviation': abbreviation,
        if (document != null) 'document': document,
        if (documentType != null) 'documentType': documentType!.toJson(),
        if (presidentName != null) 'presidentName': presidentName,
        if (presidentCpf != null) 'presidentCpf': presidentCpf,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (website != null) 'website': website,
        if (instagram != null) 'instagram': instagram,
        'country': country,
        if (state != null) 'state': state,
        if (city != null) 'city': city,
        if (logoUrl != null) 'logoUrl': logoUrl,
        if (primaryColor != null) 'primaryColor': primaryColor,
        if (secondaryColor != null) 'secondaryColor': secondaryColor,
        if (tertiaryColor != null) 'tertiaryColor': tertiaryColor,
        if (quaternaryColor != null) 'quaternaryColor': quaternaryColor,
        'colors': colors,
        'organizationIds': organizations,
      };
}

DateTime? _tryParseDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
