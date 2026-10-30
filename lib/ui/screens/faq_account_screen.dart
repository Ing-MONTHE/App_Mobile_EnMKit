import 'package:enmkit/ui/screens/support/support_screen.dart';
import 'package:enmkit/core/i18n/strings.dart';
import 'package:enmkit/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FAQ « Accès et sécurité » : pas de compte, code d'accès facultatif de
/// 4 chiffres, empreinte, questions de récupération et autorisations.
class FaqAccountScreen extends ConsumerWidget {
  const FaqAccountScreen({super.key});

  static const _questions = <IconData>[
    Icons.person_off_outlined,
    Icons.lock_open_outlined,
    Icons.pin_outlined,
    Icons.edit_outlined,
    Icons.help_outline,
    Icons.fingerprint,
    Icons.verified_user_outlined,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('faq.home.access')),
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
              _buildHeroInfo(context, t),
              const SizedBox(height: 20),
              _buildActionButtons(context, t),
              const SizedBox(height: 24),
              for (var i = 0; i < _questions.length; i++) ...[
                if (i > 0) const SizedBox(height: 16),
                _buildFaqSection(
                  context,
                  t.t('faq.access.q${i + 1}'),
                  _questions[i],
                  t.t('faq.access.a${i + 1}').split('\n'),
                ),
              ],
              const SizedBox(height: 28),
              _buildSupportCard(context, t),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildHeroInfo(BuildContext context, AppStrings t) {
  final scheme = Theme.of(context).colorScheme;
  return Container(
    width: double.infinity,
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
              colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.lock_outline, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.t('faq.access.hero'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                t.t('faq.access.hero.sub'),
                style: TextStyle(
                    fontSize: 12, color: scheme.onSurfaceVariant, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildActionButtons(BuildContext context, AppStrings t) {
  return Row(
    children: [
      Expanded(
        child: SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () {
              // Plus de page de connexion : on revient simplement à l'accueil.
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            icon: const Icon(Icons.home, color: Colors.white),
            label: Text(
              t.t('faq.common.home'),
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SupportPage()),
          ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF3B82F6)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.help_outline, color: Color(0xFF3B82F6)),
            label: Text(
              t.t('faq.common.needHelp'),
              style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    ],
  );
}

Widget _buildFaqSection(
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
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: scheme.primary, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        children: [
          Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.5)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: points
                  .map(
                    (p) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle,
                              color: Color(0xFF10B981), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              p,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: scheme.onSurfaceVariant,
                                  height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildSupportCard(BuildContext context, AppStrings t) {
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
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child:
              const Icon(Icons.support_agent, color: Color(0xFF10B981), size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.t('faq.common.stuck'),
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                t.t('faq.common.stuck.sub'),
                style:
                    TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SupportPage()),
          ),
          child: Text(t.t('faq.common.contact'),
              style: TextStyle(
                  color: Color(0xFF10B981), fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
}
