import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/device_provider.dart';

class DeviceDetailScreen extends ConsumerStatefulWidget {
  final String deviceId;
  const DeviceDetailScreen({super.key, required this.deviceId});

  @override
  ConsumerState<DeviceDetailScreen> createState() =>
      _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends ConsumerState<DeviceDetailScreen> {
  final _durasiController = TextEditingController(text: '1');
  final _catatanController = TextEditingController();
  bool _isLoading = false;
  String _kondisi = 'OK';

  @override
  void dispose() {
    _durasiController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _pinjam(String deviceId) async {
    final durasi = int.tryParse(_durasiController.text) ?? 1;
    final user = FirebaseAuth.instance.currentUser!;
    setState(() => _isLoading = true);
    try {
      await ref.read(deviceRepositoryProvider).borrowDevice(
            deviceId: deviceId,
            userId: user.uid,
            userName: user.displayName ?? 'Unknown',
            estimatedDays: durasi,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Device berhasil dipinjam!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _kembalikan(String deviceId) async {
    final user = FirebaseAuth.instance.currentUser!;
    final catatan =
        '$_kondisi - ${_catatanController.text}'.trim();
    setState(() => _isLoading = true);
    try {
      await ref.read(deviceRepositoryProvider).returnDevice(
            deviceId: deviceId,
            userId: user.uid,
            userName: user.displayName ?? 'Unknown',
            conditionNote: catatan,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Device berhasil dikembalikan!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceAsync =
        ref.watch(deviceByIdProvider(widget.deviceId));
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Device')),
      body: deviceAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('Device tidak ditemukan: $e')),
        data: (device) {
          if (device == null) {
            return const Center(
                child: Text('Device tidak ditemukan di database'));
          }

          final isAvailable = device.isAvailable;
          final isMyDevice = device.currentHolderId == currentUid;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                device.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                        fontWeight: FontWeight.bold),
                              ),
                            ),
                            _StatusBadge(status: device.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          device.deviceId,
                          style:
                              TextStyle(color: Colors.grey.shade600),
                        ),
                        const Divider(height: 24),
                        _InfoRow('Brand', device.brand),
                        _InfoRow('Kategori', device.category),
                        if (!isAvailable) ...[
                          const Divider(height: 24),
                          _InfoRow('Dipinjam oleh',
                              device.currentHolderName ?? '-'),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Kondisi A: Available
                if (isAvailable) ...[
                  Text('Estimasi durasi (hari)',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _durasiController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Contoh: 3',
                      suffixText: 'hari',
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => _pinjam(device.deviceId),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2),
                          )
                        : const Icon(Icons.handshake),
                    label: const Text('Pinjam Sekarang'),
                  ),

                // Kondisi B2: Borrowed oleh saya
                ] else if (isMyDevice) ...[
                  Text('Catatan kondisi pengembalian',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                          value: 'OK',
                          label: Text('OK'),
                          icon: Icon(Icons.check_circle)),
                      ButtonSegment(
                          value: 'Rusak',
                          label: Text('Rusak'),
                          icon: Icon(Icons.warning)),
                    ],
                    selected: {_kondisi},
                    onSelectionChanged: (v) =>
                        setState(() => _kondisi = v.first),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _catatanController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText:
                          'Tambah catatan kondisi (opsional)...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.orange),
                    onPressed: _isLoading
                        ? null
                        : () => _kembalikan(device.deviceId),
                    icon: const Icon(Icons.assignment_return),
                    label: const Text('Kembalikan Device'),
                  ),

                // Kondisi B1: Borrowed oleh orang lain
                ] else ...[
                  Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.info_outline,
                              color: Colors.orange, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            'Sedang dipakai oleh ${device.currentHolderName ?? "orang lain"}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.chat),
                              label: const Text(
                                  'Hubungi via WhatsApp'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.message),
                              label:
                                  const Text('Hubungi via Slack'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isAvailable = status == 'available';
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isAvailable
            ? Colors.green.shade100
            : Colors.red.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isAvailable ? 'Available' : 'Borrowed',
        style: TextStyle(
          color: isAvailable
              ? Colors.green.shade800
              : Colors.red.shade800,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}