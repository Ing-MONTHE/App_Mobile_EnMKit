import 'package:enmkit/core/db_service.dart';
import 'package:enmkit/models/server_config_model.dart';
import 'package:sqflite/sqflite.dart';

/// Persiste la configuration optionnelle du serveur EnMKit (ligne unique).
class ServerConfigRepository {
  final DBService _dbService;
  ServerConfigRepository(this._dbService);

  Future<ServerConfig> load() async {
    final db = await _dbService.database;
    final rows = await db.query('server_settings', where: 'id = 1', limit: 1);
    if (rows.isEmpty) return const ServerConfig();
    return ServerConfig.fromMap(rows.first);
  }

  Future<void> save(ServerConfig config) async {
    final db = await _dbService.database;
    await db.insert('server_settings', config.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> clear() async {
    final db = await _dbService.database;
    await db.delete('server_settings');
  }
}
