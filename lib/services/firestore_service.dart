import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addEntry(Map<String, dynamic> data) async {
    try {
      await _db.collection('farm_data').add(data);
    } catch (e) {
      rethrow;
    }
  }

  // Placeholder for future read methods
  Stream<QuerySnapshot> getEntries() {
    return _db.collection('farm_data').orderBy('date', descending: true).snapshots();
  }
}
