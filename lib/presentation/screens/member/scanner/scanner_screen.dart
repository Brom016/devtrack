import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});
  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool _scanned = false;

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;
    _scanned = true;
    context.push('/device/$raw');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: Colors.white,
          title: const Text('Scan QR Device'), automaticallyImplyLeading: false),
      body: Stack(children: [
        MobileScanner(onDetect: _onDetect),
        Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 240, height: 240,
            decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2.5),
                borderRadius: BorderRadius.circular(16))),
          const SizedBox(height: 24),
          Text('Arahkan ke QR Code device', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14)),
        ])),
        if (_scanned) Center(child: ElevatedButton(
            onPressed: () => setState(() => _scanned = false), child: const Text('Scan Ulang'))),
      ]),
    );
  }
}
