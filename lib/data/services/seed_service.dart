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
