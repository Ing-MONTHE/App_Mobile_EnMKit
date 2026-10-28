import 'package:enmkit/core/db_service.dart';
import 'package:enmkit/models/support_message_model.dart';
import 'package:sqflite/sqflite.dart';

/// Accès au fil d'assistance en base. Seul écrivain de `support_messages`.
class SupportRepository {
  SupportRepository(this._dbService);
  final DBService _dbService;

  /// Tout le fil, du plus ancien au plus récent (ordre de lecture naturel).
  Future<List<SupportMessage>> getThread() async {
    final db = await _dbService.database;
    final rows = await db.query('support_messages', orderBy: 'at ASC, id ASC');
    return rows.map(SupportMessage.fromMap).toList();
  }

  Future<int> add(SupportMessage message) async {
    final db = await _dbService.database;
    return db.insert('support_messages', message.toMap());
  }

  /// Vrai si un message IDENTIQUE vient d'être enregistré : le même SMS peut
  /// être livré deux fois (file native rejouée, double réception). Fenêtre
  /// courte pour ne pas fusionner deux messages légitimement identiques.
  Future<bool> isDuplicate(
    String body,
    DateTime at, {
    Duration window = const Duration(seconds: 45),
  }) async {
    final db = await _dbService.database;
    final from = at.subtract(window).millisecondsSinceEpoch;
    final to = at.add(window).millisecondsSinceEpoch;
    final rows = await db.query(
      'support_messages',
      where: 'outgoing = 0 AND body = ? AND at BETWEEN ? AND ?',
      whereArgs: [body, from, to],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  /// Horodatage de dernière consultation du fil, rangé dans `app_meta` : pas
  /// de migration de schéma pour un simple marqueur.
  static const String _seenKey = 'supportLastSeen';

  /// Nombre de réponses du support arrivées depuis la dernière consultation.
  Future<int> unreadCount() async {
    final db = await _dbService.database;
    await db.execute(
        'CREATE TABLE IF NOT EXISTS app_meta(key TEXT PRIMARY KEY, value TEXT)');
    final rows = await db
        .query('app_meta', where: 'key = ?', whereArgs: [_seenKey], limit: 1);
    final since =
        rows.isEmpty ? 0 : int.tryParse('${rows.first['value']}') ?? 0;
    final r = await db.rawQuery(
      'SELECT COUNT(*) c FROM support_messages WHERE outgoing = 0 AND at > ?',
      [since],
    );
    return (r.first['c'] as int?) ?? 0;
  }

  /// Marque le fil comme lu à l'instant.
  Future<void> markSeen() async {
    final db = await _dbService.database;
    await db.execute(
        'CREATE TABLE IF NOT EXISTS app_meta(key TEXT PRIMARY KEY, value TEXT)');
    await db.insert(
      'app_meta',
      {'key': _seenKey, 'value': '${DateTime.now().millisecondsSinceEpoch}'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clear() async {
    final db = await _dbService.database;
    await db.delete('support_messages');
  }
}
