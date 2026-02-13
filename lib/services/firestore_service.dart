import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Config Collections
  final CollectionReference _farmsCollection = FirebaseFirestore.instance.collection('farms');
  final CollectionReference _buyersCollection = FirebaseFirestore.instance.collection('buyers');
  final CollectionReference _mangoVarietiesCollection = FirebaseFirestore.instance.collection('mango_varieties');
  final CollectionReference _pesticideShopsCollection = FirebaseFirestore.instance.collection('pesticide_shops');
  final CollectionReference _workerSubCategoriesCollection = FirebaseFirestore.instance.collection('worker_sub_categories');

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

  // --- Config Data Streams ---
  Stream<List<Map<String, dynamic>>> getFarms() {
    return _farmsCollection.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        'name': doc['name'] as String,
      }).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getWorkerSubCategories() {
    return _workerSubCategoriesCollection.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        'name': doc['name'] as String,
      }).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getBuyers() {
    return _buyersCollection.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        'name': doc['name'] as String,
      }).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getVarieties({String? type}) {
    return _mangoVarietiesCollection.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                'name': doc['name'] as String,
                'type': (doc.data() as Map<String, dynamic>).containsKey('type') ? doc['type'] as String : 'Mango',
              })
          .where((v) => type == null || v['type'] == type)
          .toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getPesticideShops() {
    return _pesticideShopsCollection.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        'name': doc['name'] as String,
      }).toList();
    });
  }

  // --- Helper to add config data ---
  Future<void> _addConfigItem(CollectionReference collection, String name) async {
    final query = await collection.where('name', isEqualTo: name).get();
    if (query.docs.isEmpty) {
      final docRef = await collection.add({'name': name});
      await docRef.update({'id': docRef.id});
    } else {
      // Ensure existing documents have the explicit 'id' field
      for (var doc in query.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (!data.containsKey('id')) {
          await doc.reference.update({'id': doc.id});
        }
      }
    }
  }

  Future<void> addVariety(String name, String type) async {
    final query = await _mangoVarietiesCollection.where('name', isEqualTo: name).where('type', isEqualTo: type).get();
    if (query.docs.isEmpty) {
      final docRef = await _mangoVarietiesCollection.add({'name': name, 'type': type});
      await docRef.update({'id': docRef.id});
    }
  }

  Future<void> addFarm(String name) => _addConfigItem(_farmsCollection, name);
  Future<void> addBuyer(String name) => _addConfigItem(_buyersCollection, name);
  Future<void> addPesticideShop(String name) => _addConfigItem(_pesticideShopsCollection, name);
  Future<void> addWorkerSubCategory(String name) => _addConfigItem(_workerSubCategoriesCollection, name);

  // --- Helper to delete config data ---

  Future<void> _deleteConfigItem(CollectionReference collection, String name) async {
    final query = await collection.where('name', isEqualTo: name).get();
    for (var doc in query.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> deleteVariety(String name, String type) async {
    final query = await _mangoVarietiesCollection.where('name', isEqualTo: name).where('type', isEqualTo: type).get();
    for (var doc in query.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> deleteFarm(String name) => _deleteConfigItem(_farmsCollection, name);
  Future<void> deleteBuyer(String name) => _deleteConfigItem(_buyersCollection, name);
  Future<void> deletePesticideShop(String name) => _deleteConfigItem(_pesticideShopsCollection, name);
  Future<void> deleteWorkerSubCategory(String name) => _deleteConfigItem(_workerSubCategoriesCollection, name);



  Future<void> updateMetadata(String category, String id, String newName) async {
    CollectionReference collection;
    switch (category) {
      case 'Farms': collection = _farmsCollection; break;
      case 'Buyers': collection = _buyersCollection; break;
      case 'Mango Varieties': collection = _mangoVarietiesCollection; break;
      case 'Pesticide Shops': collection = _pesticideShopsCollection; break;
      case 'Worker Sub-Categories': collection = _workerSubCategoriesCollection; break;
      default: return;
    }
    await collection.doc(id).update({
      'name': newName,
      'id': id, // Ensure ID is present if it was missing
    });
  }

  Future<void> reconcileAllMetadata() async {
    final collections = [
      _farmsCollection,
      _buyersCollection,
      _mangoVarietiesCollection,
      _pesticideShopsCollection,
      _workerSubCategoriesCollection,
    ];

    for (var collection in collections) {
      final snapshot = await collection.get();
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (!data.containsKey('id')) {
          await doc.reference.update({'id': doc.id});
        }
      }
    }
  }

  // --- Initialization ---
  Future<void> initializeDefaultData() async {
    // Reconcile IDs for ALL items (including custom ones) to ensure visibility in Firestore
    await reconcileAllMetadata();
  }
}
