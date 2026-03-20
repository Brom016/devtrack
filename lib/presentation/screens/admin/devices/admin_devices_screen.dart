import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/providers.dart';
import '../../../widgets/device_card.dart';
import '../../../widgets/common/common_widgets.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../data/models/device_model.dart';
import '../../../../data/services/image_service.dart';

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
          if (devices.isEmpty) {
            return EmptyState(
              message: 'Belum ada device',
              icon: Icons.devices_other,
              actionLabel: 'Tambah Device',
              onAction: () => _addDialog(context, ref),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: devices.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) => DeviceCard(
              device: devices[i],
              onTap: () =>
                  context.push('/device/${devices[i].deviceId}'),
              onLongPress: () =>
                  _optionsSheet(context, ref, devices[i]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addDialog(context, ref),
        backgroundColor: const Color(0xFF1565C0),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Device',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _addDialog(BuildContext context, WidgetRef ref) {
    final idCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final brandCtrl = TextEditingController();
    String cat = AppConstants.deviceCategories.first;
    File? selectedImage;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Tambah Device Baru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Image Picker ──────────────────
                GestureDetector(
                  onTap: () => _showImageSource(ctx, (file) {
                    setS(() => selectedImage = file);
                  }),
                  child: Container(
                    width: double.infinity,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              selectedImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined,
                                  size: 40,
                                  color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text(
                                'Tap untuk tambah foto',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                'Kamera atau Galeri',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Form fields ───────────────────
                TextField(
                  controller: idCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Asset ID *',
                    hintText: 'MOB-03',
                    prefixIcon: Icon(Icons.qr_code),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Device *',
                    hintText: 'iPhone 15 Pro',
                    prefixIcon: Icon(Icons.devices),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: brandCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Brand',
                    hintText: 'Apple',
                    prefixIcon: Icon(Icons.business),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: cat,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: AppConstants.deviceCategories
                      .map((k) => DropdownMenuItem(
                          value: k, child: Text(k)))
                      .toList(),
                  onChanged: (v) => setS(() => cat = v ?? cat),
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
              onPressed: isUploading
                  ? null
                  : () async {
                      if (idCtrl.text.isEmpty ||
                          nameCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Asset ID dan Nama wajib diisi')),
                        );
                        return;
                      }

                      setS(() => isUploading = true);

                      final deviceId =
                          idCtrl.text.trim().toUpperCase();
                      String imageUrl = '';

                      // Upload gambar jika ada
                     // Konversi ke base64
if (selectedImage != null) {
  imageUrl = await ImageService.fileToBase64(selectedImage!);
}

                      await ref
                          .read(deviceRepositoryProvider)
                          .addDevice(
                            DeviceModel(
                              deviceId: deviceId,
                              name: nameCtrl.text.trim(),
                              brand: brandCtrl.text.trim(),
                              category: cat,
                              status: AppConstants.statusAvailable,
                              qrCodeUrl: imageUrl,
                            ),
                          );

                      setS(() => isUploading = false);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
              child: isUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSource(
      BuildContext context, Function(File) onPicked) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pilih Sumber Foto',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.camera_alt_outlined,
                    color: Colors.blue.shade700),
              ),
              title: const Text('Kamera'),
              subtitle: const Text('Ambil foto langsung'),
              onTap: () async {
                Navigator.pop(ctx);
                final file =
                    await ImageService.pickImage(fromCamera: true);
                if (file != null) onPicked(file);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.photo_library_outlined,
                    color: Colors.purple.shade700),
              ),
              title: const Text('Galeri'),
              subtitle: const Text('Pilih dari galeri foto'),
              onTap: () async {
                Navigator.pop(ctx);
                final file =
                    await ImageService.pickImage(fromCamera: false);
                if (file != null) onPicked(file);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _optionsSheet(
      BuildContext context, WidgetRef ref, DeviceModel d) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(d.name,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Hapus Device',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _deleteDialog(context, ref, d);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _deleteDialog(
      BuildContext context, WidgetRef ref, DeviceModel d) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Device'),
        content: Text('Hapus ${d.name} (${d.deviceId})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await ref
                  .read(deviceRepositoryProvider)
                  .deleteDevice(d.deviceId);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}