import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:enmkit/providers.dart';
import 'package:enmkit/ui/theme/app_theme.dart';

/// Écran de scan d'un QR Code de kit. Retourne (via Navigator.pop) la chaîne
/// JSON brute détectée, que l'appelant passe ensuite à [DatabaseRegenerator].
class ScanKitScreen extends ConsumerStatefulWidget {
  const ScanKitScreen({super.key});

  @override
  ConsumerState<ScanKitScreen> createState() => _ScanKitScreenState();
}

class _ScanKitScreenState extends ConsumerState<ScanKitScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final code = capture.barcodes.isNotEmpty
        ? capture.barcodes.first.rawValue
        : null;
    if (code == null || code.isEmpty) return;
    _handled = true;
    Navigator.pop(context, code);
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(tProvider);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(t.t('scan.title')),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          // Voile sombre pour faire ressortir la fenêtre de visée.
          const ColoredBox(color: Color(0x66000000), child: SizedBox.expand()),
          // Fenêtre de visée stylisée (coins de marque).
          CustomPaint(
            size: const Size(248, 248),
            painter: _ScannerFramePainter(color: AppTheme.mint),
            child: const SizedBox(width: 248, height: 248),
          ),
          Positioned(
            bottom: 56,
            left: 32,
            right: 32,
            child: Column(
              children: [
                const Icon(Icons.qr_code_scanner_rounded,
                    color: Colors.white, size: 28),
                const SizedBox(height: 12),
                Text(
                  t.t('scan.hint'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    shadows: const [Shadow(blurRadius: 8, color: Colors.black)],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dessine un cadre de visée avec des coins arrondis "premium".
class _ScannerFramePainter extends CustomPainter {
  _ScannerFramePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    const corner = 36.0;
    final w = size.width, h = size.height;

    // Haut-gauche
    canvas.drawPath(
      Path()
        ..moveTo(0, corner)
        ..lineTo(0, 0)
        ..lineTo(corner, 0),
      paint,
    );
    // Haut-droite
    canvas.drawPath(
      Path()
        ..moveTo(w - corner, 0)
        ..lineTo(w, 0)
        ..lineTo(w, corner),
      paint,
    );
    // Bas-gauche
    canvas.drawPath(
      Path()
        ..moveTo(0, h - corner)
        ..lineTo(0, h)
        ..lineTo(corner, h),
      paint,
    );
    // Bas-droite
    canvas.drawPath(
      Path()
        ..moveTo(w - corner, h)
        ..lineTo(w, h)
        ..lineTo(w, h - corner),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerFramePainter old) => old.color != color;
}
