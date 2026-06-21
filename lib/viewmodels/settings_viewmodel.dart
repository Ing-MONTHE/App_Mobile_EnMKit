import 'package:enmkit/models/settings_model.dart';
import 'package:enmkit/repositories/settings_repository.dart';
import 'package:flutter/material.dart';

/// ViewModel des réglages : charge, expose et persiste thème / langue / accent.
class SettingsViewModel extends ChangeNotifier {
  final SettingsRepository _repository;

  SettingsModel _settings = const SettingsModel();
  SettingsModel get settings => _settings;

  bool _loaded = false;
  bool get loaded => _loaded;

  SettingsViewModel(this._repository) {
    _init();
  }

  Future<void> _init() async {
    _settings = await _repository.load();
    _loaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _settings = _settings.copyWith(themeMode: mode);
    notifyListeners();
    await _repository.save(_settings);
  }

  Future<void> setLocale(String locale) async {
    _settings = _settings.copyWith(locale: locale);
    notifyListeners();
    await _repository.save(_settings);
  }

  Future<void> setAccent(String accent) async {
    _settings = _settings.copyWith(accent: accent);
    notifyListeners();
    await _repository.save(_settings);
  }

  /// Marque le tutoriel d'accueil comme vu (ne sera plus affiché).
  Future<void> setOnboardingSeen() async {
    _settings = _settings.copyWith(onboardingSeen: true);
    notifyListeners();
    await _repository.save(_settings);
  }

  /// Active ou désactive le code de sécurité à l'ouverture de l'app.
  Future<void> setSecurityCodeEnabled(bool enabled) async {
    _settings = _settings.copyWith(
      securityCodeEnabled: enabled,
      // Sans code, le déverrouillage par empreinte n'a plus de sens.
      biometricEnabled: enabled ? null : false,
    );
    notifyListeners();
    await _repository.save(_settings);
  }

  /// Active ou désactive le déverrouillage rapide par empreinte.
  Future<void> setBiometricEnabled(bool enabled) async {
    _settings = _settings.copyWith(biometricEnabled: enabled);
    notifyListeners();
    await _repository.save(_settings);
  }

  /// Clôt la proposition de code du 1er lancement (skippable) : marque la
  /// proposition comme vue et fixe l'état de la sécurité ([enabled] = true si
  /// l'utilisateur a créé un code, false s'il a choisi « Passer »).
  Future<void> completeSecurityPrompt({required bool enabled}) async {
    _settings = _settings.copyWith(
      securityCodeEnabled: enabled,
      securityPromptSeen: true,
    );
    notifyListeners();
    await _repository.save(_settings);
  }
}
