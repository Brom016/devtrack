import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';

class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String photoUrl;
  final String role;

  UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.photoUrl,
    required this.role,
  });

  bool get isAdmin => role == AppConstants.roleAdmin;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      displayName: d['display_name'] ?? '',
      email: d['email'] ?? '',
      photoUrl: d['photo_url'] ?? '',
      role: d['role'] ?? AppConstants.roleMember,
    );
  }
}
