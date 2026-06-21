import 'package:flutter/material.dart';

class FaqTroubleshootScreen extends StatelessWidget {
  const FaqTroubleshootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dépannage'),
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
              _buildHero(context),
              const SizedBox(height: 24),
              _buildSection(
                context,
                'Le Kit n\'apparaît pas',
                Icons.visibility_off_outlined,
                const [
                  'Vérifie le numéro du Kit dans Paramètres → « Numéro du Kit ».',
                  'Confirme que le Kit est alimenté et câblé correctement.',
                  'Synchronise via « État Système » → « Valider ».'
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                context,
                'La consommation ne se met pas à jour',
                Icons.bolt,
                const [
                  'Onglet Consommation → « Actualiser la consommation ».',
                  'Assure-toi que les pulsations et la consommation initiale sont configurées.',
                  'Si le problème persiste, réessaie plus tard et contacte le support.'
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                context,
                'Ligne non réactive',
                Icons.power_settings_new,
                const [
                  'Vérifie les connexions et l\'ampérage de la ligne.',
                  'Contrôle que la ligne est bien créée et active dans « Lignes Configurées » (Admin).',
                  'Redémarre l\'appareil puis réessaie.'
                ],
              ),
              const SizedBox(height: 28),
              _buildSupportCard(context),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildHero(BuildContext context) {
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
        const Icon(Icons.build_outlined, color: Color(0xFF3B82F6)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Résoudre rapidement les incidents courants',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface)),
              const SizedBox(height: 6),
              Text('Guides rapides pour le Kit, la consommation et les lignes.',
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

Widget _buildSupportCard(BuildContext context) {
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
        const Icon(Icons.support_agent, color: Color(0xFF10B981)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Si le problème persiste, contacte le support avec le numéro du Kit.',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        )
      ],
    ),
  );
}
