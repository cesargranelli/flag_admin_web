import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/firestore_service.dart';
import '../../../../domain/domain.dart';

/// Mapeia um [DocumentSnapshot] da coleção `venues` para o [Venue] de
/// domínio.
///
/// O Firestore é espelho de escrita (ADR-006): o backend grava documentos
/// camelCase com datas como String ISO. Por robustez, o snapshot também pode
/// vir de qualquer outro escritor — por isso datas suportam `Timestamp` OU
/// `String ISO`.
Venue venueFromFirestore(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>? ?? const <String, dynamic>{};

  final id = (data['id'] as String?) ?? doc.id;

  return Venue(
    id: id,
    // TOLERÂNCIA (#53): o backend (entity/response) NÃO persiste
    // `organizationId` — o campo existe no model de domínio apenas para
    // compatibilidade com o REST de escrita (POST/PUT /api/v1/venues exigem).
    // No espelho Firestore o campo está sempre AUSENTE → default ''.
    organizationId: data['organizationId'] as String? ?? '',
    name: data['name'] as String? ?? '',
    address: data['address'] as String?,
    mapsUrl: data['mapsUrl'] as String?,
    createdAt: _parseDate(data['createdAt']),
    updatedAt: _parseDate(data['updatedAt']),
  );
}

/// Serializa o [Venue] de domínio em um mapa Firestore.
///
/// IMPORTANTE (ADR-006 / issue #53): o Admin Web NÃO escreve no Firestore —
/// a escrita permanece 100% via REST (`POST/PUT/DELETE /api/v1/venues`) e o
/// espelho é gravado pelo backend. Este método existe apenas para cumprir a
/// interface genérica [FirestoreService] e não deve ser usado em runtime.
Map<String, dynamic> venueToFirestore(Venue venue) => {
      'id': venue.id,
      'name': venue.name,
      if (venue.address != null) 'address': venue.address,
      if (venue.mapsUrl != null) 'mapsUrl': venue.mapsUrl,
    };

/// Data Firestore tolerante: `Timestamp` OU String ISO.
DateTime? _parseDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}

/// Serviço Firestore de campos de jogo (issue #53 — réplica do padrão #52).
///
/// Opera sobre o [Venue] de domínio. A escrita NÃO passa por aqui
/// (ADR-006): é 100% via REST e o Firestore é apenas espelho de leitura.
///
/// Diferente de organizações, NÃO existe filtro de status para venue (não há
/// `ACTIVE`): a listagem expõe TODOS os documentos da coleção, herdada da
/// base ([FirestoreService.streamList]).
class VenueFirestoreService extends FirestoreService<Venue> {
  @override
  String get collectionName => 'venues';

  @override
  Venue fromFirestore(DocumentSnapshot doc) => venueFromFirestore(doc);

  @override
  Map<String, dynamic> toFirestore(Venue item) => venueToFirestore(item);

  // `streamList()` é herdado da base ([FirestoreService]) — stream realtime
  // da coleção inteira, listando todos os venues (sem filtro de status).
}