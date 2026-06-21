import 'package:flutter/material.dart';
import 'package:enmkit/ui/theme/app_theme.dart';

/// Carte "soft UI" : fond blanc (ou sombre), coins très arrondis, ombre douce
/// et diffuse. Brique de base de toutes les surfaces de l'app.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(18),
    this.color,
    this.shadowTint,
    this.radius = AppTheme.radius,
    this.gradient,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? shadowTint;
  final double radius;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Surface translucide par défaut : le motif de fond transparaît (immersion).
    final bg = color ??
        (isDark ? const Color(0xFF24262E) : Colors.white)
            .withValues(alpha: isDark ? 0.55 : 0.62);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null ? bg : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: gradient == null
            ? Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.07 : 0.55))
            : null,
        boxShadow: AppTheme.softShadow(tint: shadowTint),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Pastille d'icône colorée (accent pastel) — donne du peps aux listes/cartes.
class IconPill extends StatelessWidget {
  const IconPill({
    super.key,
    required this.icon,
    required this.color,
    this.size = 52,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.22),
            color.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.34),
      ),
      child: Icon(icon, color: color, size: size * 0.46),
    );
  }
}

/// Badge de statut arrondi (point + libellé), couleur sémantique.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.filled = false,
  });

  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: filled ? 1 : 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: filled ? Colors.white : color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: filled ? Colors.white : color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
