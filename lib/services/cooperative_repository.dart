import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../models/cooperative.dart';

/// Firestore access for the cooperatives collection (Figure 3.4).
class CooperativeRepository {
  CooperativeRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(AppConstants.colCooperatives);

  /// All cooperatives, alphabetical.
  Stream<List<Cooperative>> watchAll() {
    return _col.orderBy('name').snapshots().map((snap) => snap.docs
        .map((d) => Cooperative.fromMap(d.id, d.data()))
        .toList());
  }

  /// Researcher-admin adds a cooperative. Returns its new ID.
  Future<String> add(Cooperative cooperative) async {
    final doc = await _col.add(cooperative.toMap());
    return doc.id;
  }

  Future<void> rename(String id, String name) {
    return _col.doc(id).update({'name': name.trim()});
  }
}
