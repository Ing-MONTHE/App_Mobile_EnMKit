import 'package:flutter/material.dart';

class FaqDeviceScreen extends StatelessWidget {
  const FaqDeviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appareil / Kit'),
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
              _buildHero(
                icon: Icons.memory,
                title: 'Configurer et utiliser le Kit',
                subtitle:
                    'Numéro du Kit, relais, numéros autorisés et synchronisation du système.'
              ),
              const SizedBox(height: 24),
              _buildSection(
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
                'Gérer les relais',
                Icons.device_hub,
                const [
                  'Paramètres → « Relais Configurés » (Administrateur).',
                  'Ajouter: indique le nom (ex: Salon) et l\'ampérage (4/8/12A).',
                  'Modifier/Supprimer: utilise les icônes dédiées sur chaque relais.'
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
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
                'Conseils d\'installation',
                Icons.build_rounded,
                const [
                  'Respecte l\'ampérage maximal des relais.',
                  'Isole et fixe proprement les connexions.',
                  'Garde le Kit dans un environnement ventilé et sec.'
                ],
              ),
              const SizedBox(height: 28),
              _buildTipCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildHero({required IconData icon, required String title, required String subtitle}) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              const SizedBox(height: 6),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4)),
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
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
      ],
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

Widget _buildTipCard() {
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
        Icon(Icons.lightbulb, color: Color(0xFFF59E0B)),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Astuce: utilise « État Système » pour confirmer la synchronisation après chaque changement.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        )
      ],
    ),
  );
}


