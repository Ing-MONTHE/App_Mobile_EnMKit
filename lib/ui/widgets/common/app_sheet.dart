import 'package:flutter/material.dart';
import 'package:enmkit/ui/theme/app_theme.dart';

/// Affiche un bottom sheet convivial et arrondi, avec poignée, en-tête iconique
/// (pastille colorée), titre, sous-titre amical et contenu. Gère le clavier.
///
/// Remplace les AlertDialog secs par une expérience moderne « qui parle ».
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required IconData icon,
  required String title,
  String? subtitle,
  Color accent = AppTheme.indigo,
  required Widget Function(BuildContext) builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
      return AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          decoration: BoxDecoration(
            // Voile d'accent très doux en haut → rendu plus chaleureux.
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.alphaBlend(
                  accent.withValues(alpha: isDark ? 0.14 : 0.07),
                  isDark ? const Color(0xFF1E2038) : Colors.white,
                ),
                isDark ? const Color(0xFF1E2038) : Colors.white,
              ],
              stops: const [0.0, 0.32],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
          ),
          child: SafeArea(
            top: false,
            // Contenu défilable : quand le clavier est ouvert, la feuille se
            // réduit sans déborder (l'utilisateur peut faire défiler).
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poignée.
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(ctx)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // En-tête iconique centré (plus doux).
                  Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: isDark ? 0.22 : 0.14),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(icon, color: accent, size: 27),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(ctx)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                          fontSize: 13.5,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  builder(ctx),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Champ de saisie stylé pour les sheets (label au-dessus, fond doux).
class SheetField extends StatelessWidget {
  const SheetField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 7),
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          autofocus: autofocus,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null ? Icon(icon) : null,
          ),
        ),
      ],
    );
  }
}
