import 'package:flutter/material.dart';

class FaqQrScreen extends StatelessWidget {
  const FaqQrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR & Configuration'),
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
                'Générer le QR Code',
                Icons.qr_code,
                const [
                  'Paramètres → « Générer QR Code » (non-admin).',
                  'Le QR contient la configuration actuelle du Kit (numéro, relais, etc.).',
                  'Partage utile pour sauvegarde ou duplication d\'installation.'
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                context,
                'Importer un QR Code',
                Icons.qr_code_scanner,
                const [
                  'Paramètres → « Importer QR Code ».',
                  'Scanner avec la caméra ou importer depuis la galerie.',
                  'Une confirmation s\'affiche avant d\'écraser les données actuelles.'
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                context,
                'Après import',
                Icons.cloud_done_outlined,
                const [
                  'Les données du Kit sont régénérées automatiquement.',
                  'Utilise « État Système » → « Valider » pour renvoyer la config au Kit.',
                  'Vérifie la consommation et les lignes dans leurs onglets respectifs.'
                ],
              ),
              const SizedBox(height: 28),
              _buildInfoCard(context),
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
        const Icon(Icons.qr_code, color: Color(0xFF3B82F6)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gérer vos QR Codes de configuration',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface)),
              const SizedBox(height: 6),
              Text(
                  'Génération, import et synchronisation des données du Kit en toute sécurité.',
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

Widget _buildInfoCard(BuildContext context) {
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
        const Icon(Icons.info_outline, color: Color(0xFF0EA5E9)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Astuce: conserve une copie du QR Code de configuration pour restaurer rapidement le système.',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        )
      ],
    ),
  );
}
