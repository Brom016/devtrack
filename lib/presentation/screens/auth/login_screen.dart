import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    try {
      final result = await ref.read(authServiceProvider).signInWithGoogle();
      if (result != null && mounted) context.go('/home');
    } on Exception catch (e) {
      if (mounted) _showError(e.toString().replaceAll('Exception: ', ''));
    } catch (e) {
      if (mounted) _showError('Login gagal. Silakan coba lagi.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 5)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(children: [
            const Spacer(flex: 2),
            Container(
              width: 88, height: 88,
              decoration: BoxDecoration(color: const Color(0xFF1565C0), borderRadius: BorderRadius.circular(24)),
              child: const Icon(Icons.devices_rounded, color: Colors.white, size: 44),
            ),
            const SizedBox(height: 20),
            const Text('DevTrack', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
            const SizedBox(height: 6),
            Text('Asset Management System', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            const Spacer(flex: 2),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text('Hanya akun yang telah didaftarkan admin yang dapat masuk.',
                    style: TextStyle(color: Colors.blue.shade800, fontSize: 12, height: 1.4))),
              ]),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 52,
              child: FilledButton(
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.login_rounded, size: 20),
                        SizedBox(width: 10),
                        Text('Masuk dengan Google', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ]),
              ),
            ),
            const Spacer(),
            Text('DevTrack v1.0.0', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }
}
