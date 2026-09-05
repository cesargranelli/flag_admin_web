import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/firestore_service.dart';
import '../../../../domain/domain.dart';

/// Mapeia um [DocumentSnapshot] da coleção `organizations` para o
/// [Organization] de domínio.
///
/// O Firestore é espelho de escrita (ADR-006): o backend grava documentos
/// camelCase com enums como String (`'ACTIVE'`, `'FEDERATION'`...) e datas
/// como String ISO (via MapStruct). Por robustez, o snapshot também pode vir
/// de qualquer outro escritor — por isso datas suportam `Timestamp` OU
/// `String ISO`, e enums são parseados de forma tolerante (valor desconhecido
/// vira `null` em vez de derrubar a stream inteira).
Organization organizationFromFirestore(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>? ?? const <String, dynamic>{};

  final id = (data['id'] as String?) ?? doc.id;

  return Organization(
    id: id,
    legalName: data['legalName'] as String? ?? '',
    tradeName: data['tradeName'] as String? ?? '',
    abbreviation: data['abbreviation'] as String?,
    organizationType: _parseEnum(
      data['organizationType'],
      OrganizationType.fromJson,
    ),
    document: data['document'] as String?,
    documentType: DocumentType.fromJson(data['documentType'] as String?),
    presidentName: data['presidentName'] as String?,
    presidentCpf: data['presidentCpf'] as String?,
    email: data['email'] as String?,
    phone: data['phone'] as String?,
    website: data['website'] as String?,
    instagram: data['instagram'] as String?,
    country: data['country'] as String? ?? '',
    state: data['state'] as String?,
    city: data['city'] as String?,
    logoUrl: data['logoUrl'] as String?,
    primaryColor: data['primaryColor'] as String?,
    secondaryColor: data['secondaryColor'] as String?,
    tertiaryColor: data['tertiaryColor'] as String?,
    quaternaryColor: data['quaternaryColor'] as String?,
    timezone: data['timezone'] as String? ?? '',
    locale: data['locale'] as String? ?? '',
    status: _parseEnum(data['status'], OrganizationStatus.fromJson),
    createdBy: data['createdBy'] as String?,
    createdAt: _parseDate(data['createdAt']),
    updatedAt: _parseDate(data['updatedAt']),
  );
}

/// Serializa a [Organization] de domínio em um mapa Firestore.
///
/// IMPORTANTE (ADR-006 / issue #52): o Admin Web NÃO escreve no Firestore —
/// a escrita permanece 100% via REST (`POST/DELETE /api/v1/organizations`) e
/// o espelho é gravado pelo backend. Este método existe apenas para cumprir
/// a interface genérica [FirestoreService] e não deve ser usado em runtime.
Map<String, dynamic> organizationToFirestore(Organization org) => {
      'id': org.id,
      'legalName': org.legalName,
      'tradeName': org.tradeName,
      if (org.abbreviation != null) 'abbreviation': org.abbreviation,
      if (org.organizationType != null)
        'organizationType': org.organizationType!.toJson(),
      if (org.document != null) 'document': org.document,
      if (org.documentType != null) 'documentType': org.documentType!.toJson(),
      if (org.presidentName != null) 'presidentName': org.presidentName,
      if (org.presidentCpf != null) 'presidentCpf': org.presidentCpf,
      if (org.email != null) 'email': org.email,
      if (org.phone != null) 'phone': org.phone,
      if (org.website != null) 'website': org.website,
      if (org.instagram != null) 'instagram': org.instagram,
      'country': org.country,
      if (org.state != null) 'state': org.state,
      if (org.city != null) 'city': org.city,
      if (org.logoUrl != null) 'logoUrl': org.logoUrl,
      if (org.primaryColor != null) 'primaryColor': org.primaryColor,
      if (org.secondaryColor != null) 'secondaryColor': org.secondaryColor,
      if (org.tertiaryColor != null) 'tertiaryColor': org.tertiaryColor,
      if (org.quaternaryColor != null) 'quaternaryColor': org.quaternaryColor,
      'timezone': org.timezone,
      'locale': org.locale,
      if (org.status != null) 'status': org.status!.toJson(),
      if (org.createdBy != null) 'createdBy': org.createdBy,
    };

/// Data Firestore tolerante: `Timestamp` OU String ISO.
DateTime? _parseDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}

/// Enum Firestore tolerante: valor desconhecido vira `null` em vez de
/// lançar [FormatException] (um doc corrompido não derruba a stream).
T? _parseEnum<T>(Object? value, T Function(String) parse) {
  if (value is! String) return null;
  try {
    return parse(value);
  } on FormatException {
    return null;
  }
}

/// Serviço Firestore de organizações (issue #52 — piloto de leitura realtime).
///
/// Opera sobre o [Organization] de domínio. A escrita NÃO passa por aqui
/// (ADR-006): é 100% via REST e o Firestore é apenas espelho de leitura.
class OrganizationFirestoreService extends FirestoreService<Organization> {
  @override
  String get collectionName => 'organizations';

  @override
  Organization fromFirestore(DocumentSnapshot doc) =>
      organizationFromFirestore(doc);

  @override
  Map<String, dynamic> toFirestore(Organization item) =>
      organizationToFirestore(item);

  /// Stream das organizações ATIVAS (decisão de visibilidade — issue #52).
  ///
  /// A leitura via Firestore expõe apenas `status == 'ACTIVE'`. Organizações
  /// desativadas (somente ADMIN) continuam via REST
  /// (`organizationsAdminProvider`, includeDisabled=true), protegida pelo
  /// backend — mantendo o controle de visibilidade no servidor.
  Stream<List<Organization>> streamActive() => streamWhere('status', 'ACTIVE');

  // `streamById(String id)` é herdado da base ([FirestoreService]) — stream
  // realtime de um documento por id, emitindo `null` quando não existir.
}
