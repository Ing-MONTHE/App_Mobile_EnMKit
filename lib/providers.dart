// import 'package:enmkit/core/sms_service.dart';
import 'package:enmkit/core/background_sms_bridge.dart';
import 'package:enmkit/core/biometric_service.dart';
import 'package:enmkit/core/qr_generate_database_service.dart';
import 'package:enmkit/core/qr_service.dart';
import 'package:enmkit/core/sms_inbox_processor.dart';
import 'package:enmkit/core/sms_service_hybrid.dart';
import 'package:enmkit/core/i18n/strings.dart';
import 'package:enmkit/repositories/access_repository.dart';
import 'package:enmkit/repositories/settings_repository.dart';
import 'package:enmkit/viewmodels/settings_viewmodel.dart';
import 'package:enmkit/repositories/allowed_number_repository.dart';
import 'package:enmkit/repositories/consumption_repository.dart';
import 'package:enmkit/repositories/kit_repository.dart';
import 'package:enmkit/repositories/relay_repository.dart';
import 'package:enmkit/viewmodels/access_viewmodel.dart';
import 'package:enmkit/viewmodels/allowed_number_viewmodel.dart' show AllowedNumberViewModel;
import 'package:enmkit/viewmodels/consumption_viewmodel.dart';
import 'package:enmkit/viewmodels/kit_viewmodel.dart';
import 'package:enmkit/viewmodels/onboarding_vm.dart';
import 'package:enmkit/viewmodels/relay_viewmodel.dart';
import 'package:enmkit/viewmodels/sms_viewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:enmkit/core/db_service.dart';
import 'package:enmkit/models/kit_model.dart';


final onboardingVMProvider = ChangeNotifierProvider((ref) => OnboardingVM());

/// Kit actuellement sélectionné dans l'app (navigation Liste → Détail).
/// Tous les écrans de détail (relais, conso, config) s'appuieront dessus
/// pour cibler le bon kit.
final selectedKitProvider = StateProvider<KitModel?>((ref) => null);
/// Provider pour DBService singleton
final dbServiceProvider = Provider<DBService>((ref) => DBService());

/// Provider pour KitRepository
final kitRepositoryProvider = Provider<KitRepository>(
  (ref) => KitRepository(ref.read(dbServiceProvider)),
);

/// Provider pour RelayRepository (utilisé hors écran détail, ex. seeding).
final relayRepositoryProvider = Provider<RelayRepository>(
  (ref) => RelayRepository(ref.read(dbServiceProvider)),
);

/// Repository du code d'accès (PIN).
final accessRepositoryProvider = Provider<AccessRepository>(
  (ref) => AccessRepository(ref.read(dbServiceProvider)),
);

/// Service de déverrouillage par empreinte (biométrie).
final biometricServiceProvider = Provider<BiometricService>(
  (ref) => BiometricService(),
);

/// ViewModel du code d'accès : gère le verrouillage de l'app par PIN.
final accessProvider = ChangeNotifierProvider<AccessViewModel>(
  (ref) => AccessViewModel(
    ref.read(accessRepositoryProvider),
    ref.read(biometricServiceProvider),
  ),
);

/// Repository des réglages (thème, langue, accent).
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.read(dbServiceProvider)),
);

/// ViewModel des réglages : thème / langue / couleur d'accent, persistés.
final settingsProvider = ChangeNotifierProvider<SettingsViewModel>(
  (ref) => SettingsViewModel(ref.read(settingsRepositoryProvider)),
);

/// Traducteur courant, dérivé de la langue choisie dans les réglages.
/// Les écrans font `final t = ref.watch(tProvider)` puis `t.t('clé')`.
final tProvider = Provider<AppStrings>((ref) {
  final locale = ref.watch(settingsProvider).settings.locale;
  return AppStrings(locale);
});


// Instance du ViewModel des relais
final relaysProvider = ChangeNotifierProvider<RelayViewModel>((ref) {
  final dbService = DBService(); // Assurez-vous qu'il est singleton ou initialisé
  final kitRepo = KitRepository(dbService);
  final smsService = SmsServiceHybrid(kitRepo);
  return RelayViewModel(dbService, smsService);
});

// Provider pour KitViewModel
final kitProvider = ChangeNotifierProvider<KitViewModel>((ref) {
  final dbService = DBService(); // Assurez-vous que c'est singleton ou correctement initialisé
  return KitViewModel(dbService);
});

// Provider pour ConsumptionViewModel
final consumptionProvider = ChangeNotifierProvider<ConsumptionViewModel>((ref) {
  final dbService = ref.read(dbServiceProvider);
  final repo = ConsumptionRepository(dbService);
  // Initialise et charge immédiatement l'historique depuis SQLite
  final vm = ConsumptionViewModel(repo);
  vm.fetchConsumptions();
  return vm;
});


/// Provider pour AllowedNumberViewModel
final allowedNumberProvider = ChangeNotifierProvider<AllowedNumberViewModel>((ref) {
  final dbService = DBService(); // Assure-toi qu'il est singleton
  final repo = AllowedNumberRepository(dbService);
  return AllowedNumberViewModel(repo);
});



final smsListenerProvider = ChangeNotifierProvider<SmsListenerViewModel>((ref) {
  final kitNumber = ref.watch(kitProvider).kits.isNotEmpty ? ref.watch(kitProvider).kits.first.kitNumber : null;
  final consumptionVm = ref.read(consumptionProvider);
  return SmsListenerViewModel(kitNumber: kitNumber, consumptionVM: consumptionVm);
});

final smsServiceProvider = Provider<SmsServiceHybrid>((ref) {
  final dbService = ref.watch(dbServiceProvider);
  final kitRepo = KitRepository(dbService);
  return SmsServiceHybrid(kitRepo);
});

/// ============================================================================
/// Providers SCOPÉS PAR KIT (multi-kits) — paramétrés par le numéro du kit.
/// Les écrans de détail d'un kit consomment ces `.family` avec le numéro du
/// kit sélectionné (`selectedKitProvider`), garantissant des données isolées
/// par kit (relais, consommation, numéros autorisés, SMS).
/// ============================================================================

/// Service SMS ciblant un kit précis.
final kitSmsServiceProvider = Provider.family<SmsServiceHybrid, String?>((ref, kitNumber) {
  final dbService = ref.watch(dbServiceProvider);
  final kitRepo = KitRepository(dbService);
  return SmsServiceHybrid(kitRepo, kitNumber: kitNumber);
});

/// Service de génération de QR Code (export d'un kit).
final qrServiceProvider = Provider<QrService>((ref) {
  final db = ref.watch(dbServiceProvider);
  return QrService(
    kitRepo: KitRepository(db),
    relayRepo: RelayRepository(db),
    allowedRepo: AllowedNumberRepository(db),
  );
});

/// Régénérateur de base depuis un QR Code (import multi-kits sûr).
final dbRegeneratorProvider = Provider<DatabaseRegenerator>((ref) {
  final db = ref.watch(dbServiceProvider);
  return DatabaseRegenerator(
    kitRepo: KitRepository(db),
    relayRepo: RelayRepository(db),
    allowedRepo: AllowedNumberRepository(db),
  );
});

/// Pont natif pour la réception des SMS en arrière-plan.
final backgroundSmsBridgeProvider =
    Provider<BackgroundSmsBridge>((ref) => BackgroundSmsBridge());

/// Processeur des SMS entrants drainés (conso/ACK → base, par kit).
final smsInboxProcessorProvider = Provider<SmsInboxProcessor>((ref) {
  final db = ref.watch(dbServiceProvider);
  return SmsInboxProcessor(
    kitRepo: KitRepository(db),
    consumptionRepo: ConsumptionRepository(db),
    relayRepo: RelayRepository(db),
  );
});

/// Relais d'un kit donné.
final kitRelaysProvider =
    ChangeNotifierProvider.family<RelayViewModel, String?>((ref, kitNumber) {
  final dbService = ref.watch(dbServiceProvider);
  final kitRepo = KitRepository(dbService);
  final smsService = SmsServiceHybrid(kitRepo, kitNumber: kitNumber);
  return RelayViewModel(dbService, smsService, kitNumber: kitNumber);
});

/// Consommation d'un kit donné.
final kitConsumptionProvider =
    ChangeNotifierProvider.family<ConsumptionViewModel, String?>((ref, kitNumber) {
  final dbService = ref.watch(dbServiceProvider);
  final repo = ConsumptionRepository(dbService);
  final vm = ConsumptionViewModel(repo, kitNumber: kitNumber);
  vm.fetchConsumptions();
  return vm;
});

/// Numéros autorisés d'un kit donné.
final kitAllowedNumbersProvider =
    ChangeNotifierProvider.family<AllowedNumberViewModel, String?>((ref, kitNumber) {
  final dbService = ref.watch(dbServiceProvider);
  final repo = AllowedNumberRepository(dbService);
  return AllowedNumberViewModel(repo, kitNumber: kitNumber);
});

/// Écoute SMS filtrée sur le numéro d'un kit donné, alimentant sa consommation.
final kitSmsListenerProvider =
    ChangeNotifierProvider.family<SmsListenerViewModel, String?>((ref, kitNumber) {
  final consumptionVm = ref.read(kitConsumptionProvider(kitNumber));
  return SmsListenerViewModel(kitNumber: kitNumber, consumptionVM: consumptionVm);
});
