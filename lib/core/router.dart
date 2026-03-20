import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../presentation/providers/providers.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/home_shell.dart';
import '../presentation/screens/member/detail/device_detail_screen.dart';
import '../presentation/screens/member/scanner/scanner_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final loggedIn = authState.valueOrNull != null;
      final onLogin = state.matchedLocation == '/login';
      if (!loggedIn && !onLogin) return '/login';
      if (loggedIn && onLogin) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
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