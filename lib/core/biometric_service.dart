import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

/// Enveloppe le plugin `local_auth` pour le déverrouillage rapide par empreinte.
///
/// Usage volontairement minimal : savoir si la biométrie est exploitable, et
/// lancer l'invite système. Aucune donnée biométrique ne transite par l'app —
/// c'est le système qui authentifie.
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Vrai si l'appareil possède un capteur biométrique exploitable ET qu'au
  /// moins une empreinte/visage est enrôlé.
  Future<bool> isAvailable() async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      if (!await _auth.canCheckBiometrics) return false;
      final available = await _auth.getAvailableBiometrics();
      return available.isNotEmpty;
    } on PlatformException {
      return false;
    }
  }

  /// Lance l'invite biométrique. Renvoie `true` si l'utilisateur est authentifié.
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'Déverrouillage EnMKit',
            cancelButton: 'Annuler',
            biometricHint: '',
          ),
        ],
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }
}
