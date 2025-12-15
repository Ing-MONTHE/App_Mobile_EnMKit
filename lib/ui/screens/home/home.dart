
import 'package:enmkit/core/db_service.dart';
import 'package:enmkit/core/qr_generate_database_service.dart';
import 'package:enmkit/core/qr_service.dart';
import 'package:enmkit/core/sms_service.dart';
import 'package:enmkit/models/allowed_number_model.dart';
import 'package:enmkit/models/kit_model.dart';
import 'package:enmkit/models/relay_model.dart';
import 'package:enmkit/providers.dart';
import 'package:enmkit/repositories/allowed_number_repository.dart';
import 'package:enmkit/repositories/kit_repository.dart';
import 'package:enmkit/repositories/relay_repository.dart';
import 'package:enmkit/ui/screens/qr_screen.dart';
import 'package:enmkit/ui/screens/faq_screen.dart';
import 'package:enmkit/ui/screens/relays_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
 import 'dart:convert';
import 'dart:async';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';

final MobileScannerController _scannerController = MobileScannerController();
// Modèles de données
class Relay {
  final String id;
  final String name;
  final double amperage;
  bool isOn;

  Relay({
    required this.id,
    required this.name,
    required this.amperage,
    this.isOn = false,
  });
}

class ConsumptionData {
  final DateTime time;
  final double value;

  ConsumptionData({required this.time, required this.value});
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _pageTitles = [
    'Tableau de Bord',
    'Contrôle Relais',
    'Consommation',
    'Paramètres'
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBodyBehindAppBar: true,
      appBar: _buildCleanAppBar(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8FAFC),
              Color(0xFFFFFFFF),
              Color(0xFFF1F5F9),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              children: const [
                HomeScreen(),
                RelaysScreen(),
                ConsumptionScreen(),
                SettingsScreen(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildCleanBottomNav(),
    );
  }

  PreferredSizeWidget _buildCleanAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(12),
              // boxShadow: [
              //   BoxShadow(
              //     color: const Color(0xFF3B82F6).withOpacity(0.25),
              //     blurRadius: 8,
              //     offset: const Offset(0, 2),
              //   ),
              // ],
            ),
            child: Image.asset(
              'asset/images/logo3.png',
              width: 24,
              height: 30,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'EnMKit Control',
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _pageTitles[_currentIndex],
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.electric_bolt_outlined,
            color: Color(0xFF64748B),
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildCleanBottomNav() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: CurvedNavigationBar(
        index: _currentIndex,
        height: 65,
        items: [
          Icon(Icons.dashboard_rounded, size: 26, color: _currentIndex == 0 ? Colors.white : const Color(0xFF64748B)),
          Icon(Icons.electrical_services, size: 26, color: _currentIndex == 1 ? Colors.white : const Color(0xFF64748B)),
          Icon(Icons.analytics_rounded, size: 26, color: _currentIndex == 2 ? Colors.white : const Color(0xFF64748B)),
          Icon(Icons.settings_rounded, size: 26, color: _currentIndex == 3 ? Colors.white : const Color(0xFF64748B)),
        ],
        color: Colors.white,
        buttonBackgroundColor: const Color(0xFF3B82F6),
        backgroundColor: Colors.transparent,
        animationCurve: Curves.easeInOutCubic,
        animationDuration: const Duration(milliseconds: 600),
        onTap: (index) {
          setState(() => _currentIndex = index);
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
          );
        },
      ),
    );
  }
}

// ÉCRAN D'ACCUEIL ÉPURÉ
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildWelcomeCard(ref),
            const SizedBox(height: 24),
            _buildQuickStats(ref),
            // const SizedBox(height: 24),
            // _buildQuickActions(),
            const SizedBox(height: 24),
            _buildSystemStatus(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(WidgetRef ref) {
    final relayVM = ref.watch(relaysProvider);
    final totalRelay=relayVM.activeRelaysCount+relayVM.inactiveRelaysCount;
    final consumption =ref.watch(consumptionProvider);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 40,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.wb_sunny_outlined,
              color: Color(0xFF3B82F6),
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Bienvenue sur EnMKit',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Votre système fonctionne parfaitement',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              
              _buildMiniStat('$totalRelay', 'Relais', Icons.power),
              _buildMiniStat(
                (() {
                  final last = consumption.getLastConsumption();
                  if (last == null) return 'Pas de données';
                  return '${last.kwh}';
                })(),
                'kWh',
                Icons.flash_on,
              ),

              _buildMiniStat('98%', 'Statut', Icons.check_circle),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF3B82F6), size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

Widget _buildQuickStats(WidgetRef ref) {
  final relayVM = ref.watch(relaysProvider);

  return Row(
    children: [
      Expanded(
        child: _buildStatCard(
          'Actifs',
          '${relayVM.activeRelaysCount} Relais',
          Icons.electrical_services,
          const Color(0xFF10B981),
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: _buildStatCard(
          'Inactifs',
          '${relayVM.inactiveRelaysCount} Relais',
          Icons.flash_off,
          const Color(0xFFE11D48),
        ),
      ),
    ],
  );
}



  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions Rapides',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildActionButton('Contrôle', Icons.electrical_services, const Color(0xFF3B82F6))),
            const SizedBox(width: 12),
            Expanded(child: _buildActionButton('Analyse', Icons.analytics, const Color(0xFF10B981))),
            const SizedBox(width: 12),
            Expanded(child: _buildActionButton('Config', Icons.settings, const Color(0xFF8B5CF6))),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatus() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Système Opérationnel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  'Synchronisation Valide',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ÉCRAN DE CONSOMMATION ÉPURÉ
class ConsumptionScreen extends ConsumerWidget {
  const ConsumptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(consumptionProvider);
    if (vm.consumptions.isEmpty) {
      vm.fetchConsumptions();
    }
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildCurrentConsumption(ref),
            const SizedBox(height: 24),
            _buildRefreshButton(ref),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentConsumption(WidgetRef ref) {
    final consumptionVM = ref.watch(consumptionProvider);
    final kitP=ref.watch(kitProvider);
    final dataKit=kitP.kits.isNotEmpty ? kitP.kits.first : null;
    final smsVM = ref.watch(smsListenerProvider);
    final lastRecord = consumptionVM.getLastConsumption();
    final lastConsumptionText = lastRecord != null
        ? "${lastRecord.kwh} kWh"
        : smsVM.lastSms;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.flash_on, color: Color(0xFF3B82F6), size: 32),
          ),
          const SizedBox(height: 20),
          Text(
            lastConsumptionText.toString(),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Dernière consommation',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildConsumptionStat('${dataKit?.pulseCount}', 'Pulsations', Icons.timeline),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConsumptionStat(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF3B82F6), size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsumptionChart(List<ConsumptionData> data) {
    double maxValue = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    
    return Container(
      height: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Historique des 7 derniers jours',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: data.asMap().entries.map((entry) {
                int index = entry.key;
                ConsumptionData consumption = entry.value;
                double heightPercentage = consumption.value / maxValue;
                
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          consumption.value.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: (heightPercentage * 180).clamp(20.0, 180.0),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getDayLabel(index),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _getDayLabel(int index) {
    List<String> days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    DateTime now = DateTime.now();
    DateTime day = now.subtract(Duration(days: 6 - index));
    return days[day.weekday - 1];
  }

  Widget _buildRefreshButton(WidgetRef ref)  {
    final kitRepository=KitRepository( DBService());
  final SmsService smsService=SmsService(kitRepository);
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF10B981),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () {
             // Armer la fenêtre d'acceptation des réponses de consommation
             try {
               final smsListener = ref.read(smsListenerProvider);
               smsListener.armConsumptionWindow(window: const Duration(minutes: 5));
             } catch (_) {}
             smsService.requestConsumption();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.refresh, color: Colors.white, size: 22),
        label: const Text(
          'Actualiser la consommation',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// NOUVELLE ÉCRAN DE PARAMÈTRES
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _kitController = TextEditingController();
  final TextEditingController _controllerController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final kitData = ref.watch(kitProvider);
    final userData=ref.watch(authProvider).user;
    final relaysData = ref.watch(relaysProvider);
    final dbService = DBService();
      final qrService = QrService(
      kitRepo: KitRepository(dbService),
      relayRepo: RelayRepository(dbService),
      allowedRepo: AllowedNumberRepository(dbService),
    );
    
    return SingleChildScrollView(
      
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            if(!userData!.isAdmin)     
            _buildSettingCard(
              'Numéro du Kit',
              '${kitData.kits.isNotEmpty ? kitData.kits.first.kitNumber : "Non configuré"}',
              Icons.memory,
              () => _showEditDialog('Kit', _kitController),
            ),
            const SizedBox(height: 16),
            if(userData.isAdmin) 
            _buildSettingCard(
              'Relais Configurés',
              '${relaysData.relays.length} configurés',
              Icons.device_hub,
              () => _showControllersDialog(ref),
            ),
            const SizedBox(height: 16),
            if(!userData.isAdmin) 
            _buildSettingCard(
              'Générer QR Code',
              'Configuration système',
              Icons.qr_code,
              () =>  Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QrPage(qrService: qrService),
      ),),
            ),
            const SizedBox(height: 16),
            if(!userData.isAdmin) 
            _buildSettingCard(
              'État Système',
              kitData.kits.isNotEmpty ? 'Opérationnel' : 'Arrêté',
              Icons.info_outline,
              () => _showSystemStatus(),
            ),
            const SizedBox(height: 16),
            if(!userData.isAdmin) 
            _buildSettingCard(
              'Numéros Autorisés',
              'à controler le Kit',
              Icons.phone_android,
              () => _showAllowedNumbersDialog(),
            ),
            if(userData.isAdmin) 
            _buildSettingCard(
              'Paramètres Compteurs',
              'à definir ici',
              Icons.settings,
              () => _showPulseAndConsumptionDialog(),
            ),
            
            

  const SizedBox(height: 16),
          if(!userData.isAdmin) 
            _buildSettingCard(
              'Importer QR Code',
              'Mise à jour config',
              Icons.qr_code_scanner,
              () => _importQRCode(),
            ),
            const SizedBox(height: 16),
            _buildSettingCard(
              'FAQ',
              'Questions fréquentes',
              Icons.help_outline,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FaqScreen(),
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

 Widget _buildSettingCard(
    String title, String subtitle, IconData icon, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(vertical: 8), // espacement entre cartes
      decoration: BoxDecoration(
        color: Colors.grey[100], // fond clair pour contraster avec le blanc du background
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87, // texte foncé pour le contraste
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54, // texte secondaire plus léger
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            color: Colors.black38, // flèche discrète mais visible
            size: 16,
          ),
        ],
      ),
    ),
  );
}


void _showEditDialog( String field, TextEditingController controller) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: Text(
        'Modifier $field',
        style: const TextStyle(color: Colors.white),
      ),
      content: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Entrer le Numero $field',
          hintStyle: const TextStyle(color: Colors.white54),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF3B82F6)),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Annuler',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            if (field == 'Kit') {
              final kitVM = ref.read(kitProvider.notifier);
              final newKitNumber = controller.text.trim();

              if (newKitNumber.isNotEmpty) {
                try {
                  // Vérifie s’il existe déjà un kit
                  final existingKit = await kitVM.getKitNumber();
                  if (existingKit != null) {
                    // Mettre à jour le kit existant
                    await kitVM.updateKit(
                      KitModel(kitNumber: newKitNumber),
                    );
                  } else {
                    // Ajouter un nouveau kit
                    await kitVM.addKit(
                      KitModel(kitNumber: newKitNumber),
                    );
                  }
                  // Rafraîchir la liste
                  await kitVM.fetchKits();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Erreur lors de la mise à jour : $e")),
                  );
                }
              }
            }
            Navigator.pop(context);
          },
          child: const Text('Sauvegarder'),
        ),
      ],
    ),
  );
}



void _showPulseAndConsumptionDialog() {
  final kitP = ref.watch(kitProvider);
  final TextEditingController pulsesController = TextEditingController();
  final TextEditingController consumptionController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: const Text(
        'Configurer Consommation',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Champ Pulsations
          TextField(
            controller: pulsesController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Nombre d’impulsions',
              hintStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF3B82F6)),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF3B82F6)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Champ Consommation initiale
          TextField(
            controller: consumptionController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Consommation initiale (kWh)',
              hintStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF3B82F6)),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF3B82F6)),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
          ),
          onPressed: () {
            final pulsesText = pulsesController.text.trim();
            final consumptionText = consumptionController.text.trim();

            if (pulsesText.isNotEmpty && consumptionText.isNotEmpty) {
              final pulses = int.tryParse(pulsesText);
              final consumption = double.tryParse(consumptionText);

              if (pulses != null && consumption != null) {
               kitP.updateKit(kitP.kits.first.copyWith(
                  pulseCount: pulses,
                  initialConsumption: consumption,
                ));
                Navigator.pop(context);
              }
            }
          },
          child: const Text('Enregistrer'),
        ),
      ],
    ),
  );
}


void _showAllowedNumbersDialog( ) {

  final TextEditingController number1Controller = TextEditingController();
  final TextEditingController number2Controller = TextEditingController();
 final allownumbers=ref.watch(allowedNumberProvider);
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: const Text(
        'Ajouter Numéros Autorisés',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: number1Controller,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Numéro 1 (obligatoire)',
              hintStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF3B82F6)),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF3B82F6)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: number2Controller,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Numéro 2 (optionnel)',
              hintStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF3B82F6)),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF3B82F6)),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
          ),
          onPressed: () {
            final number1 = number1Controller.text.trim();
            final number2 = number2Controller.text.trim();

            if (number1.isNotEmpty) {
             allownumbers.addAllowedNumber(AllowedNumberModel(phoneNumber: number1));
              if (number2.isNotEmpty) {
                  allownumbers.addAllowedNumber(AllowedNumberModel(phoneNumber: number2));
                }
              Navigator.pop(context);
            }
          },
          child: const Text('Enregistrer'),
        ),
      ],
    ),
  );
}



void _showControllersDialog(WidgetRef ref) {
  final relaysData = ref.watch(relaysProvider);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: const Text('Relais', style: TextStyle(color: Colors.white)),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: relaysData.relays.map((relay) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.device_hub, color: Color(0xFF3B82F6), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        relay.name ?? "",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    // Bouton édition
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.yellowAccent, size: 20),
                      onPressed: () {
                        final TextEditingController editController = TextEditingController(text: relay.name);
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFF1E293B),
                            title: const Text('Modifier le nom', style: TextStyle(color: Colors.white)),
                            content: TextField(
                              controller: editController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: 'Nouveau nom du relais',
                                hintStyle: TextStyle(color: Colors.white54),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Color(0xFF3B82F6)),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Color(0xFF3B82F6)),
                                ),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Annuler', style: TextStyle(color: Colors.white70)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3B82F6),
                                ),
                                onPressed: () {
                                  final newName = editController.text.trim();
                                  if (newName.isNotEmpty) {
                                    relaysData.updateRelay(
                                      RelayModel(id: relay.id, name: newName, amperage: relay.amperage, isActive: relay.isActive),
                                    );
                                  }
                                  SnackBar snackBar = const SnackBar(
                                    content: Text('Nom du relais mis à jour', style: TextStyle(color: Colors.white)),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 2),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                                  Navigator.pop(context);
                                },
                                child: const Text('Valider'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    // Bouton suppression
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                      onPressed: () {
                         relaysData.deleteRelay(relay.id!);
                         SnackBar snackBar = const SnackBar(
                          content: Text('Relais supprimé', style: TextStyle(color: Colors.white)),
                          backgroundColor: Colors.redAccent,
                          duration: Duration(seconds: 2),);
                          ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      },
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer', style: TextStyle(color: Color(0xFF3B82F6))),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
          ),
          onPressed: () {
            Navigator.pop(context);
            _showAddControllerDialog();
          },
          child: const Text('Ajouter'),
        ),
      ],
    ),
  );
}



  void _showAddControllerDialog() {
    final relaysData = ref.watch(relaysProvider);
  final TextEditingController nameController = TextEditingController();
  String selectedAmperage = '4'; // valeur par défaut

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: const Text('Ajouter Relais', style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Nom du relais
          TextField(
            controller: nameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Ex: Salon',
              hintStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF3B82F6)),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF3B82F6)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Amperage
          DropdownButtonFormField<String>(
            initialValue: selectedAmperage,
            dropdownColor: const Color(0xFF1E293B),
            decoration: const InputDecoration(
              labelText: 'Amperage (A)',
              labelStyle: TextStyle(color: Colors.white70),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF3B82F6)),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF3B82F6)),
              ),
            ),
            style: const TextStyle(color: Colors.white),
            items: ['4', '8','12']
                .map((amp) => DropdownMenuItem(
                      value: amp,
                      child: Text(amp, style: const TextStyle(color: Colors.white)),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) selectedAmperage = value;
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
          onPressed: () {
            final name = nameController.text.trim();
            if (name.isNotEmpty && selectedAmperage.isNotEmpty) {
              // Appel de la méthode d'ajout
              relaysData.addRelay(RelayModel(amperage: int.parse(selectedAmperage),name: name));
              addRelay(name: name, amperage: selectedAmperage);

              Navigator.pop(context);
            }
          },
          child: const Text('Ajouter'),
        ),
      ],
    ),
  );
}

/// Exemple de méthode addRelay (à adapter selon ton ViewModel ou repository)
void addRelay({required String name, required String amperage}) {
  print('Ajouter relais: $name, $amperage');
  // Ici tu peux appeler ton ViewModel, par ex:
  // ref.read(relaysProvider).addRelay(RelayModel(name: name, amperage: amperage, isActive: false));
}




  void _showSystemStatus() {
    final kitData = ref.watch(kitProvider);
    final relayData=ref.watch(relaysProvider);
    final userData=ref.watch(authProvider).user;
    final numeroAllows=ref.watch(allowedNumberProvider);
    final smsService=SmsService(KitRepository(DBService()));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('État du Système', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kitData.kits.isNotEmpty 
                    ? const Color(0xFF10B981).withOpacity(0.2)
                    : const Color(0xFFEF4444).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: kitData.kits.isNotEmpty
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    kitData.kits.isNotEmpty ? Icons.check_circle : Icons.error,
                    color: kitData.kits.isNotEmpty 
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    kitData.kits.isNotEmpty ? 'OPÉRATIONNEL' : 'ARRÊTÉ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kitData.kits.isNotEmpty
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    kitData.kits.isNotEmpty
                        ? 'Tous les systèmes fonctionnent normalement'
                        : 'Le système nécessite une attention',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildStatusInfo('Numero Kit:', kitData.kits.first.kitNumber??'Non configuré'),
            _buildStatusInfo('Etats Relais:', '${relayData.activeRelaysCount} actifs'),
            _buildStatusInfo('Consommation Initiale:', '${kitData.kits.first.initialConsumption??0} kWh'),
            _buildStatusInfo('Pulsation :', '${kitData.kits.first.pulseCount??0}'),
            _buildStatusInfo('Utilisateurs Autorisés:', '${numeroAllows.allowedNumbers.length} numéros'),
            _buildStatusInfo('numero 1:', numeroAllows.allowedNumbers.isNotEmpty ? numeroAllows.allowedNumbers.first.phoneNumber : "Non configuré"),
            _buildStatusInfo('numero 2:', numeroAllows.allowedNumbers.length>1 ? numeroAllows.allowedNumbers[1].phoneNumber : "Non configuré"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer', style: TextStyle(color: Colors.white70)),
          ),

           TextButton(
            onPressed: () async {
              final smsListener = ref.read(smsListenerProvider);
              
              // Fonction helper pour envoyer le message concaténé unique
              Future<String> sendConcatenatedMessage() async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Envoi configuration système complète...', style: TextStyle(color: Colors.white)),
                    backgroundColor: Color(0xFF3B82F6),
                    duration: Duration(seconds: 3),
                  ),
                );
                
                final concatenatedMessage = await smsService.sendConcatenatedSystemConfig(
                  firstPhone: numeroAllows.allowedNumbers.isNotEmpty 
                      ? numeroAllows.allowedNumbers.first.phoneNumber 
                      : null,
                  secondPhone: numeroAllows.allowedNumbers.length > 1 
                      ? numeroAllows.allowedNumbers[1].phoneNumber 
                      : null,
                  initialConsumption: kitData.kits.first.initialConsumption?.toDouble() ?? 0.0,
                  pulsation: kitData.kits.first.pulseCount ?? 0,
                );
                
                return concatenatedMessage;
              }

              SnackBar snackBar = const SnackBar(
                content: Text('Paramétrage en cours, en attente de l\'accusé...', style: TextStyle(color: Colors.white)),
                backgroundColor: Color(0xFF3B82F6),
                duration: Duration(seconds: 2),);
              ScaffoldMessenger.of(context).showSnackBar(snackBar);

              // 1) Envoyer le message concaténé unique
              String sentMessage = '';
              try {
                sentMessage = await sendConcatenatedMessage();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur envoi SMS: $e')),
                );
                return;
              }

              // 2) Attendre l'ACK correspondant au message concaténé
              // Créer un set avec une partie identifiable du message pour l'attente
              final expectedAcksSet = <String>{sentMessage.split(':')[0]}; // utilise la première partie (ex: "n1")
              
              // Collecter les messages d'accusés reçus pour vérification stricte
              List<String> receivedAcks = [];
              final completer = Completer<bool>();
              late StreamSubscription ackSubscription;
              
              ackSubscription = smsListener.trustedSms$.listen((ackMessage) {
                receivedAcks.add(ackMessage);
              });
              
              final receivedAll = await smsListener.waitForAllAcks(expectedAcksSet, totalTimeout: const Duration(minutes: 5));
              ackSubscription.cancel();

              if (!receivedAll) {
                // Proposer de renvoyer
                final retry = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF1E293B),
                    title: const Text('Accusés non reçus', style: TextStyle(color: Colors.white)),
                    content: const Text('Souhaites-tu renvoyer les messages ?', style: TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(onPressed: ()=> Navigator.pop(context, false), child: const Text('Non', style: TextStyle(color: Colors.white70))),
                      ElevatedButton(onPressed: ()=> Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)), child: const Text('Renvoyer')),
                    ],
                  ),
                );
                if (retry == true) {
                  // Relancer l'action avec le nouveau format
                  try {
                    sentMessage = await sendConcatenatedMessage();
                  } catch (_) {}
                }
                return;
              }

              // 3) Vérification stricte du message reçu vs envoyé
              bool messageVerified = false;
              String validAckMessage = '';
              
              for (String ackMessage in receivedAcks) {
                if (smsService.verifyAckMessage(ackMessage, sentMessage)) {
                  messageVerified = true;
                  validAckMessage = ackMessage;
                  break;
                }
              }
              
              if (!messageVerified) {
                // Afficher dialogue de demande de renvoi pour vérification échouée
                final retryVerification = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF1E293B),
                    title: const Text('Vérification échouée', style: TextStyle(color: Colors.white)),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Le message de configuration ne correspond pas à l\'accusé reçu:', 
                                   style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 8),
                        Text('• $sentMessage', 
                             style: const TextStyle(color: Colors.red, fontSize: 12)),
                        const SizedBox(height: 16),
                        const Text('Souhaites-tu renvoyer le message ?', 
                                   style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                    actions: [
                      TextButton(onPressed: ()=> Navigator.pop(context, false), 
                                child: const Text('Non', style: TextStyle(color: Colors.white70))),
                      ElevatedButton(onPressed: ()=> Navigator.pop(context, true), 
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)), 
                                    child: const Text('Renvoyer')),
                    ],
                  ),
                );
                
                if (retryVerification == true) {
                  // Relancer l'action complète
                  try {
                    sentMessage = await sendConcatenatedMessage();
                  } catch (_) {}
                }
                return;
              }

              // 4) ACK reçu et vérifié: afficher les informations de configuration
              if (validAckMessage.isNotEmpty) {
                final configData = smsService.parseAckMessage(validAckMessage);
                

              }

              // 5) Demander au kit d'appliquer (ok)
              try {
                // Notification visuelle lors de l'envoi de "Fin_config"
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Envoi Fin_config(application config)...', style: TextStyle(color: Colors.white)),
                    backgroundColor: Color(0xFF3B82F6),
                    duration: Duration(seconds: 30),
                  ),
                );
                await smsService.applyConfiguration();
                // Attendre que la notification de 30s se termine avant d'afficher la suivante
                await Future.delayed(const Duration(seconds: 30));
                SnackBar snackBar2 = const SnackBar(
                  content: Text('Paramétrage validé et appliqué', style: TextStyle(color: Colors.white)),
                  backgroundColor: Color(0xFF10B981),
                  duration: Duration(seconds: 2),);
                ScaffoldMessenger.of(context).showSnackBar(snackBar2);
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur application configuration: $e')),
                );
              }
            },
            child: const Text('Valider', style: TextStyle(color: Colors.white70)),
          ),
           
        ],
      ),
    );
  }

  Widget _buildStatusInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  /// Affiche une boîte de dialogue avec les informations de configuration reçues dans l'ACK
  void _showConfigurationConfirmation(Map<String, String> configData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Color(0xFF10B981),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Configuration Confirmée',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Le kit a confirmé la réception et l\'application des paramètres suivants :',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                ),
              ),
              child: Column(
                children: configData.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          entry.value,
                          style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Color(0xFF3B82F6),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Votre kit est maintenant configuré avec ces paramètres.',
                      style: TextStyle(
                        color: Color(0xFF3B82F6),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Parfait !'),
          ),
        ],
      ),
    );
  }



void _importQRCode() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: const Text('Importer / Scanner QR Code', style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF3B82F6), width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: MobileScanner(
                controller: _scannerController,
                onDetect: (BarcodeCapture capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty) {
                    final String? rawValue = barcodes.first.rawValue;
                    if (rawValue != null && rawValue.isNotEmpty) {
                      Navigator.pop(context);
                      _handleQrData(rawValue);
                    }
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Scannez ou importez un QR Code de configuration\npour mettre à jour le système',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler', style: TextStyle(color: Colors.white70)),
        ),
    TextButton(
  onPressed: () async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      try {
        final result = await _scannerController.analyzeImage(image.path);

        if (result != null && result.barcodes.isNotEmpty) {
          final String? rawValue = result.barcodes.first.rawValue;
          if (rawValue != null) {
            Navigator.pop(context);
            _handleQrData(rawValue);
          }
        } else {
          print("❌ Aucun QR détecté dans l'image");
        }
      } catch (e) {
        print("Erreur import image QR: $e");
      }
    }
  },
  child: const Text('Importer', style: TextStyle(color: Color(0xFF3B82F6))),
),

      ],
    ),
  );
}

void _handleQrData(String data) async {
  try {
    final decoded = jsonDecode(data);
    print("✅ Données QR importées : $decoded");

    // Demander confirmation avant écrasement
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Confirmation", style: TextStyle(color: Colors.white)),
        content: const Text(
          "⚠️ Cette action va effacer les données actuelles et les remplacer par celles du QR Code.\n\nEs-tu sûr de vouloir continuer ?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler", style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF3B82F6)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Oui, continuer"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final regenerator = DatabaseRegenerator(
        kitRepo: KitRepository(DBService()),
        relayRepo: RelayRepository(DBService()),
        allowedRepo: AllowedNumberRepository(DBService()),
      );

      await regenerator.regenerateFromJson(data);

      _showImportSuccess(); // tu affiches ton succès ici
    }
  } catch (e) {
    print("⚠️ QR brut non JSON : $data");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Format QR invalide")),
    );
  }
}



  void _showImportSuccess() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Import Réussi!', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 60),
            const SizedBox(height: 16),
            const Text(
              'Configuration mise à jour avec succès',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Kit:', style: TextStyle(color: Colors.white70)),
                      Text('ENM-002', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Contrôleurs:', style: TextStyle(color: Colors.white70)),
                      Text('4 nouveaux', style: TextStyle(color: Color(0xFF10B981))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            onPressed: () {
              Navigator.pop(context);
              // Optionnel: redémarrer l'application ou recharger les données
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _kitController.dispose();
    _controllerController.dispose();
    super.dispose();
  }
}