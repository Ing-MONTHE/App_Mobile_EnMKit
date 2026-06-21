import 'package:flutter/material.dart';

class FaqDeviceScreen extends StatelessWidget {
  const FaqDeviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appareil / Kit'),
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
                title: 'Configurer et utiliser le Kit',
                subtitle:
                    'Numéro du Kit, lignes, numéros autorisés et synchronisation du système.',
              ),
              const SizedBox(height: 24),
              _buildSection(
                context,
                'Configurer le numéro du Kit',
                Icons.tag,
                const [
                  'Ouvre Paramètres → « Numéro du Kit ».',
                  'Saisis le numéro fourni avec le matériel.',
                  'Enregistre puis vérifie l\'état système.'
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                context,
                'Gérer les lignes',
                Icons.device_hub,
                const [
                  'Paramètres → « Lignes Configurées » (Administrateur).',
                  'Ajouter: indique le nom (ex: Salon) et l\'ampérage (4/8/12A).',
                  'Modifier/Supprimer: utilise les icônes dédiées sur chaque ligne.'
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                context,
                'Numéros autorisés',
                Icons.phone_android,
                const [
                  'Paramètres → « Numéros Autorisés ».',
                  'Ajoute au moins un numéro; un second est optionnel.',
                  'Ces numéros sont utilisés pour contrôler le Kit par SMS.'
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                context,
                'État système et synchronisation',
                Icons.info_outline,
                const [
                  'Paramètres → « État Système » pour vérifier l\'opérationnalité.',
                  'Appuie sur « Valider » pour renvoyer la configuration actuelle au Kit.',
                  'Vérifie que le Kit est alimenté et correctement câblé.'
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                context,
                'Conseils d\'installation',
                Icons.build_rounded,
                const [
                  'Respecte l\'ampérage maximal des lignes.',
                  'Isole et fixe proprement les connexions.',
                  'Garde le Kit dans un environnement ventilé et sec.'
                ],
              ),
              const SizedBox(height: 28),
              _buildTipCard(context),
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

Widget _buildTipCard(BuildContext context) {
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
            'Astuce: utilise « État Système » pour confirmer la synchronisation après chaque changement.',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        )
      ],
    ),
  );
}
