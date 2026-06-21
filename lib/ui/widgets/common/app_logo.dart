import 'package:flutter/material.dart';
import 'package:enmkit/ui/theme/app_theme.dart';

/// Logo EnMKit dans une pastille blanche douce et arrondie.
///
/// Le logo source étant sur fond blanc, on le pose toujours sur une surface
/// claire arrondie pour qu'il reste net y compris en thème sombre.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 96,
    this.padding = 18,
    this.elevated = true,
  });

  final double size;
  final double padding;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.32),
        boxShadow: elevated ? AppTheme.softShadow() : null,
      ),
      child: Image.asset('asset/images/logo.png', fit: BoxFit.contain),
    );
  }
}
