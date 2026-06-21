import 'package:enmkit/core/db_service.dart';
import 'package:enmkit/models/settings_model.dart';
import 'package:sqflite/sqflite.dart';

/// Persiste les réglages de l'app (ligne unique id=1) dans SQLite.
class SettingsRepository {
  final DBService _dbService;
  SettingsRepository(this._dbService);

  Future<SettingsModel> load() async {
    final db = await _dbService.database;
    final res = await db.query('app_settings', where: 'id = 1', limit: 1);
    if (res.isEmpty) return const SettingsModel();
    return SettingsModel.fromMap(res.first);
  }

  Future<void> save(SettingsModel settings) async {
    final db = await _dbService.database;
    await db.insert(
      'app_settings',
      settings.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
