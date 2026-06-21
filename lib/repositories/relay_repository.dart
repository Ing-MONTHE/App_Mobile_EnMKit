import 'package:enmkit/core/constants/defaults.dart';
import 'package:enmkit/core/db_service.dart';
import 'package:enmkit/models/relay_ack_model.dart';
import 'package:enmkit/models/relay_model.dart';
import 'package:sqflite/sqflite.dart';

class RelayRepository {
  final DBService _dbService;
  RelayRepository(this._dbService);

  // Ajouter un relais
  Future<void> addRelay(RelayModel relay) async {
    final db = await _dbService.database;
    await db.insert('relays', relay.toMap());
  }

  /// Crée [count] lignes (« Ligne 1 »…« Ligne N ») pour un nouveau kit.
  /// [count] est borné entre 1 et [DefaultData.maxRelaysPerKit].
  Future<void> seedLines(String kitNumber, int count) async {
    final db = await _dbService.database;
    final n = count.clamp(1, DefaultData.maxRelaysPerKit);
    for (var i = 1; i <= n; i++) {
      await db.insert('relays', {
        'name': 'Ligne $i',
        'isActive': 0,
        'amperage': DefaultData.defaultAmperage,
        'ackReceived': 0,
        'kitNumber': kitNumber,
      });
    }
  }

  // Récupérer tous les relais (filtrés par kit si [kitNumber] est fourni)
  Future<List<RelayModel>> getAllRelays({String? kitNumber}) async {
    final db = await _dbService.database;
    final maps = kitNumber == null
        ? await db.query('relays')
        : await db.query('relays', where: 'kitNumber = ?', whereArgs: [kitNumber]);
    return maps.map((m) => RelayModel.fromMap(m)).toList();
  }

  // Mettre à jour un relais complet
  Future<void> updateRelay(RelayModel relay) async {
    final db = await _dbService.database;
    await db.update(
      'relays',
      relay.toMap(),
      where: 'id = ?',
      whereArgs: [relay.id],
    );
  }

  Future<void> updateRelayAck(int id, bool ackReceived) async {
    final db = await _dbService.database;
    await db.update(
      'relays',
      {'ackReceived': ackReceived ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Applique l'accusé renvoyé par le kit : reflète l'état réel ON/OFF de la
  /// ligne ET marque l'ACK comme reçu. Scopé au kit si [kitNumber] est fourni,
  /// pour éviter toute confusion entre kits partageant un même id de ligne.
  Future<void> applyKitAck(int id,
      {required bool isActive, String? kitNumber}) async {
    final db = await _dbService.database;
    final where = kitNumber == null ? 'id = ?' : 'id = ? AND kitNumber = ?';
    final args = kitNumber == null ? [id] : [id, kitNumber];
    await db.update(
      'relays',
      {'isActive': isActive ? 1 : 0, 'ackReceived': 1},
      where: where,
      whereArgs: args,
    );
  }

  // Modifier uniquement le nom du relais
  Future<void> updateRelayName(int id, String newName) async {
    final db = await _dbService.database;
    await db.update(
      'relays',
      {'name': newName},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Supprimer un relais (et son historique d'accusés)
  Future<void> deleteRelay(int id) async {
    final db = await _dbService.database;
    await db.delete(
      'relays',
      where: 'id = ?',
      whereArgs: [id],
    );
    await db.delete('relay_acks', where: 'relayId = ?', whereArgs: [id]);
  }

    /// Supprime tous les relais (d'un kit si [kitNumber] est fourni)
  Future<void> clearRelays({String? kitNumber}) async {
    final db = await _dbService.database;
    if (kitNumber == null) {
      await db.delete('relays');
    } else {
      await db.delete('relays', where: 'kitNumber = ?', whereArgs: [kitNumber]);
    }
  }

  /// Retourne le nombre de relais actifs (d'un kit si [kitNumber] est fourni)
  Future<int> getActiveRelaysCount({String? kitNumber}) async {
    final db = await _dbService.database;
    final result = kitNumber == null
        ? await db.rawQuery('SELECT COUNT(*) as count FROM relays WHERE isActive = 1')
        : await db.rawQuery(
            'SELECT COUNT(*) as count FROM relays WHERE isActive = 1 AND kitNumber = ?',
            [kitNumber],
          );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // --- Historique des accusés de réception ----------------------------------

  /// Journalise un accusé horodaté pour une ligne (état réel confirmé par le
  /// kit), avec le texte brut du SMS reçu.
  ///
  /// Écrivain UNIQUE : seul le chemin natif d'arrière-plan (SmsInboxProcessor)
  /// appelle cette méthode. Le natif draine chaque SMS exactement une fois (file
  /// SharedPreferences vidée de façon atomique, cf. SmsStore.drain @Synchronized)
  /// et un SMS entrant ne déclenche qu'un seul enqueue. Aucune déduplication
  /// n'est donc nécessaire — et surtout, rejouer la MÊME commande produit un
  /// nouvel accusé qui DOIT être capturé à chaque fois (c'était le bug : une
  /// fenêtre anti-doublon écrasait les répétitions).
  Future<void> addAck(RelayAck ack) async {
    final db = await _dbService.database;
    await db.insert('relay_acks', ack.toMap());
  }

  /// Historique des accusés d'une ligne, du plus récent au plus ancien.
  /// Limité à [limit] entrées pour rester léger.
  Future<List<RelayAck>> getAcksForRelay(int relayId, {int limit = 50}) async {
    final db = await _dbService.database;
    final maps = await db.query(
      'relay_acks',
      where: 'relayId = ?',
      whereArgs: [relayId],
      orderBy: 'at DESC',
      limit: limit,
    );
    return maps.map((m) => RelayAck.fromMap(m)).toList();
  }

  /// Tous les accusés d'un kit (du plus récent au plus ancien), pour alimenter
  /// l'historique de chaque ligne en une seule requête.
  Future<List<RelayAck>> getAcksForKit(String? kitNumber, {int limit = 300}) async {
    final db = await _dbService.database;
    final maps = kitNumber == null
        ? await db.query('relay_acks', orderBy: 'at DESC', limit: limit)
        : await db.query(
            'relay_acks',
            where: 'kitNumber = ?',
            whereArgs: [kitNumber],
            orderBy: 'at DESC',
            limit: limit,
          );
    return maps.map((m) => RelayAck.fromMap(m)).toList();
  }

  /// Supprime l'historique d'une ligne (purge à la suppression de la ligne).
  Future<void> clearAcksForRelay(int relayId) async {
    final db = await _dbService.database;
    await db.delete('relay_acks', where: 'relayId = ?', whereArgs: [relayId]);
  }

  /// Retourne le nombre de relais inactifs (d'un kit si [kitNumber] est fourni)
  Future<int> getInactiveRelaysCount({String? kitNumber}) async {
    final db = await _dbService.database;
    final result = kitNumber == null
        ? await db.rawQuery('SELECT COUNT(*) as count FROM relays WHERE isActive = 0')
        : await db.rawQuery(
            'SELECT COUNT(*) as count FROM relays WHERE isActive = 0 AND kitNumber = ?',
            [kitNumber],
          );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
