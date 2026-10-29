// Migration réelle v16 -> v17 : une base existante (v16) est ouverte par
// DBService ; seules les nouvelles tables doivent apparaître, les données
// existantes restant intactes.

import 'dart:io';

import 'package:enmkit/core/db_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test('onUpgrade 16 -> 17 crée les tables v17 sans toucher l\'existant',
      () async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // Dossier propre à ce fichier : les fichiers de test tournent en parallèle.
    await databaseFactory.setDatabasesPath(
        Directory.systemTemp.createTempSync('enmkit_mig_').path);
    final path = p.join(await getDatabasesPath(), 'kit_control.db');
    await databaseFactory.deleteDatabase(path);

    // Base « v16 » minimale avec une donnée existante.
    final old = await openDatabase(path, version: 16, onCreate: (db, v) async {
      await db.execute(
          'CREATE TABLE consumptions (id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'kWh REAL NOT NULL, timestamp TEXT NOT NULL, kitNumber TEXT)');
      await db.insert('consumptions',
          {'kWh': 12.5, 'timestamp': '2026-06-01T10:00:00', 'kitNumber': 'k'});
    });
    await old.close();

    final db = await DBService().database;
    expect(await db.getVersion(), 17);
    final names = (await db
            .rawQuery("SELECT name FROM sqlite_master WHERE type='table'"))
        .map((r) => r['name'])
        .toSet();
    expect(names, containsAll(['hourly_consumptions', 'server_settings']));
    final cons = await db.query('consumptions');
    expect(cons.single['kWh'], 12.5);
  });
}
