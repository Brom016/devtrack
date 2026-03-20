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

final currentUserModelProvider = StreamProvider<UserModel?>((ref) {
  // Watch auth state dulu supaya provider rebuild saat user berganti
  ref.watch(authStateProvider);
  return ref.watch(authServiceProvider).watchCurrentUser();
});

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
