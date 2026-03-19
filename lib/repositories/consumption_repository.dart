import 'package:enmkit/core/db_service.dart';
import 'package:enmkit/models/consumption_model.dart';

class ConsumptionRepository {
  final DBService _dbService;
  ConsumptionRepository(this._dbService);

  // Ajouter une consommation
  Future<void> addConsumption(ConsumptionModel consumption) async {
    final db = await _dbService.database;
    // Respecte le schéma SQLite (colonne 'kWh')
    await db.insert('consumptions', {
      'kWh': consumption.kwh,
      'timestamp': consumption.timestamp.toIso8601String(),
    });
  }

  // Récupérer toutes les consommations
  Future<List<ConsumptionModel>> getAllConsumptions() async {
    final db = await _dbService.database;
    // Alias pour rendre la clé compatible avec le modèle ('kwh')
    final maps = await db.rawQuery('SELECT kWh AS kwh, timestamp FROM consumptions');
    return maps.map((m) => ConsumptionModel.fromMap(m)).toList();
  }

  // Mettre à jour une consommation (ex: par timestamp)
  Future<void> updateConsumption(ConsumptionModel consumption) async {
    final db = await _dbService.database;
    await db.update(
      'consumptions',
      consumption.toMap(),
      where: 'timestamp = ?',
      whereArgs: [consumption.timestamp.toIso8601String()],
    );
  }

  // Supprimer une consommation (ex: par timestamp)
  Future<void> deleteConsumption(DateTime timestamp) async {
    final db = await _dbService.database;
    await db.delete(
      'consumptions',
      where: 'timestamp = ?',
      whereArgs: [timestamp.toIso8601String()],
    );
  }
}
