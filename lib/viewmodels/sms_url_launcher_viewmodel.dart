import 'package:flutter/foundation.dart';
import 'package:enmkit/core/sms_url_launcher_service.dart';
import 'package:enmkit/models/relay_model.dart';

/// ViewModel pour gérer l'envoi de SMS via URL Launcher
/// Alternative au RelayViewModel classique
class SmsUrlLauncherViewModel extends ChangeNotifier {
  final SmsUrlLauncherService _smsUrlLauncherService;
  
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  SmsUrlLauncherViewModel(this._smsUrlLauncherService);

  /// Toggle un relais via URL Launcher
  Future<void> toggleRelay(RelayModel relay) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final success = await _smsUrlLauncherService.toggleRelay(relay);
      if (success) {
        _successMessage = 'Application SMS ouverte pour le relais ${relay.name}';
      } else {
        _errorMessage = 'Impossible d\'ouvrir l\'application SMS';
      }
    } catch (e) {
      _errorMessage = 'Erreur: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Demander la consommation via URL Launcher
  Future<void> requestConsumption() async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final success = await _smsUrlLauncherService.requestConsumption();
      if (success) {
        _successMessage = 'Application SMS ouverte pour demander la consommation';
      } else {
        _errorMessage = 'Impossible d\'ouvrir l\'application SMS';
      }
    } catch (e) {
      _errorMessage = 'Erreur: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Configurer le premier numéro via URL Launcher
  Future<void> setFirstPhoneNumber(String phone) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final success = await _smsUrlLauncherService.setFirstPhoneNumber(phone);
      if (success) {
        _successMessage = 'Application SMS ouverte pour configurer le numéro 1';
      } else {
        _errorMessage = 'Impossible d\'ouvrir l\'application SMS';
      }
    } catch (e) {
      _errorMessage = 'Erreur: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Configurer le second numéro via URL Launcher
  Future<void> setSecondPhoneNumber(String phone) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final success = await _smsUrlLauncherService.setSecondPhoneNumber(phone);
      if (success) {
        _successMessage = 'Application SMS ouverte pour configurer le numéro 2';
      } else {
        _errorMessage = 'Impossible d\'ouvrir l\'application SMS';
      }
    } catch (e) {
      _errorMessage = 'Erreur: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Configurer la consommation initiale via URL Launcher
  Future<void> setInitialConsumption(double consumption) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final success = await _smsUrlLauncherService.setInitialConsumption(consumption);
      if (success) {
        _successMessage = 'Application SMS ouverte pour configurer la consommation initiale';
      } else {
        _errorMessage = 'Impossible d\'ouvrir l\'application SMS';
      }
    } catch (e) {
      _errorMessage = 'Erreur: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Configurer la pulsation via URL Launcher
  Future<void> setPulsation(int pulsation) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final success = await _smsUrlLauncherService.setPulsation(pulsation);
      if (success) {
        _successMessage = 'Application SMS ouverte pour configurer la pulsation';
      } else {
        _errorMessage = 'Impossible d\'ouvrir l\'application SMS';
      }
    } catch (e) {
      _errorMessage = 'Erreur: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Envoyer la configuration complète via URL Launcher
  Future<void> sendCompleteConfiguration({
    String? firstPhone,
    String? secondPhone,
    double? initialConsumption,
    int? pulsation,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final success = await _smsUrlLauncherService.sendConcatenatedSystemConfig(
        firstPhone: firstPhone,
        secondPhone: secondPhone,
        initialConsumption: initialConsumption,
        pulsation: pulsation,
      );
      if (success) {
        _successMessage = 'Application SMS ouverte avec la configuration complète';
      } else {
        _errorMessage = 'Impossible d\'ouvrir l\'application SMS';
      }
    } catch (e) {
      _errorMessage = 'Erreur: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Appliquer la configuration via URL Launcher
  Future<void> applyConfiguration() async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final success = await _smsUrlLauncherService.applyConfiguration();
      if (success) {
        _successMessage = 'Application SMS ouverte pour finaliser la configuration';
      } else {
        _errorMessage = 'Impossible d\'ouvrir l\'application SMS';
      }
    } catch (e) {
      _errorMessage = 'Erreur: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Envoyer une commande personnalisée via URL Launcher
  Future<void> sendCustomCommand(String command) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final success = await _smsUrlLauncherService.sendCustomCommand(command);
      if (success) {
        _successMessage = 'Application SMS ouverte avec la commande personnalisée';
      } else {
        _errorMessage = 'Impossible d\'ouvrir l\'application SMS';
      }
    } catch (e) {
      _errorMessage = 'Erreur: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Ouvrir simplement l'application SMS
  Future<void> openSmsApp(String phoneNumber) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final success = await _smsUrlLauncherService.openSmsApp(phoneNumber);
      if (success) {
        _successMessage = 'Application SMS ouverte';
      } else {
        _errorMessage = 'Impossible d\'ouvrir l\'application SMS';
      }
    } catch (e) {
      _errorMessage = 'Erreur: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Réinitialiser les messages
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}