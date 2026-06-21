import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:enmkit/ui/widgets/common/app_logo.dart';
import 'package:enmkit/ui/widgets/common/doodle_background.dart';

/// Indicateur de chargement de marque : le logo EnMKit dans un halo qui pulse,
/// entouré d'un anneau de progression. Utilisé pour tous les chargements
/// plein écran, pour une identité visuelle cohérente et premium.
class BrandLoader extends StatefulWidget {
  const BrandLoader({
    super.key,
    this.message,
    this.size = 96,
  });

  final String? message;
  final double size;

  @override
  State<BrandLoader> createState() => _BrandLoaderState();
}

class _BrandLoaderState extends State<BrandLoader>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ring = widget.size + 36;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: ring,
          height: ring,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Anneau de progression tournant.
              AnimatedBuilder(
                animation: _spin,
                builder: (context, _) => Transform.rotate(
                  angle: _spin.value * 2 * math.pi,
                  child: CustomPaint(
                    size: Size(ring, ring),
                    painter: _ArcPainter(
                      color: scheme.primary,
                      track: scheme.primary.withValues(alpha: 0.12),
                    ),
                  ),
                ),
              ),
              // Logo qui respire.
              ScaleTransition(
                scale: Tween<double>(begin: 0.94, end: 1.04).animate(
                  CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
                ),
                child: AppLogo(size: widget.size),
              ),
            ],
          ),
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 22),
          Text(
            widget.message!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({required this.color, required this.track});
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.width / 2 - 3;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = track;
    canvas.drawCircle(center, radius, trackPaint);

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4
      ..shader = SweepGradient(
        colors: [color.withValues(alpha: 0), color],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      math.pi * 1.4,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) =>
      old.color != color || old.track != track;
}

/// Chargement plein écran centré (avec fond de scaffold).
class BrandLoadingScreen extends StatelessWidget {
  const BrandLoadingScreen({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DoodleBackground(
        child: Center(child: BrandLoader(message: message)),
      ),
    );
  }
}
