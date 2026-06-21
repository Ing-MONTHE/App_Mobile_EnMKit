import 'package:enmkit/core/biometric_service.dart';
import 'package:enmkit/repositories/access_repository.dart';
import 'package:flutter/foundation.dart';

/// Étapes possibles du flux de code d'accès.
enum AccessStatus {
  /// On ne sait pas encore si un PIN existe (chargement initial).
  unknown,

  /// Aucun PIN défini → 1er lancement, l'utilisateur doit en créer un.
  needsSetup,

  /// PIN créé, mais les questions mémo de récupération restent à configurer.
  needsRecoverySetup,

  /// Un PIN existe mais l'utilisateur n'est pas encore entré.
  locked,

  /// PIN validé : accès autorisé.
  unlocked,
}

/// ViewModel du code d'accès (PIN), des questions mémo de récupération et du
/// déverrouillage rapide par empreinte.
class AccessViewModel extends ChangeNotifier {
  final AccessRepository _repository;
  final BiometricService _biometric;

  AccessViewModel(this._repository, this._biometric) {
    _init();
  }

  AccessStatus _status = AccessStatus.unknown;
  AccessStatus get status => _status;

  String? _error;
  String? get error => _error;

  bool _busy = false;
  bool get busy => _busy;

  Future<void> _init() async {
    final has = await _repository.hasPin();
    _status = has ? AccessStatus.locked : AccessStatus.needsSetup;
    notifyListeners();
  }

  /// Crée le code au 1er lancement (avec confirmation). En cas de succès, passe
  /// à [AccessStatus.needsRecoverySetup] : les questions mémo doivent être
  /// configurées juste après (récupération garantie dès la création).
  Future<void> createPin(String pin, String confirm) async {
    _error = null;
    if (pin.length < 4) {
      _error = 'Le code doit contenir au moins 4 chiffres';
      notifyListeners();
      return;
    }
    if (pin != confirm) {
      _error = 'Les deux codes ne correspondent pas';
      notifyListeners();
      return;
    }
    _busy = true;
    notifyListeners();
    await _repository.setPin(pin);
    _busy = false;
    _status = AccessStatus.needsRecoverySetup;
    notifyListeners();
  }

  /// Finalise la création une fois les questions mémo enregistrées.
  void finishRecoverySetup() {
    _status = AccessStatus.unlocked;
    notifyListeners();
  }

  /// Vérifie le code saisi à l'ouverture.
  Future<void> unlock(String pin) async {
    _error = null;
    _busy = true;
    notifyListeners();
    final ok = await _repository.verifyPin(pin);
    _busy = false;
    if (ok) {
      _status = AccessStatus.unlocked;
    } else {
      _error = 'Code incorrect';
    }
    notifyListeners();
  }

  /// Change le code (depuis les réglages) : vérifie l'ancien puis pose le nouveau.
  /// Le sel étant préservé, les questions mémo restent valides.
  Future<bool> changePin(String oldPin, String newPin, String confirm) async {
    _error = null;
    if (!await _repository.verifyPin(oldPin)) {
      _error = 'Ancien code incorrect';
      notifyListeners();
      return false;
    }
    if (newPin.length < 4) {
      _error = 'Le nouveau code doit contenir au moins 4 chiffres';
      notifyListeners();
      return false;
    }
    if (newPin != confirm) {
      _error = 'Les deux codes ne correspondent pas';
      notifyListeners();
      return false;
    }
    await _repository.setPin(newPin);
    notifyListeners();
    return true;
  }

  /// Active la sécurité depuis les réglages : crée le code (les questions mémo
  /// sont ensuite proposées par l'écran appelant).
  Future<bool> setupSecurity(String pin, String confirm) async {
    _error = null;
    if (pin.length < 4) {
      _error = 'Le code doit contenir au moins 4 chiffres';
      notifyListeners();
      return false;
    }
    if (pin != confirm) {
      _error = 'Les deux codes ne correspondent pas';
      notifyListeners();
      return false;
    }
    await _repository.setPin(pin);
    _status = AccessStatus.unlocked;
    notifyListeners();
    return true;
  }

  /// Désactive la sécurité depuis les réglages : vérifie le code puis l'efface.
  Future<bool> disableSecurity(String pin) async {
    _error = null;
    if (!await _repository.verifyPin(pin)) {
      _error = 'Code incorrect';
      notifyListeners();
      return false;
    }
    await _repository.clearPin();
    _status = AccessStatus.needsSetup;
    notifyListeners();
    return true;
  }

  // --- Questions mémo (récupération) ----------------------------------------

  Future<bool> hasSecurityQuestions() => _repository.hasSecurityQuestions();

  Future<List<String>?> securityQuestionKeys() =>
      _repository.getSecurityQuestionKeys();

  /// Enregistre les deux questions + réponses. Renvoie false avec un message si
  /// une réponse est vide ou si la même question est choisie deux fois.
  Future<bool> setupSecurityQuestions(
      String q1, String a1, String q2, String a2) async {
    _error = null;
    if (q1 == q2) {
      _error = 'Choisissez deux questions différentes';
      notifyListeners();
      return false;
    }
    if (a1.trim().isEmpty || a2.trim().isEmpty) {
      _error = 'Les deux réponses sont requises';
      notifyListeners();
      return false;
    }
    await _repository.setSecurityQuestions(q1, a1, q2, a2);
    notifyListeners();
    return true;
  }

  /// Récupération : vérifie les réponses puis pose un nouveau code.
  Future<bool> resetPinWithAnswers(
      String a1, String a2, String newPin, String confirm) async {
    _error = null;
    if (newPin.length < 4) {
      _error = 'Le nouveau code doit contenir au moins 4 chiffres';
      notifyListeners();
      return false;
    }
    if (newPin != confirm) {
      _error = 'Les deux codes ne correspondent pas';
      notifyListeners();
      return false;
    }
    if (!await _repository.verifySecurityAnswers(a1, a2)) {
      _error = 'Réponses incorrectes';
      notifyListeners();
      return false;
    }
    await _repository.setPin(newPin);
    _status = AccessStatus.unlocked;
    notifyListeners();
    return true;
  }

  // --- Empreinte (déverrouillage rapide) ------------------------------------

  /// Vrai si l'appareil peut proposer la biométrie (capteur + empreinte enrôlée).
  Future<bool> biometricAvailable() => _biometric.isAvailable();

  /// Tente un déverrouillage par empreinte. Renvoie true si authentifié.
  Future<bool> unlockWithBiometric(String reason) async {
    final ok = await _biometric.authenticate(reason);
    if (ok) {
      _status = AccessStatus.unlocked;
      _error = null;
      notifyListeners();
    }
    return ok;
  }

  /// Reverrouille l'application (ex. retour en arrière-plan).
  void lock() {
    _status = AccessStatus.locked;
    _error = null;
    notifyListeners();
  }

  /// Efface le message d'erreur courant.
  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }
}
