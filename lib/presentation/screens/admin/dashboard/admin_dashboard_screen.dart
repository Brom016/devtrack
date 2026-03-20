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
