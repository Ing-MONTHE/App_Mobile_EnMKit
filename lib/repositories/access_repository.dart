import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:enmkit/core/db_service.dart';

/// Gère le code d'accès (PIN) de l'application, stocké haché + salé, ainsi que
/// les questions mémo de récupération.
///
/// Ni le PIN ni les réponses ne sont conservés en clair : on garde uniquement
/// `sha256(salt + valeur)` et le sel aléatoire associé. Le même sel sert au PIN
/// et aux réponses, et il est **préservé** lors d'un changement de code afin de
/// ne pas invalider les réponses déjà enregistrées.
class AccessRepository {
  final DBService _dbService;
  AccessRepository(this._dbService);

  /// Vrai si un code d'accès a déjà été défini (1er lancement = false).
  Future<bool> hasPin() async {
    final db = await _dbService.database;
    final res = await db.query('app_security', where: 'id = 1', limit: 1);
    return res.isNotEmpty;
  }

  /// Définit (ou change) le code d'accès. Préserve le sel et les questions mémo
  /// existants : seul le hachage du PIN est mis à jour.
  Future<void> setPin(String pin) async {
    final db = await _dbService.database;
    final existing = await db.query('app_security', where: 'id = 1', limit: 1);
    if (existing.isNotEmpty) {
      final salt = existing.first['salt'] as String;
      await db.update('app_security', {'pinHash': _hash(pin, salt)},
          where: 'id = 1');
    } else {
      final salt = _generateSalt();
      await db.insert(
        'app_security',
        {'id': 1, 'pinHash': _hash(pin, salt), 'salt': salt},
      );
    }
  }

  /// Supprime le code d'accès (et ses questions mémo).
  Future<void> clearPin() async {
    final db = await _dbService.database;
    await db.delete('app_security', where: 'id = 1');
  }

  /// Vérifie un code saisi contre le code enregistré.
  Future<bool> verifyPin(String pin) async {
    final db = await _dbService.database;
    final res = await db.query('app_security', where: 'id = 1', limit: 1);
    if (res.isEmpty) return false;
    final salt = res.first['salt'] as String;
    final expected = res.first['pinHash'] as String;
    return _hash(pin, salt) == expected;
  }

  // --- Questions mémo (récupération du code) --------------------------------

  /// Vrai si deux questions mémo complètes ont été enregistrées.
  Future<bool> hasSecurityQuestions() async {
    final db = await _dbService.database;
    final res = await db.query('app_security', where: 'id = 1', limit: 1);
    if (res.isEmpty) return false;
    final r = res.first;
    return r['q1'] != null &&
        r['q2'] != null &&
        r['a1Hash'] != null &&
        r['a2Hash'] != null;
  }

  /// Renvoie les clés des deux questions enregistrées, ou null si absentes.
  Future<List<String>?> getSecurityQuestionKeys() async {
    final db = await _dbService.database;
    final res = await db.query('app_security',
        columns: ['q1', 'q2'], where: 'id = 1', limit: 1);
    if (res.isEmpty) return null;
    final q1 = res.first['q1'] as String?;
    final q2 = res.first['q2'] as String?;
    if (q1 == null || q2 == null) return null;
    return [q1, q2];
  }

  /// Enregistre les deux questions (clés) + leurs réponses (hachées, normalisées).
  /// Nécessite un PIN déjà défini (réutilise son sel).
  Future<void> setSecurityQuestions(
      String q1, String a1, String q2, String a2) async {
    final db = await _dbService.database;
    final res = await db.query('app_security', where: 'id = 1', limit: 1);
    if (res.isEmpty) return;
    final salt = res.first['salt'] as String;
    await db.update(
      'app_security',
      {
        'q1': q1,
        'a1Hash': _hash(_normalize(a1), salt),
        'q2': q2,
        'a2Hash': _hash(_normalize(a2), salt),
      },
      where: 'id = 1',
    );
  }

  /// Vérifie les deux réponses (même ordre que [getSecurityQuestionKeys]).
  Future<bool> verifySecurityAnswers(String a1, String a2) async {
    final db = await _dbService.database;
    final res = await db.query('app_security', where: 'id = 1', limit: 1);
    if (res.isEmpty) return false;
    final salt = res.first['salt'] as String;
    final h1 = res.first['a1Hash'] as String?;
    final h2 = res.first['a2Hash'] as String?;
    if (h1 == null || h2 == null) return false;
    return _hash(_normalize(a1), salt) == h1 &&
        _hash(_normalize(a2), salt) == h2;
  }

  /// Normalise une réponse pour la rendre tolérante à la casse/espaces.
  String _normalize(String s) => s.trim().toLowerCase();

  String _generateSalt() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    return base64Url.encode(bytes);
  }

  String _hash(String value, String salt) {
    return sha256.convert(utf8.encode('$salt$value')).toString();
  }
}
