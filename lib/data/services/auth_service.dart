import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../models/user_model.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn();
  final _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final uc = await _auth.signInWithCredential(credential);
    final email = uc.user?.email ?? '';
    final allowed = await _isEmailAllowed(email);
    if (!allowed) {
      await signOut();
      throw Exception('Akun $email belum terdaftar.\nHubungi admin untuk mendapatkan akses.');
    }
    await _saveOrUpdateUser(uc.user!);
    return uc;
  }

  Future<bool> _isEmailAllowed(String email) async {
    try {
      final doc = await _db.collection(AppConstants.colAllowedUsers).doc(email).get();
      if (!doc.exists) return false;
      return (doc.data() as Map<String, dynamic>)['is_active'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _saveOrUpdateUser(User user) async {
    final ref = _db.collection(AppConstants.colUsers).doc(user.uid);
    final doc = await ref.get();
    if (!doc.exists) {
      await ref.set({
        'uid': user.uid,
        'display_name': user.displayName ?? 'User',
        'email': user.email ?? '',
        'photo_url': user.photoURL ?? '',
        'role': AppConstants.roleMember,
        'created_at': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.update({
        'display_name': user.displayName ?? 'User',
        'photo_url': user.photoURL ?? '',
      });
    }
  }

  Stream<UserModel?> watchCurrentUser() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);
    return _db.collection(AppConstants.colUsers).doc(user.uid).snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
