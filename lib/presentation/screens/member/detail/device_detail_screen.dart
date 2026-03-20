import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../providers/providers.dart';
import '../../../widgets/common/common_widgets.dart';

class DeviceDetailScreen extends ConsumerStatefulWidget {
  final String deviceId;
  const DeviceDetailScreen({super.key, required this.deviceId});
  @override
  ConsumerState<DeviceDetailScreen> createState() => _State();
}

class _State extends ConsumerState<DeviceDetailScreen> {
  final _durasiCtrl = TextEditingController(text: '1');
  final _catatanCtrl = TextEditingController();
  bool _isLoading = false;
  String _kondisi = 'OK';

  @override
  void dispose() {
    _durasiCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg, Color color) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
        ),
      );

  Future<void> _pinjam(String id) async {
    final durasi = int.tryParse(_durasiCtrl.text) ?? 1;
    if (durasi < 1) {
      _snack('Durasi minimal 1 hari', Colors.red);
      return;
    }

    final firebaseUser = FirebaseAuth.instance.currentUser!;
    // Ambil nama dari Firestore, bukan dari Firebase Auth
    final userModel = ref.read(currentUserModelProvider).valueOrNull;
    final userName =
        userModel?.displayName ??
        firebaseUser.email?.split('@').first ??
        'Unknown';

    setState(() => _isLoading = true);
    try {
      await ref
          .read(deviceRepositoryProvider)
          .borrowDevice(
            deviceId: id,
            userId: firebaseUser.uid,
            userName: userName,
            estimatedDays: durasi,
          );
      if (mounted) {
        _snack('Device berhasil dipinjam!', Colors.green);
        context.go('/home');
      }
    } catch (e) {
      if (mounted) _snack('Gagal: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _kembalikan(String id) async {
    final firebaseUser = FirebaseAuth.instance.currentUser!;
    final userModel = ref.read(currentUserModelProvider).valueOrNull;
    final userName =
        userModel?.displayName ??
        firebaseUser.email?.split('@').first ??
        'Unknown';

    final note =
        '$_kondisi${_catatanCtrl.text.isNotEmpty ? ' - ${_catatanCtrl.text}' : ''}';
    setState(() => _isLoading = true);
    try {
      await ref
          .read(deviceRepositoryProvider)
          .returnDevice(
            deviceId: id,
            userId: firebaseUser.uid,
            userName: userName,
            conditionNote: note,
          );
      if (mounted) {
        _snack('Device berhasil dikembalikan!', Colors.green);
        context.go('/home');
      }
    } catch (e) {
      if (mounted) _snack('Gagal: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceAsync = ref.watch(deviceByIdProvider(widget.deviceId));
    final logsAsync = ref.watch(deviceLogsProvider(widget.deviceId));
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final fmt = DateFormat('dd MMM yyyy, HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Device'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: deviceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(message: e.toString()),
        data: (device) {
          if (device == null)
            return const Center(
              child: Text('Device tidak ditemukan.\nPastikan QR code valid.'),
            );
          final isAvail = device.isAvailable;
          final isMe = device.currentHolderId == uid;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    device.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    device.deviceId,
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            StatusBadge(
                              status: device.status,
                              isOverdue: device.isOverdue,
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        InfoRow('Brand', device.brand),
                        InfoRow('Kategori', device.category),
                        if (!isAvail) ...[
                          const Divider(height: 16),
                          InfoRow(
                            'Dipinjam oleh',
                            device.currentHolderName ?? '-',
                            valueColor: Colors.orange.shade700,
                          ),
                          if (device.borrowedAt != null)
                            InfoRow(
                              'Sejak',
                              fmt.format(device.borrowedAt!.toDate()),
                            ),
                          if (device.estimatedDurationDays != null)
                            InfoRow(
                              'Est. kembali',
                              fmt.format(
                                device.borrowedAt!.toDate().add(
                                  Duration(days: device.estimatedDurationDays!),
                                ),
                              ),
                              valueColor: device.isOverdue ? Colors.red : null,
                            ),
                        ],
                        if (device.qrCodeUrl.isNotEmpty &&
                            device.qrCodeUrl.startsWith('http')) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              device.qrCodeUrl,
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (isAvail) _pinjamCard(device.deviceId),
                if (!isAvail && isMe) _kembalikanCard(device.deviceId),
                if (!isAvail && !isMe)
                  _kontakCard(device.currentHolderName ?? 'peminjam'),
                const SizedBox(height: 24),
                const Text(
                  'Riwayat device ini',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 10),
                logsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox(),
                  data: (logs) {
                    if (logs.isEmpty)
                      return Text(
                        'Belum ada riwayat',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                        ),
                      );
                    return Column(
                      children: logs
                          .map(
                            (log) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: log.isPinjam
                                    ? Colors.blue.shade50
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: log.isPinjam
                                      ? Colors.blue.shade100
                                      : Colors.grey.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    log.isPinjam
                                        ? Icons.login_rounded
                                        : Icons.logout_rounded,
                                    color: log.isPinjam
                                        ? Colors.blue
                                        : Colors.grey,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${log.actionType} oleh ${log.userName}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        if (log.conditionNote != null &&
                                            log.conditionNote!.isNotEmpty)
                                          Text(
                                            log.conditionNote!,
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 11,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    fmt.format(log.timestamp.toDate()),
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _pinjamCard(String id) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pinjam device ini',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _durasiCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Estimasi durasi',
              suffixText: 'hari',
              prefixIcon: Icon(Icons.calendar_today_outlined),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isLoading ? null : () => _pinjam(id),
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.handshake_outlined),
              label: const Text('Pinjam Sekarang'),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _kembalikanCard(String id) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kembalikan device',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 12),
          const Text(
            'Kondisi saat dikembalikan:',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'OK',
                label: Text('Kondisi OK'),
                icon: Icon(Icons.check_circle_outline),
              ),
              ButtonSegment(
                value: 'Rusak',
                label: Text('Rusak'),
                icon: Icon(Icons.warning_amber_outlined),
              ),
            ],
            selected: {_kondisi},
            onSelectionChanged: (v) => setState(() => _kondisi = v.first),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _catatanCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Catatan tambahan (opsional)',
              hintText: 'Contoh: Baterai 80%, layar normal',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: _isLoading ? null : () => _kembalikan(id),
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.assignment_return_outlined),
              label: const Text('Kembalikan Device'),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _kontakCard(String name) => Card(
    color: Colors.orange.shade50,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: Colors.orange.shade200),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            Icons.person_search_outlined,
            color: Colors.orange.shade700,
            size: 36,
          ),
          const SizedBox(height: 8),
          Text(
            'Sedang dipakai oleh $name',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Hubungi peminjam untuk info lebih lanjut',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.orange.shade600, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.chat_outlined, size: 18),
                  label: const Text('WhatsApp'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.message_outlined, size: 18),
                  label: const Text('Slack'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
