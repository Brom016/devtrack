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
  final hasImage = device.qrCodeUrl.isNotEmpty &&
      device.qrCodeUrl.startsWith('http');

  return Card(
    child: InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Gambar atau icon kategori
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: hasImage
                  ? Image.network(
                      device.qrCodeUrl,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _iconBox(isAvail),
                    )
                  : _iconBox(isAvail),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${device.brand} · ${device.category} · ${device.deviceId}',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                    ),
                  ),
                  if (!isAvail && device.currentHolderName != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      'Oleh: ${device.currentHolderName}',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            StatusBadge(
              status: device.status,
              isOverdue: device.isOverdue,
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _iconBox(bool isAvail) {
  return Container(
    width: 52,
    height: 52,
    decoration: BoxDecoration(
      color: isAvail ? Colors.blue.shade50 : Colors.orange.shade50,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(
      _icon,
      color: isAvail ? Colors.blue : Colors.orange,
      size: 24,
    ),
  );
}
}
