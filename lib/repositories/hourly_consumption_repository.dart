import 'package:enmkit/core/db_service.dart';
import 'package:enmkit/core/utils/sms_parser.dart';
import 'package:enmkit/models/hourly_consumption_model.dart';
import 'package:sqflite/sqflite.dart';

/// Accès aux relevés HORAIRES (`hourly_consumptions`).
///
/// Idempotence (contrat §2) : clé unique (kitNumber, hourStart). Une nouvelle
/// valeur pour la même heure REMPLACE l'ancienne (« dernier reçu gagne »). Le
/// même SMS capté par les deux chemins (temps réel `readsms` + drain natif)
/// aboutit donc exactement au même état, sans doublon.
class HourlyConsumptionRepository {
  final DBService _dbService;
  HourlyConsumptionRepository(this._dbService);

  static const String table = 'hourly_consumptions';

  /// Enregistre (ou remplace) les [frames] du kit [kitNumber]. Retourne le
  /// nombre de trames écrites.
  ///
  /// `INSERT OR REPLACE` plutôt que `ON CONFLICT … DO UPDATE` : cette syntaxe
  /// d'upsert exige SQLite ≥ 3.24, absent des Android anciens (API < 30).
  Future<int> upsertFrames(
    String kitNumber,
    List<HourlyFrame> frames, {
    DateTime? receivedAt,
  }) async {
    if (frames.isEmpty || kitNumber.isEmpty) return 0;
    final db = await _dbService.database;
    final at = (receivedAt ?? DateTime.now()).toIso8601String();
    final batch = db.batch();
    for (final f in frames) {
      batch.insert(
        table,
        {
          'kitNumber': kitNumber,
          'hourStart': f.hourKey,
          'kWh': f.kwh,
          'receivedAt': at,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    return frames.length;
  }

  /// Relevés horaires d'un kit, triés chronologiquement. [from] / [to] sont
  /// des bornes inclusives sur l'heure de début (optionnelles).
  Future<List<HourlyConsumptionModel>> getHourly(
    String kitNumber, {
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await _dbService.database;
    final where = StringBuffer('kitNumber = ?');
    final args = <Object>[kitNumber];
    // Les clés `YYYY-MM-DDTHH:00:00` se comparent correctement en texte.
    if (from != null) {
      where.write(' AND hourStart >= ?');
      args.add(HourlyFrame.hourKeyOf(from));
    }
    if (to != null) {
      where.write(' AND hourStart <= ?');
      args.add(HourlyFrame.hourKeyOf(to));
    }
    final rows = await db.query(
      table,
      where: where.toString(),
      whereArgs: args,
      orderBy: 'hourStart ASC',
    );
    return rows.map(HourlyConsumptionModel.fromMap).toList();
  }

  /// Nombre total de relevés horaires d'un kit.
  Future<int> count(String kitNumber) async {
    final db = await _dbService.database;
    final res = await db.rawQuery(
        'SELECT COUNT(*) AS n FROM $table WHERE kitNumber = ?', [kitNumber]);
    return (res.first['n'] as int?) ?? 0;
  }

  /// Supprime tous les relevés horaires d'un kit (ex. suppression du kit).
  Future<void> deleteForKit(String kitNumber) async {
    final db = await _dbService.database;
    await db.delete(table, where: 'kitNumber = ?', whereArgs: [kitNumber]);
  }
}
