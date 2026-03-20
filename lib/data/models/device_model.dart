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
