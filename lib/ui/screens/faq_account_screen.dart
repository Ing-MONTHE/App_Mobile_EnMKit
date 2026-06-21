import 'package:flutter/material.dart';

class FaqAccountScreen extends StatelessWidget {
  const FaqAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compte & Connexion'),
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
              _buildHeroInfo(context),
              const SizedBox(height: 20),
              _buildActionButtons(context),
              const SizedBox(height: 24),
              _buildFaqSection(
                context,
                'Créer un compte EnMKit',
                Icons.person_add_alt,
                const [
                  'Ouvre l\'application EnMKit Control.',
                  'Depuis l\'écran d\'accueil, touche « Se connecter / Créer un compte ».',
                  'Renseigne ton email et un mot de passe sécurisé.',
                  'Valide la création.',
                ],
              ),
              const SizedBox(height: 16),
              _buildFaqSection(
                context,
                'Se connecter à son compte',
                Icons.login,
                const [
                  'Accède à l\'écran de connexion.',
                  'Entre tes identifiants (email + mot de passe).',
                  'Appuie sur « Connexion ».',
                  'En cas d\'échec, vérifie t\'es identifiant et recommence.',
                ],
              ),
              const SizedBox(height: 16),
              _buildFaqSection(
                context,
                'Rôles et accès',
                Icons.verified_user_outlined,
                const [
                  'Administrateur: peut configurer le Kit (pulsations, consommation initiale, etc.).',
                  'Utilisateur: peut consulter l\'état, la consommation et les informations du système.',
                  'Si certaines options ne s\'affichent pas, il est probable que ton rôle n\'y autorise pas l\'accès.',
                ],
              ),

              const SizedBox(height: 16),
              _buildFaqSection(
                context,
                'Sécurité du compte',
                Icons.security_outlined,
                const [
                  'Utilise un mot de passe long et unique.',
                  'Ne partage pas tes identifiants avec d\'autres utilisateurs.',
                  'Déconnecte-toi des appareils publics après utilisation.',
                ],
              ),
              const SizedBox(height: 16),
              _buildFaqSection(
                context,
                'Problèmes de connexion réseau',
                Icons.wifi_tethering_off,
                const [
                  'Vérifie que le téléphone a un forfait SMS',
                  'Si la consommation ne s\'actualise pas: utilise « Actualiser la consommation » dans l\'onglet Consommation.',
                  'Si le Kit n\'apparaît pas: assure-toi que le numéro du Kit est configuré dans Paramètres.',
                  'Synchronise les paramètres via « État Système » puis « Valider » pour renvoyer la config au Kit.',
                  'En cas d\'échec persistant, redémarre l\'appareil et réessaie.',
                ],
              ),
              const SizedBox(height: 28),
              _buildSupportCard(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildHeroInfo(BuildContext context) {
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
                'Gérer votre compte en toute simplicité',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Connexion, rôles, sécurité et récupération d\'accès pour EnMKit Control.',
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

Widget _buildActionButtons(BuildContext context) {
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
            label: const Text(
              'Retour à l\'accueil',
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
            onPressed: () => _showSupportDialog(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF3B82F6)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.help_outline, color: Color(0xFF3B82F6)),
            label: const Text(
              'Besoin d\'aide ?',
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
                'Toujours bloqué ?',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                'Contacte le support avec ton email et le numéro du Kit.',
                style:
                    TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () => _showSupportDialog(context),
          child: const Text('Contacter',
              style: TextStyle(
                  color: Color(0xFF10B981), fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
}

void _showSupportDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: const Text('Contacter le support', style: TextStyle(color: Colors.white)),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Merci de préparer les informations suivantes :',
            style: TextStyle(color: Colors.white70),
          ),
          SizedBox(height: 8),
          Text('- Email du compte', style: TextStyle(color: Colors.white, height: 1.4)),
          Text('- Numéro du Kit (si configuré)', style: TextStyle(color: Colors.white, height: 1.4)),
          Text('- Description du problème', style: TextStyle(color: Colors.white, height: 1.4)),
          SizedBox(height: 12),
          Text(
            'Canaux de contact:',
            style: TextStyle(color: Colors.white70),
          ),
          SizedBox(height: 6),
          Text('• Email: support@enmkit.app', style: TextStyle(color: Colors.white)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer', style: TextStyle(color: Colors.white70)),
        ),
      ],
    ),
  );
}


