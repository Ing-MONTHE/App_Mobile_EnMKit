import 'package:flutter/material.dart';

/// Fond global de l'app : motif doodle de la marque (texture) + grand logo
/// EnMKit en filigrane, pour une immersion de marque. Un voile dégradé garde
/// le contenu lisible par-dessus.
class DoodleBackground extends StatelessWidget {
  const DoodleBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        // Base.
        Positioned.fill(child: ColoredBox(color: scheme.surface)),

        // Motif doodle répété (texture de marque, plus présent).
        Positioned.fill(
          child: Opacity(
            opacity: isDark ? 0.12 : 0.42,
            child: Image.asset(
              'asset/images/doodle_pattern.jpg',
              repeat: ImageRepeat.repeat,
              colorBlendMode: isDark ? BlendMode.screen : null,
              color: isDark ? Colors.white24 : null,
            ),
          ),
        ),

        // Grand logo EnMKit en filigrane immersif (centré, très discret).
        Positioned.fill(
          child: IgnorePointer(
            child: Center(
              child: FractionallySizedBox(
                widthFactor: 0.92,
                child: Opacity(
                  opacity: isDark ? 0.05 : 0.07,
                  child: Image.asset(
                    'asset/images/logo.png',
                    fit: BoxFit.contain,
                    color: isDark ? Colors.white : null,
                    colorBlendMode: isDark ? BlendMode.srcIn : null,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Voile dégradé : éclaircit le centre pour la lisibilité,
        // touche d'accent en haut.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  scheme.primary.withValues(alpha: isDark ? 0.10 : 0.06),
                  scheme.surface.withValues(alpha: isDark ? 0.42 : 0.50),
                  scheme.surface.withValues(alpha: isDark ? 0.38 : 0.42),
                ],
              ),
            ),
          ),
        ),

        child,
      ],
    );
  }
}

/// Scaffold appliquant le fond doodle automatiquement.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.extendBodyBehindAppBar = true,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final bool extendBodyBehindAppBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      body: DoodleBackground(child: body),
    );
  }
}
