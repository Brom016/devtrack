import 'dart:convert';
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
              onAction: () => _openAddDialog(context, ref, devices),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: devices.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) => DeviceCard(
              device: devices[i],
              onTap: () => context.push('/device/${devices[i].deviceId}'),
              onLongPress: () => _optionsSheet(context, ref, devices[i]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final devices = ref.read(allDevicesProvider).valueOrNull ?? [];
          _openAddDialog(context, ref, devices);
        },
        backgroundColor: const Color(0xFF1565C0),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Device', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _openAddDialog(BuildContext context, WidgetRef ref, List<DeviceModel> existingDevices) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DeviceDialog(widgetRef: ref, existingDevices: existingDevices),
    );
  }

  void _openEditDialog(BuildContext context, WidgetRef ref, DeviceModel device) {
    final devices = ref.read(allDevicesProvider).valueOrNull ?? [];
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DeviceDialog(widgetRef: ref, existingDevices: devices, editDevice: device),
    );
  }

  void _optionsSheet(BuildContext context, WidgetRef ref, DeviceModel d) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text(d.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(d.deviceId, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)), child: Icon(Icons.edit_outlined, color: Colors.blue.shade700)),
              title: const Text('Edit Device'),
              subtitle: const Text('Ubah nama, brand, kategori, foto'),
              onTap: () { Navigator.pop(ctx); _openEditDialog(context, ref, d); },
            ),
            const Divider(height: 8),
            ListTile(
              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)), child: Icon(Icons.delete_outline, color: Colors.red.shade700)),
              title: const Text('Hapus Device', style: TextStyle(color: Colors.red)),
              subtitle: const Text('Hapus permanen dari sistem'),
              onTap: () { Navigator.pop(ctx); _deleteDialog(context, ref, d); },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _deleteDialog(BuildContext context, WidgetRef ref, DeviceModel d) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Device'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade400, size: 48),
            const SizedBox(height: 12),
            Text('Hapus ${d.name} (${d.deviceId})?', textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text('Tindakan ini tidak dapat dibatalkan.', style: TextStyle(color: Colors.grey.shade500, fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await ref.read(deviceRepositoryProvider).deleteDevice(d.deviceId);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

class _DeviceDialog extends StatefulWidget {
  final WidgetRef widgetRef;
  final List<DeviceModel> existingDevices;
  final DeviceModel? editDevice;

  const _DeviceDialog({
    required this.widgetRef,
    required this.existingDevices,
    this.editDevice,
  });

  @override
  State<_DeviceDialog> createState() => _DeviceDialogState();
}

class _DeviceDialogState extends State<_DeviceDialog> {
  late final TextEditingController _idCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _brandCtrl;
  late String _category;
  File? _selectedImage;
  String _existingImageUrl = '';
  bool _isLoading = false;

  bool get isEditMode => widget.editDevice != null;

  static const Map<String, String> _categoryPrefix = {
    'Smartphone': 'HP',
    'Tablet': 'TB',
    'Laptop': 'LP',
    'Kamera': 'CAM',
    'Aksesoris': 'ACC',
    'Lainnya': 'DLL',
  };

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _idCtrl = TextEditingController(text: widget.editDevice!.deviceId);
      _nameCtrl = TextEditingController(text: widget.editDevice!.name);
      _brandCtrl = TextEditingController(text: widget.editDevice!.brand);
      _category = widget.editDevice!.category;
      _existingImageUrl = widget.editDevice!.qrCodeUrl;
    } else {
      _category = AppConstants.deviceCategories.first;
      _idCtrl = TextEditingController(text: _generateId(_category));
      _nameCtrl = TextEditingController();
      _brandCtrl = TextEditingController();
    }
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    super.dispose();
  }

  String _generateId(String category) {
    final prefix = _categoryPrefix[category] ?? 'DLL';
    final existing = widget.existingDevices
        .where((d) => d.deviceId.startsWith('$prefix-'))
        .map((d) {
          final parts = d.deviceId.split('-');
          return parts.length == 2 ? (int.tryParse(parts[1]) ?? 0) : 0;
        })
        .toList();
    final next = existing.isEmpty ? 1 : existing.reduce((a, b) => a > b ? a : b) + 1;
    return '$prefix-${next.toString().padLeft(3, '0')}';
  }

  void _onCategoryChanged(String newCat) {
    setState(() {
      _category = newCat;
      if (!isEditMode) _idCtrl.text = _generateId(newCat);
    });
  }

  Future<void> _pickImage({required bool fromCamera}) async {
    final file = await ImageService.pickImage(fromCamera: fromCamera);
    if (file != null && mounted) {
      setState(() { _selectedImage = file; _existingImageUrl = ''; });
    }
  }

  void _showImageSource() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pilih Sumber Foto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)), child: Icon(Icons.camera_alt_outlined, color: Colors.blue.shade700)),
              title: const Text('Kamera'),
              subtitle: const Text('Ambil foto langsung'),
              onTap: () { Navigator.pop(ctx); _pickImage(fromCamera: true); },
            ),
            ListTile(
              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(10)), child: Icon(Icons.photo_library_outlined, color: Colors.purple.shade700)),
              title: const Text('Galeri'),
              subtitle: const Text('Pilih dari galeri foto'),
              onTap: () { Navigator.pop(ctx); _pickImage(fromCamera: false); },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _simpan() async {
    if (_idCtrl.text.trim().isEmpty || _nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Asset ID dan Nama wajib diisi'), behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final deviceId = _idCtrl.text.trim().toUpperCase();
      String imageUrl = _existingImageUrl;
      if (_selectedImage != null) imageUrl = await ImageService.fileToBase64(_selectedImage!);

      if (isEditMode) {
        await widget.widgetRef.read(deviceRepositoryProvider).updateDevice(deviceId, {
          'name': _nameCtrl.text.trim(),
          'brand': _brandCtrl.text.trim(),
          'category': _category,
          'qr_code_url': imageUrl,
        });
      } else {
        await widget.widgetRef.read(deviceRepositoryProvider).addDevice(DeviceModel(
          deviceId: deviceId,
          name: _nameCtrl.text.trim(),
          brand: _brandCtrl.text.trim(),
          category: _category,
          status: AppConstants.statusAvailable,
          qrCodeUrl: imageUrl,
        ));
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
      }
    }
  }

  Widget _buildImagePreview() {
    if (_selectedImage != null) {
      return Stack(children: [
        ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_selectedImage!, width: double.infinity, height: 150, fit: BoxFit.cover)),
        _overlayButtons(),
      ]);
    }
    if (_existingImageUrl.isNotEmpty) {
      try {
        if (_existingImageUrl.startsWith('data:image')) {
          final bytes = base64Decode(_existingImageUrl.split(',').last);
          return Stack(children: [
            ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(bytes, width: double.infinity, height: 150, fit: BoxFit.cover)),
            _overlayButtons(),
          ]);
        } else if (_existingImageUrl.startsWith('http')) {
          return Stack(children: [
            ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(_existingImageUrl, width: double.infinity, height: 150, fit: BoxFit.cover)),
            _overlayButtons(),
          ]);
        }
      } catch (_) {}
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey.shade400),
        const SizedBox(height: 8),
        Text('Tap untuk tambah foto', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        Text('Kamera atau Galeri', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
      ],
    );
  }

  Widget _overlayButtons() {
    return Positioned(
      bottom: 8, right: 8,
      child: Row(children: [
        GestureDetector(
          onTap: _showImageSource,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.edit, color: Colors.white, size: 12),
              SizedBox(width: 4),
              Text('Ganti', style: TextStyle(color: Colors.white, fontSize: 11)),
            ]),
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => setState(() { _selectedImage = null; _existingImageUrl = ''; }),
          child: Container(padding: const EdgeInsets.all(5), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 12)),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isEditMode ? 'Edit Device' : 'Tambah Device Baru', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _isLoading ? null : _showImageSource,
              child: Container(
                width: double.infinity, height: 150,
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                child: _buildImagePreview(),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Kategori', prefixIcon: Icon(Icons.category)),
              items: AppConstants.deviceCategories.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
              onChanged: isEditMode ? null : (v) { if (v != null) _onCategoryChanged(v); },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _idCtrl,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Asset ID',
                prefixIcon: const Icon(Icons.qr_code),
                filled: true,
                fillColor: Colors.grey.shade100,
                suffixIcon: Tooltip(
                  message: isEditMode ? 'ID tidak dapat diubah' : 'ID otomatis berdasarkan kategori',
                  child: Icon(Icons.info_outline, color: Colors.grey.shade400, size: 18),
                ),
              ),
              style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Device *', hintText: 'iPhone 15 Pro', prefixIcon: Icon(Icons.devices)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _brandCtrl,
              decoration: const InputDecoration(labelText: 'Brand', hintText: 'Apple', prefixIcon: Icon(Icons.business)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _simpan,
                icon: _isLoading
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(isEditMode ? Icons.save_outlined : Icons.add),
                label: Text(isEditMode ? 'Simpan Perubahan' : 'Tambah Device', style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
