import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../presentation/screens/home_shell.dart';
import '../presentation/screens/member/detail/device_detail_screen.dart';
import '../presentation/screens/member/scanner/scanner_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/home', builder: (c, s) => const HomeShell()),
      GoRoute(path: '/scanner', builder: (c, s) => const ScannerScreen()),
      GoRoute(
        path: '/device/:id',
        builder: (c, s) => DeviceDetailScreen(
          deviceId: s.pathParameters['id']!,
        ),
      ),
    ],
  );
});