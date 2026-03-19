import 'package:flutter/material.dart';

class FaqTroubleshootScreen extends StatelessWidget {
  const FaqTroubleshootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dépannage'),
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
                'Relais non réactif',
                Icons.power_settings_new,
                const [
                  'Vérifie les connexions et l\'ampérage du relais.',
                  'Contrôle que le relais est bien créé et actif dans « Relais Configurés » (Admin).',
                  'Redémarre l\'appareil puis réessaie.'
                ],
              ),
              const SizedBox(height: 28),
              _buildSupportCard(),
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
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6))],
    ),
    child: const Row(
      children: [
        Icon(Icons.build_outlined, color: Color(0xFF3B82F6)),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Résoudre rapidement les incidents courants', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              SizedBox(height: 6),
              Text('Guides rapides pour le Kit, la consommation et les relais.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4)),
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

Widget _buildSupportCard() {
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
        Icon(Icons.support_agent, color: Color(0xFF10B981)),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Si le problème persiste, contacte le support avec le numéro du Kit.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        )
      ],
    ),
  );
}


