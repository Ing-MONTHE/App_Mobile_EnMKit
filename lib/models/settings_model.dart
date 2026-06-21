import 'package:flutter/material.dart';

/// Réglages de l'application : thème, langue, couleur d'accent.
class SettingsModel {
  final ThemeMode themeMode;
  final String locale; // 'fr' | 'en'
  final String accent; // clé d'accent (voir AppTheme.accents)
  final bool onboardingSeen; // tutoriel d'accueil déjà vu ?
  final bool securityCodeEnabled; // code d'accès (PIN) activé à l'ouverture ?
  final bool securityPromptSeen; // proposition de code (skippable) déjà présentée ?
  final bool biometricEnabled; // déverrouillage rapide par empreinte activé ?

  const SettingsModel({
    this.themeMode = ThemeMode.system,
    this.locale = 'fr',
    this.accent = 'indigo',
    this.onboardingSeen = false,
    this.securityCodeEnabled = false,
    this.securityPromptSeen = false,
    this.biometricEnabled = false,
  });

  SettingsModel copyWith({
    ThemeMode? themeMode,
    String? locale,
    String? accent,
    bool? onboardingSeen,
    bool? securityCodeEnabled,
    bool? securityPromptSeen,
    bool? biometricEnabled,
  }) {
    return SettingsModel(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      accent: accent ?? this.accent,
      onboardingSeen: onboardingSeen ?? this.onboardingSeen,
      securityCodeEnabled: securityCodeEnabled ?? this.securityCodeEnabled,
      securityPromptSeen: securityPromptSeen ?? this.securityPromptSeen,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': 1,
        'themeMode': themeMode.name,
        'locale': locale,
        'accent': accent,
        'onboardingSeen': onboardingSeen ? 1 : 0,
        'securityCodeEnabled': securityCodeEnabled ? 1 : 0,
        'securityPromptSeen': securityPromptSeen ? 1 : 0,
        'biometricEnabled': biometricEnabled ? 1 : 0,
      };

  factory SettingsModel.fromMap(Map<String, dynamic> map) {
    return SettingsModel(
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == map['themeMode'],
        orElse: () => ThemeMode.system,
      ),
      locale: (map['locale'] as String?) ?? 'fr',
      accent: (map['accent'] as String?) ?? 'indigo',
      onboardingSeen: (map['onboardingSeen'] ?? 0) == 1,
      securityCodeEnabled: (map['securityCodeEnabled'] ?? 0) == 1,
      securityPromptSeen: (map['securityPromptSeen'] ?? 0) == 1,
      biometricEnabled: (map['biometricEnabled'] ?? 0) == 1,
    );
  }
}
