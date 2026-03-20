import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/auth_provider.dart';
import '../../providers/device_provider.dart';
import '../../widgets/device_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _filter = 'Semua';
  final _filters = ['Semua', 'Available', 'Borrowed'];

  void _showTambahDeviceDialog() {
    final nameCtrl = TextEditingController();
    final brandCtrl = TextEditingController();
    final idCtrl = TextEditingController();
    String kategori = 'Smartphone';
    final kategoriList = [
      'Smartphone', 'Tablet', 'Laptop', 'Kamera', 'Lainnya'
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Tambah Device Baru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: idCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Asset ID',
                    hintText: 'Contoh: MOB-03',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Device',
                    hintText: 'Contoh: iPhone 15 Pro',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: brandCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Brand',
                    hintText: 'Contoh: Apple',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: kategori,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                  ),
                  items: kategoriList
                      .map((k) => DropdownMenuItem(
                            value: k,
                            child: Text(k),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setStateDialog(() => kategori = v ?? kategori),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                if (idCtrl.text.isEmpty || nameCtrl.text.isEmpty) return;
                await FirebaseFirestore.instance
                    .collection('devices')
                    .doc(idCtrl.text.trim().toUpperCase())
                    .set({
                  'device_id': idCtrl.text.trim().toUpperCase(),
                  'name': nameCtrl.text.trim(),
                  'brand': brandCtrl.text.trim(),
                  'category': kategori,
                  'status': 'available',
                  'qr_code_url': '',
                  'current_holder_id': null,
                  'current_holder_name': null,
                  'created_at': FieldValue.serverTimestamp(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final devicesAsync = ref.watch(allDevicesProvider);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.devices,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'DevTrack',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_outlined),
            tooltip: 'Riwayat',
            onPressed: () => context.push('/logs'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _showLogoutDialog(),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF1565C0),
                backgroundImage: user?.photoURL != null
                    ? NetworkImage(user!.photoURL!)
                    : null,
                child: user?.photoURL == null
                    ? Text(
                        (user?.displayName ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info user
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, ${user?.displayName?.split(' ').first ?? 'User'}! 👋',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Kelola peminjaman device kantor',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Summary cards
          devicesAsync.when(
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
            data: (devices) {
              final available =
                  devices.where((d) => d.isAvailable).length;
              final borrowed = devices.length - available;
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _SummaryCard(
                      label: 'Total Device',
                      value: '${devices.length}',
                      color: const Color(0xFF1565C0),
                      icon: Icons.devices,
                    ),
                    const SizedBox(width: 12),
                    _SummaryCard(
                      label: 'Available',
                      value: '$available',
                      color: Colors.green,
                      icon: Icons.check_circle_outline,
                    ),
                    const SizedBox(width: 12),
                    _SummaryCard(
                      label: 'Dipinjam',
                      value: '$borrowed',
                      color: Colors.orange,
                      icon: Icons.pending_outlined,
                    ),
                  ],
                ),
              );
            },
          ),

          // Filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                const Text(
                  'Daftar Device',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                ..._filters.map((f) {
                  final selected = _filter == f;
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: GestureDetector(
                      onTap: () => setState(() => _filter = f),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF1565C0)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFF1565C0)
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          f,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: selected
                                ? Colors.white
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Device list
          Expanded(
            child: devicesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 8),
                    Text('Error: $e',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              data: (devices) {
                final filtered = _filter == 'Semua'
                    ? devices
                    : devices
                        .where((d) =>
                            d.status.toLowerCase() ==
                            _filter.toLowerCase())
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.devices_other,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada device',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _showTambahDeviceDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Tambah Device'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, i) => DeviceCard(
                    device: filtered[i],
                    onTap: () => context
                        .push('/device/${filtered[i].deviceId}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'add',
            onPressed: _showTambahDeviceDialog,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1565C0),
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'scan',
            onPressed: () => context.push('/scanner'),
            backgroundColor: const Color(0xFF1565C0),
            icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
            label: const Text(
              'Scan QR',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Yakin ingin keluar dari DevTrack?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authServiceProvider).signOut();
              if (mounted) context.go('/login');
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}