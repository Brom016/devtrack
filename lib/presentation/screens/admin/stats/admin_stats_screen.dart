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
