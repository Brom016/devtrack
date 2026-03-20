import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/log_model.dart';

class LogHistoryScreen extends StatelessWidget {
  const LogHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Aktivitas')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('logs')
            .orderBy('timestamp', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Belum ada aktivitas'),
                ],
              ),
            );
          }

          final logs = snap.data!.docs
              .map((d) => LogModel.fromFirestore(d))
              .toList();

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final log = logs[i];
              final isPinjam = log.actionType == 'PINJAM';
              final ts = log.timestamp.toDate();
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isPinjam
                      ? Colors.blue.shade100
                      : Colors.grey.shade200,
                  child: Icon(
                    isPinjam ? Icons.login : Icons.logout,
                    color: isPinjam
                        ? Colors.blue
                        : Colors.grey.shade700,
                    size: 20,
                  ),
                ),
                title: Text(
                  '${log.actionType} — ${log.assetId}',
                  style:
                      const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(log.userName),
                trailing: Text(
                  '${ts.day}/${ts.month} ${ts.hour}:${ts.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade600),
                ),
              );
            },
          );
        },
      ),
    );
  }
}