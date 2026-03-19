import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:enmkit/core/sms_url_launcher_provider.dart';
import 'package:enmkit/viewmodels/sms_url_launcher_viewmodel.dart';
import 'package:enmkit/models/relay_model.dart';

/// Provider pour le ViewModel URL Launcher
final smsUrlLauncherViewModelProvider = ChangeNotifierProvider<SmsUrlLauncherViewModel>((ref) {
  final service = ref.read(smsUrlLauncherServiceProvider);
  return SmsUrlLauncherViewModel(service);
});

/// Exemple de widget utilisant le SMS URL Launcher
/// Ce widget peut être utilisé comme référence pour intégrer URL Launcher dans vos écrans existants
class SmsUrlLauncherExampleWidget extends ConsumerWidget {
  const SmsUrlLauncherExampleWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(smsUrlLauncherViewModelProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS URL Launcher - Exemple'),
        backgroundColor: Colors.blue[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Indicateur de chargement
            if (viewModel.isLoading)
              const LinearProgressIndicator(),
            
            const SizedBox(height: 16),
            
            // Messages d'erreur
            if (viewModel.errorMessage != null)
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          viewModel.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => viewModel.clearMessages(),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Messages de succès
            if (viewModel.successMessage != null)
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          viewModel.successMessage!,
                          style: const TextStyle(color: Colors.green),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => viewModel.clearMessages(),
                      ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Section Contrôle Relais
            _buildSectionTitle('Contrôle des Relais'),
            const SizedBox(height: 12),
            
            _buildActionButton(
              context: context,
              title: 'Activer Relais 1',
              icon: Icons.power_settings_new,
              color: Colors.green,
              onPressed: () async {
                final relay = RelayModel(id: 1, name: 'Relais 1', amperage: 10, isActive: true);
                await viewModel.toggleRelay(relay);
              },
            ),
            
            _buildActionButton(
              context: context,
              title: 'Désactiver Relais 1',
              icon: Icons.power_off,
              color: Colors.red,
              onPressed: () async {
                final relay = RelayModel(id: 1, name: 'Relais 1', amperage: 10, isActive: false);
                await viewModel.toggleRelay(relay);
              },
            ),
            
            const SizedBox(height: 24),
            
            // Section Consommation
            _buildSectionTitle('Consommation'),
            const SizedBox(height: 12),
            
            _buildActionButton(
              context: context,
              title: 'Demander Consommation',
              icon: Icons.analytics,
              color: Colors.blue,
              onPressed: () async {
                await viewModel.requestConsumption();
              },
            ),
            
            const SizedBox(height: 24),
            
            // Section Configuration
            _buildSectionTitle('Configuration'),
            const SizedBox(height: 12),
            
            _buildActionButton(
              context: context,
              title: 'Configurer Numéro 1',
              icon: Icons.phone,
              color: Colors.orange,
              onPressed: () async {
                await _showPhoneNumberDialog(context, viewModel, 1);
              },
            ),
            
            _buildActionButton(
              context: context,
              title: 'Configurer Numéro 2',
              icon: Icons.phone,
              color: Colors.orange,
              onPressed: () async {
                await _showPhoneNumberDialog(context, viewModel, 2);
              },
            ),
            
            _buildActionButton(
              context: context,
              title: 'Configuration Complète',
              icon: Icons.settings,
              color: Colors.purple,
              onPressed: () async {
                await _showCompleteConfigDialog(context, viewModel);
              },
            ),
            
            const SizedBox(height: 24),
            
            // Section Commande Personnalisée
            _buildSectionTitle('Commande Personnalisée'),
            const SizedBox(height: 12),
            
            _buildActionButton(
              context: context,
              title: 'Envoyer Commande Personnalisée',
              icon: Icons.edit,
              color: Colors.teal,
              onPressed: () async {
                await _showCustomCommandDialog(context, viewModel);
              },
            ),
            
            const SizedBox(height: 24),
            
            // Informations sur URL Launcher
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'À propos de URL Launcher',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'URL Launcher ouvre l\'application SMS native avec le message pré-rempli. '
                      'L\'utilisateur doit confirmer manuellement l\'envoi du SMS.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Avantages:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Text('• Pas de permission SMS requise'),
                    const Text('• Contrôle total par l\'utilisateur'),
                    const Text('• Compatible avec toutes les versions Android/iOS'),
                    const SizedBox(height: 8),
                    const Text(
                      'Inconvénients:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Text('• Nécessite confirmation manuelle'),
                    const Text('• Pas d\'envoi automatique'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _showPhoneNumberDialog(
    BuildContext context,
    SmsUrlLauncherViewModel viewModel,
    int numberIndex,
  ) async {
    final controller = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Configurer Numéro $numberIndex'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Numéro de téléphone',
            hintText: '+237XXXXXXXXX',
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (numberIndex == 1) {
                await viewModel.setFirstPhoneNumber(controller.text);
              } else {
                await viewModel.setSecondPhoneNumber(controller.text);
              }
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCompleteConfigDialog(
    BuildContext context,
    SmsUrlLauncherViewModel viewModel,
  ) async {
    final phone1Controller = TextEditingController();
    final phone2Controller = TextEditingController();
    final consumptionController = TextEditingController();
    final pulsationController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuration Complète'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: phone1Controller,
                decoration: const InputDecoration(
                  labelText: 'Numéro 1',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phone2Controller,
                decoration: const InputDecoration(
                  labelText: 'Numéro 2',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: consumptionController,
                decoration: const InputDecoration(
                  labelText: 'Consommation initiale (kWh)',
                  prefixIcon: Icon(Icons.analytics),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pulsationController,
                decoration: const InputDecoration(
                  labelText: 'Pulsation',
                  prefixIcon: Icon(Icons.speed),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await viewModel.sendCompleteConfiguration(
                firstPhone: phone1Controller.text.isNotEmpty ? phone1Controller.text : null,
                secondPhone: phone2Controller.text.isNotEmpty ? phone2Controller.text : null,
                initialConsumption: consumptionController.text.isNotEmpty 
                    ? double.tryParse(consumptionController.text) 
                    : null,
                pulsation: pulsationController.text.isNotEmpty 
                    ? int.tryParse(pulsationController.text) 
                    : null,
              );
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCustomCommandDialog(
    BuildContext context,
    SmsUrlLauncherViewModel viewModel,
  ) async {
    final controller = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Commande Personnalisée'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Commande SMS',
            hintText: 'Ex: r1on, cons, etc.',
            prefixIcon: Icon(Icons.edit),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await viewModel.sendCustomCommand(controller.text);
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }
}