import 'dart:ui';

import 'package:enmkit/providers.dart';
import 'package:enmkit/ui/screens/education/education_screen.dart';
import 'package:enmkit/ui/screens/kits/kits_list_screen.dart';
import 'package:enmkit/ui/screens/settings/settings_screen.dart';
import 'package:enmkit/ui/screens/support/support_screen.dart';
import 'package:enmkit/ui/theme/app_theme.dart';
import 'package:enmkit/ui/widgets/common/doodle_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Coquille principale après déverrouillage : fond doodle commun + barre de
/// navigation basse en icônes (Accueil / Apprendre / Aide / Réglages).
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  /// Index de l'onglet Aide : ouvrir cet onglet vaut consultation du fil.
  static const int _helpIndex = 2;
  int _index = 0;

  static const _pages = [
    _PageHost(child: KitsListScreen()),
    _PageHost(child: EducationScreen()),
    _PageHost(child: SupportScreen()),
    _PageHost(child: SettingsScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: DoodleBackground(
        child: SafeArea(
          bottom: false,
          child: IndexedStack(index: _index, children: _pages),
        ),
      ),
      bottomNavigationBar: _BottomBar(
        index: _index,
        helpIndex: _helpIndex,
        unread: ref.watch(supportProvider).unread,
        onTap: (i) {
          setState(() => _index = i);
          // Ouvrir l'Aide éteint la pastille : le fil est réputé lu.
          if (i == _helpIndex) ref.read(supportProvider).markSeen();
        },
      ),
    );
  }
}

/// Hôte de page : laisse le fond doodle du shell transparaître.
class _PageHost extends StatelessWidget {
  const _PageHost({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// Barre basse flottante, icônes seules.
///
/// Une capsule translucide et floutée flotte au-dessus du contenu ; une bulle
/// teintée glisse d'un onglet à l'autre sous l'icône active (pleine, colorée et
/// soulignée d'un point). Le libellé n'est pas affiché mais reste annoncé par
/// les lecteurs d'écran et visible en appui long (infobulle).
class _BottomBar extends ConsumerWidget {
  const _BottomBar({
    required this.index,
    required this.onTap,
    required this.helpIndex,
    this.unread = 0,
  });
  final int index;

  /// Position de l'onglet Aide (porteur de la pastille de non-lu).
  final int helpIndex;
  final ValueChanged<int> onTap;

  /// Réponses du support non lues : pastille discrète sur l'onglet Aide.
  final int unread;

  static const double _height = 64;
  static const double _bubbleW = 56;
  static const double _bubbleH = 46;
  static const Duration _slide = Duration(milliseconds: 420);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    final items = <(IconData, IconData, String)>[
      (Icons.home_rounded, Icons.home_outlined, t.t('nav.home')),
      (
        Icons.auto_stories_rounded,
        Icons.auto_stories_outlined,
        t.t('nav.learn'),
      ),
      (Icons.forum_rounded, Icons.forum_outlined, t.t('nav.help')),
      (Icons.tune_rounded, Icons.tune_outlined, t.t('nav.settings')),
    ];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final surface = isDark ? const Color(0xFF1E2038) : Colors.white;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: DecoratedBox(
          // L'ombre est posée hors du ClipRRect, sinon le flou la couperait.
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_height / 2),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: isDark ? 0.14 : 0.10),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_height / 2),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: _height,
                decoration: BoxDecoration(
                  color: surface.withValues(alpha: isDark ? 0.78 : 0.86),
                  borderRadius: BorderRadius.circular(_height / 2),
                  border: Border.all(
                    color:
                        isDark
                            ? Colors.white.withValues(alpha: 0.07)
                            : Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, box) {
                    final slot = box.maxWidth / items.length;
                    return Stack(
                      children: [
                        // Bulle de l'onglet actif : elle glisse (léger rebond)
                        // au lieu d'apparaître, ce qui rend le changement lisible.
                        AnimatedPositioned(
                          duration: _slide,
                          curve: Curves.easeOutBack,
                          left: slot * index + (slot - _bubbleW) / 2,
                          top: (_height - _bubbleH) / 2 - 1,
                          width: _bubbleW,
                          height: _bubbleH,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  scheme.primary.withValues(
                                    alpha: isDark ? 0.30 : 0.16,
                                  ),
                                  scheme.primary.withValues(
                                    alpha: isDark ? 0.14 : 0.06,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Row(
                          children: List.generate(items.length, (i) {
                            return Expanded(
                              child: _NavIcon(
                                filled: items[i].$1,
                                outlined: items[i].$2,
                                label: items[i].$3,
                                selected: index == i,
                                badge:
                                    i == helpIndex && unread > 0 && index != i,
                                badgeBorder: surface,
                                onTap: () {
                                  if (index != i) {
                                    HapticFeedback.selectionClick();
                                  }
                                  onTap(i);
                                },
                              ),
                            );
                          }),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Icône d'onglet : pleine et colorée quand active (avec un point dessous),
/// en contour et atténuée au repos. La différence se lit donc même sans couleur.
class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.filled,
    required this.outlined,
    required this.label,
    required this.selected,
    required this.badge,
    required this.badgeBorder,
    required this.onTap,
  });

  final IconData filled;
  final IconData outlined;
  final String label;
  final bool selected;
  final bool badge;
  final Color badgeBorder;
  final VoidCallback onTap;

  static const Duration _d = Duration(milliseconds: 300);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // En thème sombre, l'accent est éclairci pour rester lisible sur la bulle.
    final accent =
        Theme.of(context).brightness == Brightness.dark
            ? Color.lerp(scheme.primary, Colors.white, 0.35)!
            : scheme.primary;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        triggerMode: TooltipTriggerMode.longPress,
        child: InkResponse(
          onTap: onTap,
          radius: 30,
          highlightColor: Colors.transparent,
          splashColor: scheme.primary.withValues(alpha: 0.10),
          child: SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: selected ? 1.08 : 1.0,
                  duration: _d,
                  curve: Curves.easeOutBack,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedSwitcher(
                        duration: _d,
                        transitionBuilder:
                            (c, a) => FadeTransition(opacity: a, child: c),
                        child: Icon(
                          selected ? filled : outlined,
                          key: ValueKey(selected),
                          size: 25,
                          color:
                              selected
                                  ? scheme.primary
                                  : scheme.onSurfaceVariant.withValues(
                                    alpha: 0.62,
                                  ),
                        ),
                      ),
                      // Pastille de non-lu : une réponse du support arrivée en
                      // arrière-plan serait sinon totalement invisible.
                      if (badge)
                        Positioned(
                          right: -2,
                          top: -1,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppTheme.coral,
                              shape: BoxShape.circle,
                              border: Border.all(color: badgeBorder, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: _d,
                  curve: Curves.easeOutCubic,
                  width: selected ? 5 : 0,
                  height: 5,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

