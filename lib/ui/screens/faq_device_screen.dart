import 'package:enmkit/core/i18n/strings.dart';
import 'package:enmkit/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FAQ « Kit et lignes » : ajout, configuration verrouillée, pilotage des
/// lignes, connexion du kit, actions rapides et consommation.
class FaqDeviceScreen extends ConsumerWidget {
  const FaqDeviceScreen({super.key});

  static const _questions = <IconData>[
    Icons.add_circle_outline,
    Icons.tune,
    Icons.lock_outline,
    Icons.power_settings_new,
    Icons.network_check,
    Icons.flash_on_outlined,
    Icons.edit_outlined,
    Icons.bolt,
    Icons.delete_outline,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('faq.home.kit')),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHero(
                context,
                icon: Icons.memory,
                title: t.t('faq.kit.hero'),
                subtitle: t.t('faq.kit.hero.sub'),
              ),
              const SizedBox(height: 24),
              for (var i = 0; i < _questions.length; i++) ...[
                if (i > 0) const SizedBox(height: 16),
                _buildSection(
                  context,
                  t.t('faq.kit.q${i + 1}'),
                  _questions[i],
                  t.t('faq.kit.a${i + 1}').split('\n'),
                ),
              ],
              const SizedBox(height: 28),
              _buildTipCard(context, t),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildHero(BuildContext context,
    {required IconData icon, required String title, required String subtitle}) {
  final scheme = Theme.of(context).colorScheme;
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface)),
              const SizedBox(height: 6),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                      height: 1.4)),
            ],
          ),
        )
      ],
    ),
  );
}

Widget _buildSection(
    BuildContext context, String title, IconData icon, List<String> points) {
  final scheme = Theme.of(context).colorScheme;
  return Container(
    decoration: BoxDecoration(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
    ),
    clipBehavior: Clip.antiAlias,
    child: Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: scheme.primary, size: 22),
        ),
        title: Text(title,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface)),
        children: [
          Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.5)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: points
                  .map((p) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle,
                                color: Color(0xFF10B981), size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(p,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: scheme.onSurfaceVariant,
                                        height: 1.4))),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildTipCard(BuildContext context, AppStrings t) {
  final scheme = Theme.of(context).colorScheme;
  return Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
    ),
    child: Row(
      children: [
        const Icon(Icons.lightbulb, color: Color(0xFFF59E0B)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            t.t('faq.kit.tip'),
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        )
      ],
    ),
  );
}
