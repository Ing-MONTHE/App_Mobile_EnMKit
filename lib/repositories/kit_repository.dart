import 'package:enmkit/core/db_service.dart';
import 'package:enmkit/models/kit_model.dart';

class KitRepository {
  final DBService _dbService;
  KitRepository(this._dbService);

  Future<void> addKit(KitModel kit) async {
    final db = await _dbService.database;
    await db.insert('kits', kit.toMap());
  }

  Future<List<KitModel>> getKit() async {
    final db = await _dbService.database;
    final kitMaps = await db.query('kits'); // SQLite natif
    return kitMaps.map((map) => KitModel.fromMap(map)).toList();
  }

  Future<void> updateKit(KitModel kit) async {
    final db = await _dbService.database;
    await db.update(
      'kits',
      kit.toMap(),
      where: 'kitNumber = ?',
      whereArgs: [kit.kitNumber],
    );
  }

  /// Change le numéro GSM (clé) d'un kit et répercute le changement sur toutes
  /// les entités rattachées (relais, consommations, numéros autorisés), dans
  /// une transaction. [updated] doit déjà porter le nouveau kitNumber.
  Future<void> changeKitNumber(String oldNumber, KitModel updated) async {
    final db = await _dbService.database;
    final newNumber = updated.kitNumber;
    await db.transaction((txn) async {
      await txn.update('kits', updated.toMap(),
          where: 'kitNumber = ?', whereArgs: [oldNumber]);
      for (final table in ['relays', 'consumptions', 'allowed_numbers']) {
        await txn.update(table, {'kitNumber': newNumber},
            where: 'kitNumber = ?', whereArgs: [oldNumber]);
      }
    });
  }

  Future<String?> getKitNumber() async {
    final db = await _dbService.database;
    final res = await db.query("kits", limit: 1);
    if (res.isNotEmpty) {
      return res.first['kitNumber'] as String;
    }
    return null;
  }


  /// Marque (ou démarque) un kit comme ayant reçu une configuration AVEC SUCCÈS
  /// — débloque le pilotage effectif des lignes.
  Future<void> markConfigSent(String kitNumber, {bool sent = true}) async {
    final db = await _dbService.database;
    await db.update(
      'kits',
      {'configured': sent ? 1 : 0},
      where: 'kitNumber = ?',
      whereArgs: [kitNumber],
    );
  }

  /// Mémorise la trame de configuration qui vient d'être ENVOYÉE au kit, en
  /// attente de son écho. Remet à zéro l'éventuelle validation pendante : une
  /// nouvelle configuration annule la précédente.
  Future<void> setPendingConfig(String kitNumber, String message) async {
    final db = await _dbService.database;
    await db.update(
      'kits',
      {'pendingConfigMsg': message, 'configAckPending': 0},
      where: 'kitNumber = ?',
      whereArgs: [kitNumber],
    );
  }

  /// L'écho du kit concorde : la configuration attend la validation de
  /// l'utilisateur. Idempotent — deux livraisons du même écho (flux `readsms`
  /// ET chemin natif) laissent le même état.
  Future<void> markConfigAckPending(String kitNumber) async {
    final db = await _dbService.database;
    await db.update(
      'kits',
      {'configAckPending': 1},
      where: 'kitNumber = ?',
      whereArgs: [kitNumber],
    );
  }

  /// Configuration close (« Fin_config » envoyé) : plus rien en attente, et le
  /// kit est marqué comme configuré.
  Future<void> clearPendingConfig(String kitNumber) async {
    final db = await _dbService.database;
    await db.update(
      'kits',
      {'pendingConfigMsg': null, 'configAckPending': 0, 'configured': 1},
      where: 'kitNumber = ?',
      whereArgs: [kitNumber],
    );
  }

   /// Supprime l'enregistrement existant
  Future<void> clearKit() async {
    final db = await _dbService.database;
    await db.delete('kits');
  }

  /// Supprime UN kit (par son numéro GSM, clé) ET toutes ses données rattachées
  /// — lignes, consommations (index et horaires), numéros autorisés, accusés,
  /// scénarios pédagogiques — dans une transaction,
  /// pour ne laisser aucun orphelin en base.
  Future<void> deleteKit(String kitNumber) async {
    final db = await _dbService.database;
    await db.transaction((txn) async {
      for (final table in [
        'relays',
        'consumptions',
        'allowed_numbers',
        'relay_acks',
        'hourly_consumptions',
        'edu_scenarios',
      ]) {
        await txn.delete(table, where: 'kitNumber = ?', whereArgs: [kitNumber]);
      }
      await txn.delete('kits', where: 'kitNumber = ?', whereArgs: [kitNumber]);
    });
  }
}
