import 'package:flutter/material.dart';

class FaqQrScreen extends StatelessWidget {
  const FaqQrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR & Configuration'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF1E293B),
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHero(),
              const SizedBox(height: 24),
              _buildSection(
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
                'Après import',
                Icons.cloud_done_outlined,
                const [
                  'Les données du Kit sont régénérées automatiquement.',
                  'Utilise « État Système » → « Valider » pour renvoyer la config au Kit.',
                  'Vérifie la consommation et les relais dans leurs onglets respectifs.'
                ],
              ),
              const SizedBox(height: 28),
              _buildInfoCard(),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildHero() {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6)),
      ],
    ),
    child: const Row(
      children: [
        Icon(Icons.qr_code, color: Color(0xFF3B82F6)),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gérer vos QR Codes de configuration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              SizedBox(height: 6),
              Text('Génération, import et synchronisation des données du Kit en toute sécurité.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4)),
            ],
          ),
        )
      ],
    ),
  );
}

Widget _buildSection(String title, IconData icon, List<String> points) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Theme(
      data: ThemeData().copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFF3B82F6).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: const Color(0xFF3B82F6), size: 22),
        ),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
        children: [
          const Divider(height: 1),
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
                            const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(p, style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4))),
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

Widget _buildInfoCard() {
  return Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: const Row(
      children: [
        Icon(Icons.info_outline, color: Color(0xFF0EA5E9)),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Astuce: conserve une copie du QR Code de configuration pour restaurer rapidement le système.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        )
      ],
    ),
  );
}


