import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StoreIdentityService {
  StoreIdentityService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  Stream<String?> watchStoreKey() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream<String?>.value(null);
      }
      return _db.collection('stores').doc(user.uid).snapshots().map((doc) {
        final data = doc.data();
        return data?['storeKey'] as String?;
      });
    });
  }
}

