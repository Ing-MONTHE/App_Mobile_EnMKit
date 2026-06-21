import 'package:enmkit/providers.dart';
import 'package:enmkit/ui/screens/kits/kits_list_screen.dart';
import 'package:enmkit/ui/screens/settings/settings_screen.dart';
import 'package:enmkit/ui/theme/app_theme.dart';
import 'package:enmkit/ui/widgets/common/doodle_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Coquille principale après déverrouillage : fond doodle commun + barre de
/// navigation basse premium (Accueil / Réglages).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _pages = [
    _PageHost(child: KitsListScreen()),
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
        onTap: (i) => setState(() => _index = i),
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

class _BottomBar extends ConsumerWidget {
  const _BottomBar({required this.index, required this.onTap});
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    final items = [
      (Icons.home_rounded, t.t('nav.home')),
      (Icons.settings_rounded, t.t('nav.settings')),
    ];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2038) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppTheme.elevedShadow(strength: 0.9),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(items.length, (i) {
            final sel = index == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    gradient: sel
                        ? LinearGradient(colors: [
                            scheme.primary,
                            Color.lerp(scheme.primary, Colors.white, 0.26)!
                          ])
                        : null,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        items[i].$1,
                        size: 22,
                        color: sel ? Colors.white : scheme.onSurfaceVariant,
                      ),
                      if (sel) ...[
                        const SizedBox(width: 8),
                        Text(
                          items[i].$2,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
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
    );
  }
}
