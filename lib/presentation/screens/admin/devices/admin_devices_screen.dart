import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/providers.dart';
import '../../../widgets/device_card.dart';
import '../../../widgets/common/common_widgets.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../data/models/device_model.dart';

class AdminDevicesScreen extends ConsumerWidget {
  const AdminDevicesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(allDevicesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Device')),
      body: devicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(message: e.toString()),
        data: (devices) {
          if (devices.isEmpty) return EmptyState(message: 'Belum ada device', icon: Icons.devices_other,
              actionLabel: 'Tambah Device', onAction: () => _addDialog(context, ref));
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), itemCount: devices.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) => DeviceCard(device: devices[i],
                onTap: () => context.push('/device/${devices[i].deviceId}'),
                onLongPress: () => _optionsSheet(context, ref, devices[i])),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addDialog(context, ref),
        backgroundColor: const Color(0xFF1565C0),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Device', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _addDialog(BuildContext context, WidgetRef ref) {
    final idCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final brandCtrl = TextEditingController();
    String cat = AppConstants.deviceCategories.first;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      title: const Text('Tambah Device Baru'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: idCtrl, decoration: const InputDecoration(labelText: 'Asset ID', hintText: 'MOB-03')),
        const SizedBox(height: 12),
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Device')),
        const SizedBox(height: 12),
        TextField(controller: brandCtrl, decoration: const InputDecoration(labelText: 'Brand')),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(value: cat, decoration: const InputDecoration(labelText: 'Kategori'),
          items: AppConstants.deviceCategories.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
          onChanged: (v) => setS(() => cat = v ?? cat)),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
        FilledButton(onPressed: () async {
          if (idCtrl.text.isEmpty || nameCtrl.text.isEmpty) return;
          await ref.read(deviceRepositoryProvider).addDevice(DeviceModel(
            deviceId: idCtrl.text.trim().toUpperCase(), name: nameCtrl.text.trim(),
            brand: brandCtrl.text.trim(), category: cat, status: AppConstants.statusAvailable,
          ));
          if (ctx.mounted) Navigator.pop(ctx);
        }, child: const Text('Simpan')),
      ],
    )));
  }

  void _optionsSheet(BuildContext context, WidgetRef ref, DeviceModel d) {
    showModalBottomSheet(context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(d.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        ListTile(leading: const Icon(Icons.delete_outline, color: Colors.red),
          title: const Text('Hapus Device', style: TextStyle(color: Colors.red)),
          onTap: () { Navigator.pop(ctx); _deleteDialog(context, ref, d); }),
      ])));
  }

  void _deleteDialog(BuildContext context, WidgetRef ref, DeviceModel d) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Hapus Device'),
      content: Text('Hapus ${d.name} (${d.deviceId})?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async { await ref.read(deviceRepositoryProvider).deleteDevice(d.deviceId); if (ctx.mounted) Navigator.pop(ctx); },
          child: const Text('Hapus')),
      ],
    ));
  }
}
