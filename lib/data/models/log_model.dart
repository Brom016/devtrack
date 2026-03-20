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
