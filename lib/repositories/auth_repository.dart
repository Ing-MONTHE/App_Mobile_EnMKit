
import 'package:enmkit/core/db_service.dart';
import 'package:enmkit/models/users_model.dart';
import 'package:sqflite/sqflite.dart';

class AuthRepository {
  final DBService _dbService;

  AuthRepository(this._dbService);

  /// Insère un nouvel utilisateur dans la table users
  Future<void> registerUser(UserModel user) async {
    final db = await _dbService.database;
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace, // remplace si déjà présent
    );
  }

/// Vérifie le login et retourne l'utilisateur si valide
/// Si c'est un admin, vérifie qu'il ne s'est pas déjà connecté
Future<UserModel?> login(String phone, String password) async {
  final db = await _dbService.database;

  // Recherche de l'utilisateur avec le téléphone et mot de passe
  final result = await db.query(
    'users',
    where: 'phoneNumber = ? AND password = ?',
    whereArgs: [phone, password],
  );

  if (result.isNotEmpty) {
    final user = UserModel.fromMap(result.first);

    // Si l'utilisateur est un admin
    if (user.isAdmin) {
      if (user.hasConnected) {
        // L'admin s'est déjà connecté, on refuse l'accès
        return null;
      } else {
        // Marque l'admin comme connecté pour bloquer les prochaines connexions
        await db.update(
          'users',
          {'hasConnected': 1},
          where: 'isAdmin = 1',
        );
      }
    }

    return user;
  }

  return null; // aucun utilisateur trouvé
}


  /// Met à jour le statut de connexion pour l'admin
  Future<void> markAdminConnected(String phone) async {
    final db = await _dbService.database;
    await db.update(
      'users',
      {'hasConnected': 1},
      where: 'phoneNumber = ? AND isAdmin = 1',
      whereArgs: [phone],
    );
  }

  /// Vérifie si l'admin s'est déjà connecté
  Future<bool> hasAdminConnected(String phone) async {
    final db = await _dbService.database;
    final result = await db.query(
      'users',
      columns: ['hasConnected'],
      where: 'phoneNumber = ? AND isAdmin = 1',
      whereArgs: [phone],
    );

    if (result.isNotEmpty) {
      return result.first['hasConnected'] == 1;
    }

    return false;
  }
}
