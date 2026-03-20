import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../models/user_model.dart';

class UserRepository {
  final _db = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> watchAllowedUsers() => _db
      .collection(AppConstants.colAllowedUsers)
      .orderBy('added_at', descending: true).snapshots()
      .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  Future<void> addAllowedUser({
    required String email, required String name, required String addedByName,
  }) async => _db.collection(AppConstants.colAllowedUsers)
      .doc(email.toLowerCase().trim()).set({
    'email': email.toLowerCase().trim(), 'name': name.trim(),
    'added_by': addedByName, 'added_at': FieldValue.serverTimestamp(),
    'is_active': true,
  });

  Future<void> setUserActive(String email, bool isActive) async => _db
      .collection(AppConstants.colAllowedUsers).doc(email).update({'is_active': isActive});

  Future<void> removeAllowedUser(String email) async => _db
      .collection(AppConstants.colAllowedUsers).doc(email).delete();

  Stream<List<UserModel>> watchRegisteredUsers() => _db
      .collection(AppConstants.colUsers).orderBy('display_name').snapshots()
      .map((s) => s.docs.map(UserModel.fromFirestore).toList());

  Future<void> setUserRole(String uid, String role) async => _db
      .collection(AppConstants.colUsers).doc(uid).update({'role': role});
}
