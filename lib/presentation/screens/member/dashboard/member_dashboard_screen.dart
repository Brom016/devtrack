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
