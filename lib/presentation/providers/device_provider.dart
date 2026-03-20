import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/device_model.dart';
import '../../data/repositories/device_repository.dart';

final deviceRepositoryProvider = Provider<DeviceRepository>(
  (ref) => DeviceRepository(),
);

final allDevicesProvider = StreamProvider<List<DeviceModel>>((ref) {
  return ref.watch(deviceRepositoryProvider).watchAllDevices();
});

final deviceByIdProvider =
    StreamProvider.family<DeviceModel?, String>((ref, deviceId) {
  return ref.watch(deviceRepositoryProvider).watchDeviceById(deviceId);
});