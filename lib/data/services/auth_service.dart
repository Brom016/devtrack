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

  // ─── Login Email & Password ───────────────────
  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final emailClean = email.trim().toLowerCase();

    // Debug: cek whitelist
    final allowed = await _isEmailAllowed(emailClean);
    if (!allowed) {
      throw Exception(
        'Akun $emailClean belum terdaftar di whitelist.\n'
        'Hubungi admin untuk mendapatkan akses.',
      );
    }

    // Login ke Firebase Auth
    final uc = await _auth.signInWithEmailAndPassword(
      email: emailClean,
      password: password,
    );

    await _saveOrUpdateUser(uc.user!);
    return uc;
  }

  // ─── Login Google (akan diaktifkan nanti) ────
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
      throw Exception(
        'Akun $email belum terdaftar.\nHubungi admin untuk mendapatkan akses.',
      );
    }

    await _saveOrUpdateUser(uc.user!);
    return uc;
  }

  // ─── Cek whitelist ────────────────────────────
  Future<bool> _isEmailAllowed(String email) async {
    try {
      final doc = await _db
          .collection(AppConstants.colAllowedUsers)
          .doc(email)
          .get();
      if (!doc.exists) return false;
      return (doc.data() as Map<String, dynamic>)['is_active'] == true;
    } catch (_) {
      return false;
    }
  }

  // ─── Simpan profil user ───────────────────────
  Future<void> _saveOrUpdateUser(User user) async {
    final ref = _db.collection(AppConstants.colUsers).doc(user.uid);
    final doc = await ref.get();

    if (!doc.exists) {
      // User baru → buat dengan role member
      await ref.set({
        'uid': user.uid,
        'display_name':
            user.displayName ?? user.email?.split('@').first ?? 'User',
        'email': user.email ?? '',
        'photo_url': user.photoURL ?? '',
        'role': AppConstants.roleMember,
        'created_at': FieldValue.serverTimestamp(),
      });
    } else {
      // User lama → update HANYA display_name dan photo
      // JANGAN timpa role yang sudah ada
      await ref.update({
        'display_name':
            user.displayName ?? user.email?.split('@').first ?? 'User',
        'photo_url': user.photoURL ?? '',
      });
    }
  }

  Stream<UserModel?> watchCurrentUser() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);
    return _db
        .collection(AppConstants.colUsers)
        .doc(user.uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
