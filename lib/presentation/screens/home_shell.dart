import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import 'admin/dashboard/admin_dashboard_screen.dart';
import 'admin/devices/admin_devices_screen.dart';
import 'admin/users/admin_users_screen.dart';
import 'admin/stats/admin_stats_screen.dart';
import 'member/dashboard/member_dashboard_screen.dart';
import 'member/scanner/scanner_screen.dart';
import 'member/history/history_screen.dart';
import 'shared/profile/profile_screen.dart';

// Ganti ini untuk test: 'admin' atau 'member'
const String kTestRole = 'admin';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});
  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _idx = 0;

  @override
  Widget build(BuildContext context) {
    final isAdmin = kTestRole == 'admin';

    final screens = isAdmin
        ? [
            const AdminDashboardScreen(),
            const AdminDevicesScreen(),
            const AdminUsersScreen(),
            const AdminStatsScreen(),
            const ProfileScreen(),
          ]
        : [
            const MemberDashboardScreen(),
            const ScannerScreen(),
            const HistoryScreen(),
            const ProfileScreen(),
          ];

    final items = isAdmin
        ? const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.devices_outlined),
              activeIcon: Icon(Icons.devices),
              label: 'Device',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Users',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Statistik',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ]
        : const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner_outlined),
              activeIcon: Icon(Icons.qr_code_scanner),
              label: 'Scan QR',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: 'Riwayat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ];

    final safeIdx = _idx.clamp(0, screens.length - 1);

    return Scaffold(
      body: IndexedStack(index: safeIdx, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: safeIdx,
        onTap: (i) => setState(() => _idx = i),
        items: items,
      ),
    );
  }
}