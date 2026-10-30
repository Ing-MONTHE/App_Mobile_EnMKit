import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:enmkit/providers.dart';
import 'package:enmkit/ui/screens/faq_account_screen.dart';
import 'package:enmkit/ui/screens/faq_device_screen.dart';
import 'package:enmkit/ui/screens/faq_learning_screen.dart';
import 'package:enmkit/ui/screens/faq_qr_screen.dart';
import 'package:enmkit/ui/screens/faq_troubleshoot_screen.dart';

/// Accueil de la FAQ (Réglages > Aide > Questions fréquentes). Les textes
/// viennent du catalogue i18n (clés `faq.*`), donc suivent la langue choisie.
class FaqScreen extends ConsumerWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    final categories = <(String, IconData, Widget)>[
      ('access', Icons.lock_outline, const FaqAccountScreen()),
      ('kit', Icons.memory, const FaqDeviceScreen()),
      ('qr', Icons.qr_code, const FaqQrScreen()),
      ('ai', Icons.school_outlined, const FaqLearningScreen()),
      ('trouble', Icons.build_outlined, const FaqTroubleshootScreen()),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('faq.title')),
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
              const SizedBox(height: 8),
              for (final (i, c) in categories.indexed) ...[
                if (i > 0) const SizedBox(height: 10),
                _buildSettingCard(
                  context,
                  t.t('faq.home.${c.$1}'),
                  t.t('faq.home.${c.$1}.sub'),
                  c.$2,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => c.$3),
                  ),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildSettingCard(
  BuildContext context,
  String title,
  String subtitle,
  IconData icon,
  VoidCallback onTap,
) {
  final scheme = Theme.of(context).colorScheme;
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: scheme.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: scheme.onSurfaceVariant, size: 20),
        ],
      ),
    ),
  );
}