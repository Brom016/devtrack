#!/bin/bash
# DevTrack — Auto Setup Script
# Jalankan dari root folder project: bash setup_devtrack.sh

echo "🚀 DevTrack Auto Setup dimulai..."

# ── Buat semua folder ──────────────────────────────────────────
mkdir -p lib/core/{constants,theme,router,utils}
mkdir -p lib/data/{models,repositories,services}
mkdir -p lib/presentation/providers
mkdir -p lib/presentation/widgets/common
mkdir -p lib/presentation/screens/auth
mkdir -p lib/presentation/screens/shared/profile
mkdir -p lib/presentation/screens/member/{dashboard,scanner,detail,history}
mkdir -p lib/presentation/screens/admin/{dashboard,devices,users,stats}
echo "✅ Folder struktur selesai"

# ══════════════════════════════════════════════════════════════
# CORE
# ══════════════════════════════════════════════════════════════

cat > lib/core/constants/app_constants.dart << 'EOF'
class AppConstants {
  static const String colUsers = 'users';
  static const String colDevices = 'devices';
  static const String colLogs = 'logs';
  static const String colAllowedUsers = 'allowed_users';
  static const String statusAvailable = 'available';
  static const String statusBorrowed = 'borrowed';
  static const String actionPinjam = 'PINJAM';
  static const String actionKembali = 'KEMBALI';
  static const String roleAdmin = 'admin';
  static const String roleMember = 'member';
  static const List<String> deviceCategories = [
    'Smartphone', 'Tablet', 'Laptop', 'Kamera', 'Aksesoris', 'Lainnya',
  ];
}
EOF

cat > lib/core/theme/app_theme.dart << 'EOF'
import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF1565C0);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: Color(0xFF1A1A2E),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Color(0xFF1A1A2E)),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Color(0xFFF0F0F0)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFFF8F8F8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor, width: 1.5),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            minimumSize: Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.dark,
        ),
      );
}
EOF

# ══════════════════════════════════════════════════════════════
# DATA — MODELS
# ══════════════════════════════════════════════════════════════

cat > lib/data/models/user_model.dart << 'EOF'
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
EOF

cat > lib/data/models/device_model.dart << 'EOF'
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';

class DeviceModel {
  final String deviceId;
  final String name;
  final String brand;
  final String category;
  final String status;
  final String qrCodeUrl;
  final String? currentHolderId;
  final String? currentHolderName;
  final Timestamp? borrowedAt;
  final int? estimatedDurationDays;

  DeviceModel({
    required this.deviceId,
    required this.name,
    required this.brand,
    required this.category,
    required this.status,
    this.qrCodeUrl = '',
    this.currentHolderId,
    this.currentHolderName,
    this.borrowedAt,
    this.estimatedDurationDays,
  });

  bool get isAvailable => status == AppConstants.statusAvailable;

  bool get isOverdue {
    if (borrowedAt == null || estimatedDurationDays == null) return false;
    final due = borrowedAt!.toDate().add(Duration(days: estimatedDurationDays!));
    return DateTime.now().isAfter(due);
  }

  factory DeviceModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return DeviceModel(
      deviceId: doc.id,
      name: d['name'] ?? '',
      brand: d['brand'] ?? '',
      category: d['category'] ?? '',
      status: d['status'] ?? AppConstants.statusAvailable,
      qrCodeUrl: d['qr_code_url'] ?? '',
      currentHolderId: d['current_holder_id'],
      currentHolderName: d['current_holder_name'],
      borrowedAt: d['borrowed_at'],
      estimatedDurationDays: d['estimated_duration_days'],
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'brand': brand,
        'category': category,
        'status': status,
        'qr_code_url': qrCodeUrl,
        'current_holder_id': currentHolderId,
        'current_holder_name': currentHolderName,
        'borrowed_at': borrowedAt,
        'estimated_duration_days': estimatedDurationDays,
        'created_at': FieldValue.serverTimestamp(),
      };
}
EOF

cat > lib/data/models/log_model.dart << 'EOF'
import 'package:cloud_firestore/cloud_firestore.dart';

class LogModel {
  final String logId;
  final String assetId;
  final String userId;
  final String userName;
  final String actionType;
  final String? conditionNote;
  final int? estimatedDays;
  final Timestamp timestamp;

  LogModel({
    required this.logId,
    required this.assetId,
    required this.userId,
    required this.userName,
    required this.actionType,
    this.conditionNote,
    this.estimatedDays,
    required this.timestamp,
  });

  bool get isPinjam => actionType == 'PINJAM';

  factory LogModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return LogModel(
      logId: doc.id,
      assetId: d['asset_id'] ?? '',
      userId: d['user_id'] ?? '',
      userName: d['user_name'] ?? '',
      actionType: d['action_type'] ?? '',
      conditionNote: d['condition_note'],
      estimatedDays: d['estimated_days'],
      timestamp: d['timestamp'] ?? Timestamp.now(),
    );
  }
}
EOF

# ══════════════════════════════════════════════════════════════
# DATA — SERVICES
# ══════════════════════════════════════════════════════════════

cat > lib/data/services/auth_service.dart << 'EOF'
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
EOF

cat > lib/data/services/seed_service.dart << 'EOF'
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';

class SeedService {
  static Future<void> seedDevices() async {
    final db = FirebaseFirestore.instance;
    final col = db.collection(AppConstants.colDevices);
    final existing = await col.limit(1).get();
    if (existing.docs.isNotEmpty) return;
    final devices = [
      {'id': 'MOB-01', 'name': 'iPhone 14 Pro', 'brand': 'Apple', 'category': 'Smartphone'},
      {'id': 'MOB-02', 'name': 'Samsung Galaxy S24', 'brand': 'Samsung', 'category': 'Smartphone'},
      {'id': 'MOB-03', 'name': 'Pixel 8 Pro', 'brand': 'Google', 'category': 'Smartphone'},
      {'id': 'TAB-01', 'name': 'iPad Pro 12.9"', 'brand': 'Apple', 'category': 'Tablet'},
      {'id': 'LAP-01', 'name': 'MacBook Pro M3', 'brand': 'Apple', 'category': 'Laptop'},
      {'id': 'LAP-02', 'name': 'ThinkPad X1 Carbon', 'brand': 'Lenovo', 'category': 'Laptop'},
      {'id': 'CAM-01', 'name': 'Sony ZV-E10', 'brand': 'Sony', 'category': 'Kamera'},
    ];
    final batch = db.batch();
    for (final d in devices) {
      batch.set(col.doc(d['id']), {
        'name': d['name'], 'brand': d['brand'], 'category': d['category'],
        'status': AppConstants.statusAvailable, 'qr_code_url': '',
        'current_holder_id': null, 'current_holder_name': null,
        'borrowed_at': null, 'estimated_duration_days': null,
        'created_at': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}
EOF

# ══════════════════════════════════════════════════════════════
# DATA — REPOSITORIES
# ══════════════════════════════════════════════════════════════

cat > lib/data/repositories/device_repository.dart << 'EOF'
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../models/device_model.dart';
import '../models/log_model.dart';

class DeviceRepository {
  final _db = FirebaseFirestore.instance;

  Stream<List<DeviceModel>> watchAllDevices() => _db
      .collection(AppConstants.colDevices).orderBy('name').snapshots()
      .map((s) => s.docs.map(DeviceModel.fromFirestore).toList());

  Stream<DeviceModel?> watchDeviceById(String id) => _db
      .collection(AppConstants.colDevices).doc(id).snapshots()
      .map((d) => d.exists ? DeviceModel.fromFirestore(d) : null);

  Stream<List<LogModel>> watchAllLogs({int limit = 50}) => _db
      .collection(AppConstants.colLogs)
      .orderBy('timestamp', descending: true).limit(limit).snapshots()
      .map((s) => s.docs.map(LogModel.fromFirestore).toList());

  Stream<List<LogModel>> watchDeviceLogs(String deviceId) => _db
      .collection(AppConstants.colLogs)
      .where('asset_id', isEqualTo: deviceId)
      .orderBy('timestamp', descending: true).limit(20).snapshots()
      .map((s) => s.docs.map(LogModel.fromFirestore).toList());

  Future<void> addDevice(DeviceModel device) async =>
      _db.collection(AppConstants.colDevices).doc(device.deviceId).set(device.toMap());

  Future<void> deleteDevice(String id) async =>
      _db.collection(AppConstants.colDevices).doc(id).delete();

  Future<void> borrowDevice({
    required String deviceId, required String userId,
    required String userName, required int estimatedDays,
  }) async {
    final batch = _db.batch();
    final now = Timestamp.now();
    batch.update(_db.collection(AppConstants.colDevices).doc(deviceId), {
      'status': AppConstants.statusBorrowed,
      'current_holder_id': userId, 'current_holder_name': userName,
      'borrowed_at': now, 'estimated_duration_days': estimatedDays,
    });
    batch.set(_db.collection(AppConstants.colLogs).doc(), {
      'asset_id': deviceId, 'user_id': userId, 'user_name': userName,
      'action_type': AppConstants.actionPinjam,
      'condition_note': null, 'estimated_days': estimatedDays, 'timestamp': now,
    });
    await batch.commit();
  }

  Future<void> returnDevice({
    required String deviceId, required String userId,
    required String userName, required String conditionNote,
  }) async {
    final batch = _db.batch();
    batch.update(_db.collection(AppConstants.colDevices).doc(deviceId), {
      'status': AppConstants.statusAvailable,
      'current_holder_id': FieldValue.delete(),
      'current_holder_name': FieldValue.delete(),
      'borrowed_at': FieldValue.delete(),
      'estimated_duration_days': FieldValue.delete(),
    });
    batch.set(_db.collection(AppConstants.colLogs).doc(), {
      'asset_id': deviceId, 'user_id': userId, 'user_name': userName,
      'action_type': AppConstants.actionKembali,
      'condition_note': conditionNote, 'estimated_days': null,
      'timestamp': Timestamp.now(),
    });
    await batch.commit();
  }
}
EOF

cat > lib/data/repositories/user_repository.dart << 'EOF'
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
EOF

# ══════════════════════════════════════════════════════════════
# PROVIDERS
# ══════════════════════════════════════════════════════════════

cat > lib/presentation/providers/providers.dart << 'EOF'
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/device_model.dart';
import '../../data/models/log_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/device_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) =>
    ref.watch(authServiceProvider).authStateChanges);

final currentUserModelProvider = StreamProvider<UserModel?>((ref) =>
    ref.watch(authServiceProvider).watchCurrentUser());

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) => DeviceRepository());

final allDevicesProvider = StreamProvider<List<DeviceModel>>((ref) =>
    ref.watch(deviceRepositoryProvider).watchAllDevices());

final deviceByIdProvider = StreamProvider.family<DeviceModel?, String>((ref, id) =>
    ref.watch(deviceRepositoryProvider).watchDeviceById(id));

final allLogsProvider = StreamProvider<List<LogModel>>((ref) =>
    ref.watch(deviceRepositoryProvider).watchAllLogs());

final deviceLogsProvider = StreamProvider.family<List<LogModel>, String>((ref, deviceId) =>
    ref.watch(deviceRepositoryProvider).watchDeviceLogs(deviceId));

final userRepositoryProvider = Provider<UserRepository>((ref) => UserRepository());

final allowedUsersProvider = StreamProvider<List<Map<String, dynamic>>>((ref) =>
    ref.watch(userRepositoryProvider).watchAllowedUsers());

final deviceStatsProvider = Provider<Map<String, int>>((ref) {
  final devices = ref.watch(allDevicesProvider).valueOrNull ?? [];
  return {
    'total': devices.length,
    'available': devices.where((d) => d.isAvailable).length,
    'borrowed': devices.where((d) => !d.isAvailable).length,
    'overdue': devices.where((d) => d.isOverdue).length,
  };
});
EOF

# ══════════════════════════════════════════════════════════════
# WIDGETS
# ══════════════════════════════════════════════════════════════

cat > lib/presentation/widgets/common/common_widgets.dart << 'EOF'
import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool isOverdue;
  const StatusBadge({super.key, required this.status, this.isOverdue = false});
  @override
  Widget build(BuildContext context) {
    final isAvail = status == 'available';
    Color bg, fg;
    String label;
    if (isOverdue && !isAvail) { bg = Colors.red.shade100; fg = Colors.red.shade800; label = 'Terlambat'; }
    else if (isAvail) { bg = Colors.green.shade100; fg = Colors.green.shade800; label = 'Available'; }
    else { bg = Colors.orange.shade100; fg = Colors.orange.shade800; label = 'Dipinjam'; }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 11)),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  const EmptyState({super.key, required this.message, this.icon = Icons.inbox_outlined, this.actionLabel, this.onAction});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 64, color: Colors.grey.shade300),
      const SizedBox(height: 12),
      Text(message, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
      if (actionLabel != null && onAction != null) ...[
        const SizedBox(height: 12),
        TextButton.icon(onPressed: onAction, icon: const Icon(Icons.add), label: Text(actionLabel!)),
      ],
    ]),
  );
}

class ErrorState extends StatelessWidget {
  final String message;
  const ErrorState({super.key, required this.message});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(padding: const EdgeInsets.all(24), child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.red),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
      ],
    )),
  );
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionHeader({super.key, required this.title, this.action, this.onAction});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      if (action != null) TextButton(onPressed: onAction, child: Text(action!, style: const TextStyle(fontSize: 13))),
    ],
  );
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const InfoRow(this.label, this.value, {super.key, this.valueColor});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 110, child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13))),
      Expanded(child: Text(value, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: valueColor))),
    ]),
  );
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const StatCard({super.key, required this.label, required this.value, required this.color, required this.icon});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ]),
    ),
  );
}
EOF

cat > lib/presentation/widgets/device_card.dart << 'EOF'
import 'package:flutter/material.dart';
import '../../data/models/device_model.dart';
import 'common/common_widgets.dart';

class DeviceCard extends StatelessWidget {
  final DeviceModel device;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  const DeviceCard({super.key, required this.device, required this.onTap, this.onLongPress});

  IconData get _icon {
    switch (device.category) {
      case 'Smartphone': return Icons.smartphone;
      case 'Tablet': return Icons.tablet;
      case 'Laptop': return Icons.laptop;
      case 'Kamera': return Icons.camera_alt;
      default: return Icons.devices_other;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAvail = device.isAvailable;
    return Card(
      child: InkWell(
        onTap: onTap, onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: isAvail ? Colors.blue.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon, color: isAvail ? Colors.blue : Colors.orange, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(device.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 2),
              Text('${device.brand} · ${device.category} · ${device.deviceId}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
              if (!isAvail && device.currentHolderName != null) ...[
                const SizedBox(height: 3),
                Text('Oleh: ${device.currentHolderName}',
                    style: TextStyle(color: Colors.orange.shade700, fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ])),
            StatusBadge(status: device.status, isOverdue: device.isOverdue),
          ]),
        ),
      ),
    );
  }
}
EOF

# ══════════════════════════════════════════════════════════════
# SCREENS — AUTH
# ══════════════════════════════════════════════════════════════

cat > lib/presentation/screens/auth/login_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    try {
      final result = await ref.read(authServiceProvider).signInWithGoogle();
      if (result != null && mounted) context.go('/home');
    } on Exception catch (e) {
      if (mounted) _showError(e.toString().replaceAll('Exception: ', ''));
    } catch (e) {
      if (mounted) _showError('Login gagal. Silakan coba lagi.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 5)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(children: [
            const Spacer(flex: 2),
            Container(
              width: 88, height: 88,
              decoration: BoxDecoration(color: const Color(0xFF1565C0), borderRadius: BorderRadius.circular(24)),
              child: const Icon(Icons.devices_rounded, color: Colors.white, size: 44),
            ),
            const SizedBox(height: 20),
            const Text('DevTrack', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
            const SizedBox(height: 6),
            Text('Asset Management System', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            const Spacer(flex: 2),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text('Hanya akun yang telah didaftarkan admin yang dapat masuk.',
                    style: TextStyle(color: Colors.blue.shade800, fontSize: 12, height: 1.4))),
              ]),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 52,
              child: FilledButton(
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.login_rounded, size: 20),
                        SizedBox(width: 10),
                        Text('Masuk dengan Google', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ]),
              ),
            ),
            const Spacer(),
            Text('DevTrack v1.0.0', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }
}
EOF

# ══════════════════════════════════════════════════════════════
# SCREENS — HOME SHELL
# ══════════════════════════════════════════════════════════════

cat > lib/presentation/screens/home_shell.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import 'admin/dashboard/admin_dashboard_screen.dart';
import 'admin/devices/admin_devices_screen.dart';
import 'admin/users/admin_users_screen.dart';
import 'admin/stats/admin_stats_screen.dart';
import 'member/dashboard/member_dashboard_screen.dart';
import 'member/scanner/scanner_screen.dart';
import 'member/history/history_screen.dart';
import 'shared/profile/profile_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});
  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _idx = 0;

  @override
  Widget build(BuildContext context) {
    return ref.watch(currentUserModelProvider).when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const Scaffold(body: Center(child: Text('Error memuat profil'))),
      data: (user) {
        if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final isAdmin = user.isAdmin;
        final screens = isAdmin
            ? [const AdminDashboardScreen(), const AdminDevicesScreen(), const AdminUsersScreen(), const AdminStatsScreen(), const ProfileScreen()]
            : [const MemberDashboardScreen(), const ScannerScreen(), const HistoryScreen(), const ProfileScreen()];
        final items = isAdmin
            ? const [
                BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
                BottomNavigationBarItem(icon: Icon(Icons.devices_outlined), activeIcon: Icon(Icons.devices), label: 'Device'),
                BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Users'),
                BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart), label: 'Statistik'),
                BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
              ]
            : const [
                BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner_outlined), activeIcon: Icon(Icons.qr_code_scanner), label: 'Scan QR'),
                BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'Riwayat'),
                BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
              ];
        final safeIdx = _idx.clamp(0, screens.length - 1);
        return Scaffold(
          body: IndexedStack(index: safeIdx, children: screens),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: safeIdx,
            onTap: (i) => setState(() => _idx = i),
            items: items,
          ),
        );
      },
    );
  }
}
EOF

# ══════════════════════════════════════════════════════════════
# SCREENS — MEMBER
# ══════════════════════════════════════════════════════════════

cat > lib/presentation/screens/member/dashboard/member_dashboard_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../providers/providers.dart';
import '../../../widgets/device_card.dart';
import '../../../widgets/common/common_widgets.dart';

class MemberDashboardScreen extends ConsumerStatefulWidget {
  const MemberDashboardScreen({super.key});
  @override
  ConsumerState<MemberDashboardScreen> createState() => _State();
}

class _State extends ConsumerState<MemberDashboardScreen> {
  String _filter = 'Semua';
  final _filters = ['Semua', 'Available', 'Borrowed'];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final devicesAsync = ref.watch(allDevicesProvider);
    final stats = ref.watch(deviceStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(width: 28, height: 28,
            decoration: BoxDecoration(color: const Color(0xFF1565C0), borderRadius: BorderRadius.circular(7)),
            child: const Icon(Icons.devices_rounded, color: Colors.white, size: 16)),
          const SizedBox(width: 8),
          const Text('DevTrack'),
        ]),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(allDevicesProvider),
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: Container(color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Halo, ${user?.displayName?.split(' ').first ?? 'User'}! 👋',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text('Kelola peminjaman device kantor', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            ]))),
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(16),
            child: Row(children: [
              StatCard(label: 'Total', value: '${stats['total'] ?? 0}', color: const Color(0xFF1565C0), icon: Icons.devices),
              const SizedBox(width: 10),
              StatCard(label: 'Available', value: '${stats['available'] ?? 0}', color: Colors.green, icon: Icons.check_circle_outline),
              const SizedBox(width: 10),
              StatCard(label: 'Dipinjam', value: '${stats['borrowed'] ?? 0}', color: Colors.orange, icon: Icons.pending_outlined),
            ]))),
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(children: [
              const Text('Daftar Device', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const Spacer(),
              ..._filters.map((f) {
                final sel = _filter == f;
                return Padding(padding: const EdgeInsets.only(left: 6),
                  child: GestureDetector(onTap: () => setState(() => _filter = f),
                    child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel ? const Color(0xFF1565C0) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: sel ? const Color(0xFF1565C0) : Colors.grey.shade300),
                      ),
                      child: Text(f, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                          color: sel ? Colors.white : Colors.grey.shade700)))));
              }),
            ]))),
          devicesAsync.when(
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SliverFillRemaining(child: ErrorState(message: e.toString())),
            data: (devices) {
              final filtered = _filter == 'Semua' ? devices
                  : devices.where((d) => d.status.toLowerCase() == _filter.toLowerCase()).toList();
              if (filtered.isEmpty) return SliverFillRemaining(
                  child: EmptyState(message: 'Tidak ada device $_filter', icon: Icons.devices_other));
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(delegate: SliverChildBuilderDelegate(
                  (context, i) => Padding(padding: const EdgeInsets.only(bottom: 10),
                      child: DeviceCard(device: filtered[i],
                          onTap: () => context.push('/device/${filtered[i].deviceId}'))),
                  childCount: filtered.length,
                )));
            },
          ),
        ]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/scanner'),
        backgroundColor: const Color(0xFF1565C0),
        icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
        label: const Text('Scan QR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
EOF

cat > lib/presentation/screens/member/scanner/scanner_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});
  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool _scanned = false;

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;
    _scanned = true;
    context.push('/device/$raw');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: Colors.white,
          title: const Text('Scan QR Device'), automaticallyImplyLeading: false),
      body: Stack(children: [
        MobileScanner(onDetect: _onDetect),
        Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 240, height: 240,
            decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2.5),
                borderRadius: BorderRadius.circular(16))),
          const SizedBox(height: 24),
          Text('Arahkan ke QR Code device', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14)),
        ])),
        if (_scanned) Center(child: ElevatedButton(
            onPressed: () => setState(() => _scanned = false), child: const Text('Scan Ulang'))),
      ]),
    );
  }
}
EOF

cat > lib/presentation/screens/member/history/history_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../providers/providers.dart';
import '../../../widgets/common/common_widgets.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(allLogsProvider);
    final fmt = DateFormat('dd MMM yyyy, HH:mm');
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Aktivitas')),
      body: logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(message: e.toString()),
        data: (logs) {
          if (logs.isEmpty) return const EmptyState(message: 'Belum ada aktivitas', icon: Icons.history);
          return ListView.separated(
            padding: const EdgeInsets.all(16), itemCount: logs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final log = logs[i];
              return ListTile(
                leading: CircleAvatar(radius: 20,
                  backgroundColor: log.isPinjam ? Colors.blue.shade100 : Colors.grey.shade200,
                  child: Icon(log.isPinjam ? Icons.login_rounded : Icons.logout_rounded,
                      color: log.isPinjam ? Colors.blue.shade700 : Colors.grey.shade600, size: 18)),
                title: Text('${log.actionType}  —  ${log.assetId}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                subtitle: Text(log.userName, style: const TextStyle(fontSize: 12)),
                trailing: Text(fmt.format(log.timestamp.toDate()),
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500), textAlign: TextAlign.right),
              );
            },
          );
        },
      ),
    );
  }
}
EOF

cat > lib/presentation/screens/member/detail/device_detail_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../providers/providers.dart';
import '../../../widgets/common/common_widgets.dart';

class DeviceDetailScreen extends ConsumerStatefulWidget {
  final String deviceId;
  const DeviceDetailScreen({super.key, required this.deviceId});
  @override
  ConsumerState<DeviceDetailScreen> createState() => _State();
}

class _State extends ConsumerState<DeviceDetailScreen> {
  final _durasiCtrl = TextEditingController(text: '1');
  final _catatanCtrl = TextEditingController();
  bool _isLoading = false;
  String _kondisi = 'OK';

  @override
  void dispose() { _durasiCtrl.dispose(); _catatanCtrl.dispose(); super.dispose(); }

  void _snack(String msg, Color color) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating));

  Future<void> _pinjam(String id) async {
    final durasi = int.tryParse(_durasiCtrl.text) ?? 1;
    if (durasi < 1) { _snack('Durasi minimal 1 hari', Colors.red); return; }
    final user = FirebaseAuth.instance.currentUser!;
    setState(() => _isLoading = true);
    try {
      await ref.read(deviceRepositoryProvider).borrowDevice(
          deviceId: id, userId: user.uid, userName: user.displayName ?? 'Unknown', estimatedDays: durasi);
      if (mounted) { _snack('Device berhasil dipinjam!', Colors.green); context.go('/home'); }
    } catch (e) { if (mounted) _snack('Gagal: $e', Colors.red); }
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  Future<void> _kembalikan(String id) async {
    final user = FirebaseAuth.instance.currentUser!;
    final note = '$_kondisi${_catatanCtrl.text.isNotEmpty ? ' - ${_catatanCtrl.text}' : ''}';
    setState(() => _isLoading = true);
    try {
      await ref.read(deviceRepositoryProvider).returnDevice(
          deviceId: id, userId: user.uid, userName: user.displayName ?? 'Unknown', conditionNote: note);
      if (mounted) { _snack('Device berhasil dikembalikan!', Colors.green); context.go('/home'); }
    } catch (e) { if (mounted) _snack('Gagal: $e', Colors.red); }
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final deviceAsync = ref.watch(deviceByIdProvider(widget.deviceId));
    final logsAsync = ref.watch(deviceLogsProvider(widget.deviceId));
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final fmt = DateFormat('dd MMM yyyy, HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Device'),
          leading: IconButton(icon: const Icon(Icons.arrow_back),
              onPressed: () => context.canPop() ? context.pop() : context.go('/home'))),
      body: deviceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(message: e.toString()),
        data: (device) {
          if (device == null) return const Center(child: Text('Device tidak ditemukan.\nPastikan QR code valid.'));
          final isAvail = device.isAvailable;
          final isMe = device.currentHolderId == uid;
          return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(device.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(device.deviceId, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ])),
                    StatusBadge(status: device.status, isOverdue: device.isOverdue),
                  ]),
                  const Divider(height: 24),
                  InfoRow('Brand', device.brand),
                  InfoRow('Kategori', device.category),
                  if (!isAvail) ...[
                    const Divider(height: 16),
                    InfoRow('Dipinjam oleh', device.currentHolderName ?? '-', valueColor: Colors.orange.shade700),
                    if (device.borrowedAt != null) InfoRow('Sejak', fmt.format(device.borrowedAt!.toDate())),
                    if (device.estimatedDurationDays != null)
                      InfoRow('Est. kembali',
                          fmt.format(device.borrowedAt!.toDate().add(Duration(days: device.estimatedDurationDays!))),
                          valueColor: device.isOverdue ? Colors.red : null),
                  ],
                ],
              ))),
              const SizedBox(height: 16),
              if (isAvail) _pinjamCard(device.deviceId),
              if (!isAvail && isMe) _kembalikanCard(device.deviceId),
              if (!isAvail && !isMe) _kontakCard(device.currentHolderName ?? 'peminjam'),
              const SizedBox(height: 24),
              const Text('Riwayat device ini', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              logsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox(),
                data: (logs) {
                  if (logs.isEmpty) return Text('Belum ada riwayat', style: TextStyle(color: Colors.grey.shade500, fontSize: 13));
                  return Column(children: logs.map((log) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: log.isPinjam ? Colors.blue.shade50 : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: log.isPinjam ? Colors.blue.shade100 : Colors.grey.shade200),
                    ),
                    child: Row(children: [
                      Icon(log.isPinjam ? Icons.login_rounded : Icons.logout_rounded,
                          color: log.isPinjam ? Colors.blue : Colors.grey, size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${log.actionType} oleh ${log.userName}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        if (log.conditionNote != null && log.conditionNote!.isNotEmpty)
                          Text(log.conditionNote!, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                      ])),
                      Text(fmt.format(log.timestamp.toDate()),
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
                    ]),
                  )).toList());
                },
              ),
            ],
          ));
        },
      ),
    );
  }

  Widget _pinjamCard(String id) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Pinjam device ini', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      const SizedBox(height: 12),
      TextField(controller: _durasiCtrl, keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Estimasi durasi', suffixText: 'hari',
              prefixIcon: Icon(Icons.calendar_today_outlined))),
      const SizedBox(height: 16),
      SizedBox(width: double.infinity, child: FilledButton.icon(
        onPressed: _isLoading ? null : () => _pinjam(id),
        icon: _isLoading ? const SizedBox(width: 18, height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.handshake_outlined),
        label: const Text('Pinjam Sekarang'),
      )),
    ],
  )));

  Widget _kembalikanCard(String id) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Kembalikan device', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      const SizedBox(height: 12),
      const Text('Kondisi saat dikembalikan:', style: TextStyle(fontSize: 13)),
      const SizedBox(height: 8),
      SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'OK', label: Text('Kondisi OK'), icon: Icon(Icons.check_circle_outline)),
          ButtonSegment(value: 'Rusak', label: Text('Rusak'), icon: Icon(Icons.warning_amber_outlined)),
        ],
        selected: {_kondisi},
        onSelectionChanged: (v) => setState(() => _kondisi = v.first),
      ),
      const SizedBox(height: 12),
      TextField(controller: _catatanCtrl, maxLines: 3,
          decoration: const InputDecoration(labelText: 'Catatan tambahan (opsional)',
              hintText: 'Contoh: Baterai 80%, layar normal')),
      const SizedBox(height: 16),
      SizedBox(width: double.infinity, child: FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: Colors.orange),
        onPressed: _isLoading ? null : () => _kembalikan(id),
        icon: _isLoading ? const SizedBox(width: 18, height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.assignment_return_outlined),
        label: const Text('Kembalikan Device'),
      )),
    ],
  )));

  Widget _kontakCard(String name) => Card(
    color: Colors.orange.shade50,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.orange.shade200)),
    child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      Icon(Icons.person_search_outlined, color: Colors.orange.shade700, size: 36),
      const SizedBox(height: 8),
      Text('Sedang dipakai oleh $name', textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
      const SizedBox(height: 4),
      Text('Hubungi peminjam untuk info lebih lanjut', textAlign: TextAlign.center,
          style: TextStyle(color: Colors.orange.shade600, fontSize: 12)),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: OutlinedButton.icon(onPressed: () {},
            icon: const Icon(Icons.chat_outlined, size: 18), label: const Text('WhatsApp'))),
        const SizedBox(width: 10),
        Expanded(child: OutlinedButton.icon(onPressed: () {},
            icon: const Icon(Icons.message_outlined, size: 18), label: const Text('Slack'))),
      ]),
    ])),
  );
}
EOF

# ══════════════════════════════════════════════════════════════
# SCREENS — ADMIN
# ══════════════════════════════════════════════════════════════

cat > lib/presentation/screens/admin/dashboard/admin_dashboard_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../providers/providers.dart';
import '../../../widgets/common/common_widgets.dart';
import '../../../widgets/device_card.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(deviceStatsProvider);
    final devicesAsync = ref.watch(allDevicesProvider);
    final logsAsync = ref.watch(allLogsProvider);
    final fmt = DateFormat('dd MMM, HH:mm');
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: RefreshIndicator(
        onRefresh: () async { ref.invalidate(allDevicesProvider); ref.invalidate(allLogsProvider); },
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Row(children: [
            StatCard(label: 'Total', value: '${stats['total'] ?? 0}', color: const Color(0xFF1565C0), icon: Icons.devices),
            const SizedBox(width: 8),
            StatCard(label: 'Available', value: '${stats['available'] ?? 0}', color: Colors.green, icon: Icons.check_circle_outline),
            const SizedBox(width: 8),
            StatCard(label: 'Dipinjam', value: '${stats['borrowed'] ?? 0}', color: Colors.orange, icon: Icons.pending_outlined),
            const SizedBox(width: 8),
            StatCard(label: 'Terlambat', value: '${stats['overdue'] ?? 0}', color: Colors.red, icon: Icons.warning_outlined),
          ]),
          const SizedBox(height: 20),
          if ((stats['overdue'] ?? 0) > 0) ...[
            const SectionHeader(title: 'Perlu perhatian ⚠️'),
            const SizedBox(height: 8),
            devicesAsync.when(
              loading: () => const SizedBox(), error: (_, __) => const SizedBox(),
              data: (devices) => Column(children: devices.where((d) => d.isOverdue).map((d) =>
                Padding(padding: const EdgeInsets.only(bottom: 8),
                    child: DeviceCard(device: d, onTap: () => context.push('/device/${d.deviceId}')))).toList()),
            ),
            const SizedBox(height: 16),
          ],
          const SectionHeader(title: 'Aktivitas terbaru'),
          const SizedBox(height: 8),
          logsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox(),
            data: (logs) => Column(children: logs.take(8).map((log) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade100)),
              child: Row(children: [
                CircleAvatar(radius: 16,
                  backgroundColor: log.isPinjam ? Colors.blue.shade100 : Colors.grey.shade200,
                  child: Icon(log.isPinjam ? Icons.login : Icons.logout, size: 14,
                      color: log.isPinjam ? Colors.blue : Colors.grey)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${log.actionType} — ${log.assetId}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(log.userName, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                ])),
                Text(fmt.format(log.timestamp.toDate()),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
              ]),
            )).toList()),
          ),
        ]),
      ),
    );
  }
}
EOF

cat > lib/presentation/screens/admin/devices/admin_devices_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/providers.dart';
import '../../../widgets/device_card.dart';
import '../../../widgets/common/common_widgets.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../data/models/device_model.dart';

class AdminDevicesScreen extends ConsumerWidget {
  const AdminDevicesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(allDevicesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Device')),
      body: devicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(message: e.toString()),
        data: (devices) {
          if (devices.isEmpty) return EmptyState(message: 'Belum ada device', icon: Icons.devices_other,
              actionLabel: 'Tambah Device', onAction: () => _addDialog(context, ref));
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), itemCount: devices.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) => DeviceCard(device: devices[i],
                onTap: () => context.push('/device/${devices[i].deviceId}'),
                onLongPress: () => _optionsSheet(context, ref, devices[i])),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addDialog(context, ref),
        backgroundColor: const Color(0xFF1565C0),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Device', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _addDialog(BuildContext context, WidgetRef ref) {
    final idCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final brandCtrl = TextEditingController();
    String cat = AppConstants.deviceCategories.first;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      title: const Text('Tambah Device Baru'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: idCtrl, decoration: const InputDecoration(labelText: 'Asset ID', hintText: 'MOB-03')),
        const SizedBox(height: 12),
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Device')),
        const SizedBox(height: 12),
        TextField(controller: brandCtrl, decoration: const InputDecoration(labelText: 'Brand')),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(value: cat, decoration: const InputDecoration(labelText: 'Kategori'),
          items: AppConstants.deviceCategories.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
          onChanged: (v) => setS(() => cat = v ?? cat)),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
        FilledButton(onPressed: () async {
          if (idCtrl.text.isEmpty || nameCtrl.text.isEmpty) return;
          await ref.read(deviceRepositoryProvider).addDevice(DeviceModel(
            deviceId: idCtrl.text.trim().toUpperCase(), name: nameCtrl.text.trim(),
            brand: brandCtrl.text.trim(), category: cat, status: AppConstants.statusAvailable,
          ));
          if (ctx.mounted) Navigator.pop(ctx);
        }, child: const Text('Simpan')),
      ],
    )));
  }

  void _optionsSheet(BuildContext context, WidgetRef ref, DeviceModel d) {
    showModalBottomSheet(context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(d.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        ListTile(leading: const Icon(Icons.delete_outline, color: Colors.red),
          title: const Text('Hapus Device', style: TextStyle(color: Colors.red)),
          onTap: () { Navigator.pop(ctx); _deleteDialog(context, ref, d); }),
      ])));
  }

  void _deleteDialog(BuildContext context, WidgetRef ref, DeviceModel d) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Hapus Device'),
      content: Text('Hapus ${d.name} (${d.deviceId})?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async { await ref.read(deviceRepositoryProvider).deleteDevice(d.deviceId); if (ctx.mounted) Navigator.pop(ctx); },
          child: const Text('Hapus')),
      ],
    ));
  }
}
EOF

cat > lib/presentation/screens/admin/users/admin_users_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../providers/providers.dart';
import '../../../widgets/common/common_widgets.dart';

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allowedUsersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Akses User')),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(message: e.toString()),
        data: (users) {
          if (users.isEmpty) return EmptyState(message: 'Belum ada user', icon: Icons.people_outline,
              actionLabel: 'Tambah User', onAction: () => _addDialog(context, ref));
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final u = users[i];
              final email = u['email'] ?? ''; final name = u['name'] ?? '';
              final isActive = u['is_active'] == true;
              return Card(child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isActive ? Colors.green.shade100 : Colors.grey.shade200,
                  child: Text((name.isNotEmpty ? name : email)[0].toUpperCase(),
                      style: TextStyle(color: isActive ? Colors.green.shade800 : Colors.grey, fontWeight: FontWeight.bold))),
                title: Text(name.isNotEmpty ? name : email, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text(email, style: const TextStyle(fontSize: 12)),
                trailing: Switch(value: isActive,
                    onChanged: (val) => ref.read(userRepositoryProvider).setUserActive(email, val)),
                onLongPress: () => _removeDialog(context, ref, email),
              ));
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addDialog(context, ref),
        backgroundColor: const Color(0xFF1565C0),
        icon: const Icon(Icons.person_add_outlined, color: Colors.white),
        label: const Text('Tambah User', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _addDialog(BuildContext context, WidgetRef ref) {
    final emailCtrl = TextEditingController(); final nameCtrl = TextEditingController();
    final me = FirebaseAuth.instance.currentUser;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Tambah User'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email Google', hintText: 'user@gmail.com')),
        const SizedBox(height: 12),
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Lengkap')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
        FilledButton(onPressed: () async {
          if (emailCtrl.text.trim().isEmpty) return;
          await ref.read(userRepositoryProvider).addAllowedUser(
            email: emailCtrl.text, name: nameCtrl.text, addedByName: me?.displayName ?? 'Admin');
          if (ctx.mounted) Navigator.pop(ctx);
        }, child: const Text('Tambahkan')),
      ],
    ));
  }

  void _removeDialog(BuildContext context, WidgetRef ref, String email) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Hapus Akses'),
      content: Text('Hapus akses untuk $email?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async { await ref.read(userRepositoryProvider).removeAllowedUser(email); if (ctx.mounted) Navigator.pop(ctx); },
          child: const Text('Hapus')),
      ],
    ));
  }
}
EOF

cat > lib/presentation/screens/admin/stats/admin_stats_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/providers.dart';
import '../../../widgets/common/common_widgets.dart';

class AdminStatsScreen extends ConsumerWidget {
  const AdminStatsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(deviceStatsProvider);
    final logsAsync = ref.watch(allLogsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Statistik')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          StatCard(label: 'Total Device', value: '${stats['total'] ?? 0}', color: const Color(0xFF1565C0), icon: Icons.devices),
          const SizedBox(width: 10),
          StatCard(label: 'Available', value: '${stats['available'] ?? 0}', color: Colors.green, icon: Icons.check_circle_outline),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          StatCard(label: 'Dipinjam', value: '${stats['borrowed'] ?? 0}', color: Colors.orange, icon: Icons.pending_outlined),
          const SizedBox(width: 10),
          StatCard(label: 'Terlambat', value: '${stats['overdue'] ?? 0}', color: Colors.red, icon: Icons.warning_outlined),
        ]),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Total aktivitas log'),
        const SizedBox(height: 10),
        logsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorState(message: e.toString()),
          data: (logs) => Row(children: [
            StatCard(label: 'Total Pinjam', value: '${logs.where((l) => l.isPinjam).length}', color: Colors.blue, icon: Icons.login),
            const SizedBox(width: 10),
            StatCard(label: 'Total Kembali', value: '${logs.where((l) => !l.isPinjam).length}', color: Colors.teal, icon: Icons.logout),
          ]),
        ),
      ]),
    );
  }
}
EOF

# ══════════════════════════════════════════════════════════════
# SCREENS — SHARED
# ══════════════════════════════════════════════════════════════

cat > lib/presentation/screens/shared/profile/profile_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(currentUserModelProvider).when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const Scaffold(body: Center(child: Text('Gagal memuat profil'))),
      data: (user) {
        if (user == null) return const Scaffold(body: SizedBox());
        return Scaffold(
          appBar: AppBar(title: const Text('Profil')),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            Center(child: Column(children: [
              CircleAvatar(radius: 44, backgroundColor: const Color(0xFF1565C0),
                backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
                child: user.photoUrl.isEmpty ? Text(user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)) : null),
              const SizedBox(height: 14),
              Text(user.displayName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(user.email, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: user.isAdmin ? Colors.purple.shade100 : Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(20)),
                child: Text(user.isAdmin ? 'Admin' : 'Member',
                    style: TextStyle(color: user.isAdmin ? Colors.purple.shade800 : Colors.blue.shade800,
                        fontWeight: FontWeight.w600, fontSize: 12))),
            ])),
            const SizedBox(height: 28),
            Card(child: Column(children: [
              ListTile(leading: Icon(Icons.email_outlined, color: Colors.grey.shade600, size: 20),
                title: Text('Email', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                subtitle: Text(user.email, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
              const Divider(height: 1, indent: 56),
              ListTile(leading: Icon(Icons.manage_accounts_outlined, color: Colors.grey.shade600, size: 20),
                title: Text('Role', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                subtitle: Text(user.role.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
            ])),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red),
                  minimumSize: const Size.fromHeight(50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () => showDialog(context: context, builder: (ctx) => AlertDialog(
                title: const Text('Keluar'), content: const Text('Yakin ingin keluar dari DevTrack?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                  FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () async { Navigator.pop(ctx); await ref.read(authServiceProvider).signOut(); if (context.mounted) context.go('/login'); },
                    child: const Text('Keluar')),
                ],
              )),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Keluar dari DevTrack', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 16),
            Center(child: Text('DevTrack v1.0.0', style: TextStyle(color: Colors.grey.shade400, fontSize: 11))),
          ]),
        );
      },
    );
  }
}
EOF

# ══════════════════════════════════════════════════════════════
# CORE — ROUTER & MAIN
# ══════════════════════════════════════════════════════════════

cat > lib/core/router.dart << 'EOF'
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../presentation/providers/providers.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/home_shell.dart';
import '../presentation/screens/member/detail/device_detail_screen.dart';
import '../presentation/screens/member/scanner/scanner_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final loggedIn = authState.valueOrNull != null;
      final onLogin = state.matchedLocation == '/login';
      if (!loggedIn && !onLogin) return '/login';
      if (loggedIn && onLogin) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/home', builder: (c, s) => const HomeShell()),
      GoRoute(path: '/scanner', builder: (c, s) => const ScannerScreen()),
      GoRoute(path: '/device/:id',
          builder: (c, s) => DeviceDetailScreen(deviceId: s.pathParameters['id']!)),
    ],
  );
});
EOF

cat > lib/main.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router.dart';
import 'data/services/seed_service.dart';
import 'presentation/providers/providers.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: DevTrackApp()));
}

class DevTrackApp extends ConsumerWidget {
  const DevTrackApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    ref.listen<AsyncValue<dynamic>>(authStateProvider, (_, next) {
      if (next.valueOrNull != null) SeedService.seedDevices();
    });
    return MaterialApp.router(
      title: 'DevTrack',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
EOF

echo ""
echo "✅ Semua file berhasil dibuat!"
echo ""
echo "Langkah selanjutnya:"
echo "1. Pastikan pubspec.yaml sudah ada dependency: intl: ^0.19.0"
echo "2. Jalankan: flutter pub get && flutter run"
