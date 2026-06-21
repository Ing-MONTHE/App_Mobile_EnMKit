import 'package:enmkit/core/db_service.dart';
import 'package:enmkit/models/allowed_number_model.dart';

class AllowedNumberRepository {
  final DBService _dbService;
  AllowedNumberRepository(this._dbService);

  // Ajouter un numéro
  Future<void> addNumber(AllowedNumberModel number) async {
    final db = await _dbService.database;
    await db.insert('allowed_numbers', number.toMap());
  }

  // Récupérer tous les numéros (filtrés par kit si [kitNumber] est fourni)
  Future<List<AllowedNumberModel>> getAllNumbers({String? kitNumber}) async {
    final db = await _dbService.database;
    final maps = kitNumber == null
        ? await db.query('allowed_numbers')
        : await db.query('allowed_numbers', where: 'kitNumber = ?', whereArgs: [kitNumber]);
    return maps.map((m) => AllowedNumberModel.fromMap(m)).toList();
  }

  // Mettre à jour un numéro
  Future<void> updateNumber(AllowedNumberModel number) async {
    final db = await _dbService.database;
    await db.update(
      'allowed_numbers',
      number.toMap(),
      where: 'id = ?',
      whereArgs: [number.id],
    );
  }

  // Supprimer un numéro
  Future<void> deleteNumber(int id) async {
    final db = await _dbService.database;
    await db.delete(
      'allowed_numbers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

    /// Supprime tous les numéros autorisés (d'un kit si [kitNumber] est fourni)
  Future<void> clearAllowedNumbers({String? kitNumber}) async {
    final db = await _dbService.database;
    if (kitNumber == null) {
      await db.delete('allowed_numbers');
    } else {
      await db.delete('allowed_numbers', where: 'kitNumber = ?', whereArgs: [kitNumber]);
    }
  }
}
