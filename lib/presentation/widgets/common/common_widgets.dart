import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool isOverdue;
  const StatusBadge({super.key, required this.status, this.isOverdue = false});
  @override
  Widget build(BuildContext context) {
    final isAvail = status == 'available';
    Color bg, fg;
    String label;
    if (isOverdue && !isAvail) { bg = Colors.red.shade100; fg = Colors.red.shade800; label = 'Terlambat'; }
    else if (isAvail) { bg = Colors.green.shade100; fg = Colors.green.shade800; label = 'Available'; }
    else { bg = Colors.orange.shade100; fg = Colors.orange.shade800; label = 'Dipinjam'; }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 11)),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  const EmptyState({super.key, required this.message, this.icon = Icons.inbox_outlined, this.actionLabel, this.onAction});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 64, color: Colors.grey.shade300),
      const SizedBox(height: 12),
      Text(message, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
      if (actionLabel != null && onAction != null) ...[
        const SizedBox(height: 12),
        TextButton.icon(onPressed: onAction, icon: const Icon(Icons.add), label: Text(actionLabel!)),
      ],
    ]),
  );
}

class ErrorState extends StatelessWidget {
  final String message;
  const ErrorState({super.key, required this.message});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(padding: const EdgeInsets.all(24), child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.red),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
      ],
    )),
  );
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionHeader({super.key, required this.title, this.action, this.onAction});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      if (action != null) TextButton(onPressed: onAction, child: Text(action!, style: const TextStyle(fontSize: 13))),
    ],
  );
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const InfoRow(this.label, this.value, {super.key, this.valueColor});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 110, child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13))),
      Expanded(child: Text(value, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: valueColor))),
    ]),
  );
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const StatCard({super.key, required this.label, required this.value, required this.color, required this.icon});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ]),
    ),
  );
}
