import 'package:cloud_firestore/cloud_firestore.dart';

/// Serviço base para operações CRUD no Firestore.
abstract class FirestoreService<T> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Nome da collection no Firestore.
  String get collectionName;

  /// Converte DocumentSnapshot para model T.
  T fromFirestore(DocumentSnapshot doc);

  /// Converte model T para Map (Firestore).
  Map<String, dynamic> toFirestore(T item);

  /// Reference da collection.
  CollectionReference get collection => _firestore.collection(collectionName);

  /// Lista todos os documentos.
  Future<List<T>> list({int limit = 50}) async {
    final snapshot = await collection
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
  }

  /// Lista documentos com filtro.
  Future<List<T>> listWhere(String field, dynamic value, {int limit = 50}) async {
    final snapshot = await collection
        .where(field, isEqualTo: value)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
  }

  /// Busca documento por ID.
  Future<T?> getById(String id) async {
    final doc = await collection.doc(id).get();
    if (!doc.exists) return null;
    return fromFirestore(doc);
  }

  /// Cria novo documento.
  Future<T> create(T item, {String? id}) async {
    final docRef = id != null ? collection.doc(id) : collection.doc();
    await docRef.set(toFirestore(item));
    return fromFirestore(await docRef.get());
  }

  /// Atualiza documento existente.
  Future<T> update(String id, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await collection.doc(id).update(data);
    return fromFirestore(await collection.doc(id).get());
  }

  /// Remove documento.
  Future<void> delete(String id) async {
    await collection.doc(id).delete();
  }

  /// Escuta mudanças em tempo real.
  Stream<List<T>> streamList() {
    return collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => fromFirestore(doc)).toList());
  }
}
