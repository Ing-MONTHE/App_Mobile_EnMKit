import 'package:enmkit/core/sms_service.dart';
import 'package:enmkit/repositories/allowed_number_repository.dart';
import 'package:enmkit/repositories/consumption_repository.dart';
import 'package:enmkit/repositories/kit_repository.dart';
import 'package:enmkit/viewmodels/allowedNumberViewmodel.dart' show AllowedNumberViewModel;
import 'package:enmkit/viewmodels/authViewModel.dart';
import 'package:enmkit/viewmodels/consumption_viewmodel.dart';
import 'package:enmkit/viewmodels/kitViewModel.dart';
import 'package:enmkit/viewmodels/onboarding_vm.dart';
import 'package:enmkit/viewmodels/relayViewmodel.dart';
import 'package:enmkit/viewmodels/smsViewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:enmkit/core/db_service.dart';
import 'package:enmkit/repositories/auth_repository.dart';


final onboardingVMProvider = ChangeNotifierProvider((ref) => OnboardingVM());
/// Provider pour DBService singleton
final dbServiceProvider = Provider<DBService>((ref) => DBService());

/// Provider pour AuthRepository
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.read(dbServiceProvider)),
);

final authProvider = StateNotifierProvider<AuthVM, AuthState>(
  (ref) => AuthVM(ref.read(authRepositoryProvider)),
);


// Instance du ViewModel des relais
final relaysProvider = ChangeNotifierProvider<RelayViewModel>((ref) {
  final dbService = DBService(); // Assurez-vous qu'il est singleton ou initialisé
  final kitRepo = KitRepository(dbService);
  final smsService = SmsService(kitRepo);
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
