import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../providers/providers.dart';
import '../../../widgets/common/common_widgets.dart';

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allowedUsersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Akses User')),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(message: e.toString()),
        data: (users) {
          if (users.isEmpty) return EmptyState(message: 'Belum ada user', icon: Icons.people_outline,
              actionLabel: 'Tambah User', onAction: () => _addDialog(context, ref));
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final u = users[i];
              final email = u['email'] ?? ''; final name = u['name'] ?? '';
              final isActive = u['is_active'] == true;
              return Card(child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isActive ? Colors.green.shade100 : Colors.grey.shade200,
                  child: Text((name.isNotEmpty ? name : email)[0].toUpperCase(),
                      style: TextStyle(color: isActive ? Colors.green.shade800 : Colors.grey, fontWeight: FontWeight.bold))),
                title: Text(name.isNotEmpty ? name : email, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text(email, style: const TextStyle(fontSize: 12)),
                trailing: Switch(value: isActive,
                    onChanged: (val) => ref.read(userRepositoryProvider).setUserActive(email, val)),
                onLongPress: () => _removeDialog(context, ref, email),
              ));
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addDialog(context, ref),
        backgroundColor: const Color(0xFF1565C0),
        icon: const Icon(Icons.person_add_outlined, color: Colors.white),
        label: const Text('Tambah User', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _addDialog(BuildContext context, WidgetRef ref) {
    final emailCtrl = TextEditingController(); final nameCtrl = TextEditingController();
    final me = FirebaseAuth.instance.currentUser;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Tambah User'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email Google', hintText: 'user@gmail.com')),
        const SizedBox(height: 12),
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Lengkap')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
        FilledButton(onPressed: () async {
          if (emailCtrl.text.trim().isEmpty) return;
          await ref.read(userRepositoryProvider).addAllowedUser(
            email: emailCtrl.text, name: nameCtrl.text, addedByName: me?.displayName ?? 'Admin');
          if (ctx.mounted) Navigator.pop(ctx);
        }, child: const Text('Tambahkan')),
      ],
    ));
  }

  void _removeDialog(BuildContext context, WidgetRef ref, String email) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Hapus Akses'),
      content: Text('Hapus akses untuk $email?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async { await ref.read(userRepositoryProvider).removeAllowedUser(email); if (ctx.mounted) Navigator.pop(ctx); },
          child: const Text('Hapus')),
      ],
    ));
  }
}
