import 'package:cloud_firestore/cloud_firestore.dart';

/// Serviço base genérico de acesso ao Firestore.
///
/// Cada feature implementa [collectionName], [fromFirestore] e [toFirestore]
/// para o seu modelo, herdando as operações CRUD comuns.
abstract class FirestoreService<T> {
  /// Nome da coleção no Firestore.
  String get collectionName;

  /// Converte um [DocumentSnapshot] no modelo [T].
  T fromFirestore(DocumentSnapshot doc);

  /// Converte o modelo [T] em um mapa para gravação no Firestore.
  Map<String, dynamic> toFirestore(T item);

  /// Referência à coleção.
  CollectionReference<Map<String, dynamic>> get collection =>
      FirebaseFirestore.instance.collection(collectionName);

  /// Lista todos os documentos da coleção.
  Future<List<T>> list() async {
    final snapshot = await collection.get();
    return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
  }

  /// Lista documentos filtrando por [field] == [value].
  Future<List<T>> listWhere(String field, dynamic value) async {
    final snapshot = await collection.where(field, isEqualTo: value).get();
    return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
  }

  /// Busca um documento por id.
  Future<T?> getById(String id) async {
    final doc = await collection.doc(id).get();
    return doc.exists ? fromFirestore(doc) : null;
  }

  /// Cria um novo documento, retornando-o com o id preenchido.
  Future<T> create(T item) async {
    final data = toFirestore(item);
    final docRef = await collection.add(data);
    final doc = await docRef.get();
    return fromFirestore(doc);
  }

  /// Cria/atualiza um documento com id explícito.
  Future<void> setById(String id, T item) async {
    await collection.doc(id).set(toFirestore(item));
  }

  /// Atualiza parcialmente um documento por id.
  Future<void> update(String id, Map<String, dynamic> data) async {
    await collection.doc(id).update(data);
  }

  /// Remove um documento por id.
  Future<void> delete(String id) async {
    await collection.doc(id).delete();
  }

  /// Escuta a coleção inteira em tempo real.
  Stream<List<T>> streamList() {
    return collection
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => fromFirestore(doc)).toList());
  }

  /// Escuta a coleção filtrando por [field] == [value].
  Stream<List<T>> streamWhere(String field, dynamic value) {
    return collection
        .where(field, isEqualTo: value)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => fromFirestore(doc)).toList());
  }
}