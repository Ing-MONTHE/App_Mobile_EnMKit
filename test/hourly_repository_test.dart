// Persistance des trames horaires : création du schéma v17 (onCreate),
// migration idempotente et upsert « dernier reçu gagne » sans doublon.
// Base SQLite réelle via sqflite_common_ffi (exécutée sur la machine de test).

import 'dart:io';

import 'package:enmkit/core/db_service.dart';
import 'package:enmkit/core/utils/sms_parser.dart';
import 'package:enmkit/repositories/hourly_consumption_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late HourlyConsumptionRepository repo;
  const kit = '+237699000000';

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // Dossier propre à ce fichier : les fichiers de test tournent en parallèle.
    await databaseFactory.setDatabasesPath(
        Directory.systemTemp.createTempSync('enmkit_repo_').path);
    // Base neuve : on supprime un éventuel reliquat d'une exécution précédente.
    final path = p.join(await getDatabasesPath(), 'kit_control.db');
    await databaseFactory.deleteDatabase(path);
    repo = HourlyConsumptionRepository(DBService());
  });

  test('upsert : même SMS reçu deux fois => aucune ligne en double', () async {
    final frames =
        SmsParser.parseHourlyFrames('27/06/26;09;0.00\n27/06/26;10;0.12').frames;
    await repo.upsertFrames(kit, frames);
    await repo.upsertFrames(kit, frames); // 2e chemin (natif + temps réel)
    final rows = await repo.getHourly(kit);
    expect(rows.length, 2);
    expect(rows.first.hourKey, '2026-06-27T09:00:00');
    expect(rows.last.kwh, 0.12);
  });

  test('upsert : nouvelle valeur pour la même heure => remplace', () async {
    final again = SmsParser.parseHourlyFrames('27/06/26;10;0.30').frames;
    await repo.upsertFrames(kit, again);
    final rows = await repo.getHourly(kit);
    expect(rows.length, 2);
    expect(rows.last.kwh, 0.30);
  });

  test('isolation par kit et bornes de lecture', () async {
    await repo.upsertFrames(
        '+237677000000', SmsParser.parseHourlyFrames('27/06/26;10;9.0').frames);
    expect(await repo.count(kit), 2);
    expect(await repo.count('+237677000000'), 1);
    final only10 = await repo.getHourly(kit,
        from: DateTime(2026, 6, 27, 10), to: DateTime(2026, 6, 27, 10));
    expect(only10.single.kwh, 0.30);
  });

  test('migration v17 rejouable (IF NOT EXISTS) sur une base existante',
      () async {
    final db = await DBService().database;
    await DBService.createV17Tables(db); // ne doit pas lever
    final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'");
    final names = tables.map((r) => r['name']).toSet();
    expect(
        names,
        containsAll([
          'hourly_consumptions',
          'server_settings',
          'edu_progress',
          'edu_quiz_scores',
          'edu_scenarios',
        ]));
    expect(await db.getVersion(), 17);
  });
}
