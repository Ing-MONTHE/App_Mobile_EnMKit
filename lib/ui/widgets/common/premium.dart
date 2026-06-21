import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:enmkit/ui/theme/app_theme.dart';

/// Nombre qui s'anime de 0 à sa valeur (effet "compteur" fintech).
class AnimatedCount extends StatelessWidget {
  const AnimatedCount({
    super.key,
    required this.value,
    this.style,
    this.suffix = '',
    this.fractionDigits = 0,
    this.duration = const Duration(milliseconds: 900),
  });

  final num value;
  final TextStyle? style;
  final String suffix;
  final int fractionDigits;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(
        '${v.toStringAsFixed(fractionDigits)}$suffix',
        style: style,
      ),
    );
  }
}

/// Grande carte "héro" à dégradé, avec halo lumineux interne — le bloc phare
/// fintech (solde, total, mesure clé).
class GradientHeroCard extends StatelessWidget {
  const GradientHeroCard({
    super.key,
    required this.child,
    this.gradient,
    this.tint,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final Gradient? gradient;
  final Color? tint;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final g = gradient ??
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, Color.lerp(primary, Colors.white, 0.26)!],
        );
    return Container(
      decoration: BoxDecoration(
        gradient: g,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        boxShadow: AppTheme.elevedShadow(tint: tint ?? primary, strength: 0.9),
      ),
      child: Stack(
        children: [
          // Halo décoratif discret en haut à droite.
          Positioned(
            top: -24,
            right: -16,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

/// Tuile statistique premium : pastille d'icône en dégradé + valeur animée.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.suffix = '',
  });

  final IconData icon;
  final String label;
  final num value;
  final Color color;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2038) : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        boxShadow: AppTheme.elevedShadow(tint: color, strength: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, Color.lerp(color, Colors.white, 0.3)!],
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: Colors.white, size: 19),
          ),
          const SizedBox(height: 12),
          AnimatedCount(
            value: value,
            suffix: suffix,
            style: GoogleFonts.chakraPetch(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bouton circulaire flottant (icône) avec ombre douce.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({super.key, required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.elevedShadow(strength: 0.6),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: AppTheme.indigo, size: 22),
          ),
        ),
      ),
    );
  }
}
