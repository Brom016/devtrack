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
