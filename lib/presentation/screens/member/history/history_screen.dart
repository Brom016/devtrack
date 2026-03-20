import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../providers/providers.dart';
import '../../../widgets/common/common_widgets.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(allLogsProvider);
    final fmt = DateFormat('dd MMM yyyy, HH:mm');
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Aktivitas')),
      body: logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(message: e.toString()),
        data: (logs) {
          if (logs.isEmpty) return const EmptyState(message: 'Belum ada aktivitas', icon: Icons.history);
          return ListView.separated(
            padding: const EdgeInsets.all(16), itemCount: logs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final log = logs[i];
              return ListTile(
                leading: CircleAvatar(radius: 20,
                  backgroundColor: log.isPinjam ? Colors.blue.shade100 : Colors.grey.shade200,
                  child: Icon(log.isPinjam ? Icons.login_rounded : Icons.logout_rounded,
                      color: log.isPinjam ? Colors.blue.shade700 : Colors.grey.shade600, size: 18)),
                title: Text('${log.actionType}  —  ${log.assetId}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                subtitle: Text(log.userName, style: const TextStyle(fontSize: 12)),
                trailing: Text(fmt.format(log.timestamp.toDate()),
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500), textAlign: TextAlign.right),
              );
            },
          );
        },
      ),
    );
  }
}
