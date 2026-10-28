import 'dart:ui';

import 'package:enmkit/providers.dart';
import 'package:enmkit/ui/screens/kits/kits_list_screen.dart';
import 'package:enmkit/ui/screens/settings/settings_screen.dart';
import 'package:enmkit/ui/screens/support/support_screen.dart';
import 'package:enmkit/ui/theme/app_theme.dart';
import 'package:enmkit/ui/widgets/common/doodle_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Coquille principale après déverrouillage : fond doodle commun + barre de
/// navigation basse (Accueil / Aide / Réglages).
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  /// Index de l'onglet Aide : ouvrir cet onglet vaut consultation du fil.
  static const int _helpIndex = 1;
  int _index = 0;

  static const _pages = [
    _PageHost(child: KitsListScreen()),
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

/// Barre basse « douce » : surface translucide et floutée qui laisse deviner le
/// motif de fond, et onglet actif posé dessus comme une pastille lumineuse.
///
/// Le flou (et non une surface opaque) est ce qui donne la sensation de
/// profondeur : la barre flotte au-dessus du contenu au lieu de le trancher.
class _BottomBar extends ConsumerWidget {
  const _BottomBar({
    required this.index,
    required this.onTap,
    this.unread = 0,
  });
  final int index;
  final ValueChanged<int> onTap;

  /// Réponses du support non lues : pastille discrète sur l'onglet Aide.
  final int unread;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    final items = <(IconData, IconData, String)>[
      (Icons.home_rounded, Icons.home_outlined, t.t('nav.home')),
      (
        Icons.support_agent_rounded,
        Icons.support_agent_outlined,
        t.t('nav.help')
      ),
      (Icons.settings_rounded, Icons.settings_outlined, t.t('nav.settings')),
    ];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
            decoration: BoxDecoration(
              color: (isDark ? const Color(0xFF1E2038) : Colors.white)
                  .withValues(alpha: isDark ? 0.72 : 0.78),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.6),
              ),
              boxShadow: AppTheme.elevedShadow(strength: 0.7),
            ),
            child: Row(
              children: List.generate(items.length, (i) {
                final sel = index == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        gradient: sel
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  scheme.primary,
                                  Color.lerp(
                                      scheme.primary, Colors.white, 0.28)!,
                                ],
                              )
                            : null,
                        borderRadius: BorderRadius.circular(19),
                        // Halo coloré sous l'onglet actif : c'est lui qui donne
                        // le côté « posé en relief » plutôt que « rempli ».
                        boxShadow: sel
                            ? [
                                BoxShadow(
                                  color:
                                      scheme.primary.withValues(alpha: 0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedScale(
                            scale: sel ? 1.0 : 0.94,
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutCubic,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Icon(
                                  // Plein quand actif, contour au repos : la
                                  // différence se lit même sans la couleur.
                                  sel ? items[i].$1 : items[i].$2,
                                  size: 21,
                                  color: sel
                                      ? Colors.white
                                      : scheme.onSurfaceVariant
                                          .withValues(alpha: 0.9),
                                ),
                                // Pastille de non-lu : une réponse du support
                                // arrivée en arrière-plan serait sinon
                                // totalement invisible.
                                if (i == 1 && unread > 0 && !sel)
                                  Positioned(
                                    right: -3,
                                    top: -2,
                                    child: Container(
                                      width: 9,
                                      height: 9,
                                      decoration: BoxDecoration(
                                        color: AppTheme.coral,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isDark
                                              ? const Color(0xFF1E2038)
                                              : Colors.white,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (sel) ...[
                            const SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                items[i].$3,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
