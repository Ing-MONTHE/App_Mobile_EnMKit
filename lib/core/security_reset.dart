import 'package:enmkit/core/db_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sqflite/sqflite.dart';

/// Réinitialise le CODE SECRET (et seulement lui) à chaque (ré)installation ou
/// mise à jour de l'application.
///
/// Principe : Android impose d'augmenter le `versionCode` pour qu'une mise à
/// jour s'installe — c'est donc un signal fiable et automatique. On mémorise la
/// dernière version de build vue (table `app_meta`). Si elle a changé depuis le
/// dernier lancement, on efface le PIN et ses questions mémo, on désactive le
/// verrouillage et on ré-affiche la proposition de code.
///
/// IMPORTANT : TOUTES les autres données (kits, lignes, accusés, consommation,
/// réglages d'apparence, onboarding) sont CONSERVÉES — seule la sécurité est
/// réinitialisée.
class SecurityResetService {
  SecurityResetService(this._dbService);
  final DBService _dbService;

  static const String _buildKey = 'appBuild';

  Future<void> resetPinIfBuildChanged() async {
    final db = await _dbService.database;

    // Filet de sécurité si la table n'existe pas encore (anciennes installs).
    await db.execute(
        'CREATE TABLE IF NOT EXISTS app_meta(key TEXT PRIMARY KEY, value TEXT)');

    final info = await PackageInfo.fromPlatform();
    final current = '${info.version}+${info.buildNumber}'; // ex. « 1.0.0+2 »

    final rows = await db.query('app_meta',
        where: 'key = ?', whereArgs: [_buildKey], limit: 1);
    final stored = rows.isEmpty ? null : rows.first['value'] as String?;

    // Même build qu'au dernier lancement : rien à faire.
    if (stored == current) return;

    // (Ré)installation/mise à jour détectée → on réinitialise UNIQUEMENT la
    // sécurité. (Sur une toute première installation, ces opérations sont des
    // no-op : il n'y a pas encore de PIN ni de réglages.)
    await db.delete('app_security'); // supprime PIN + sel + questions mémo

    final hasSettings =
        (await db.query('app_settings', where: 'id = 1', limit: 1)).isNotEmpty;
    if (hasSettings) {
      await db.update(
        'app_settings',
        {
          'securityCodeEnabled': 0, // plus de verrouillage au démarrage
          'securityPromptSeen': 0, // ré-affiche la proposition de code
          'biometricEnabled': 0, // l'empreinte sans PIN n'a pas de sens
        },
        where: 'id = 1',
      );
    }

    // Mémorise la version courante pour ne réinitialiser qu'UNE fois par build.
    await db.insert(
      'app_meta',
      {'key': _buildKey, 'value': current},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
