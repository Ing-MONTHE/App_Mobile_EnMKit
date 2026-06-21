/// Un accusé de réception horodaté renvoyé par le kit pour une ligne donnée.
///
/// On en enregistre un à chaque écho confirmé (« rXon » / « rXoff »), afin de
/// présenter un historique fiable plutôt qu'un simple indicateur d'état qui
/// pourrait laisser croire que le dernier accusé concerne la dernière commande.
class RelayAck {
  final int? id;
  final int relayId;
  final String? kitNumber;
  final bool isActive;
  final DateTime at;

  /// Contenu brut de l'accusé renvoyé par le kit (texte du SMS, ex. « r1on »).
  /// Joint à l'historique pour montrer la confirmation réellement reçue.
  final String? raw;

  RelayAck({
    this.id,
    required this.relayId,
    required this.kitNumber,
    required this.isActive,
    required this.at,
    this.raw,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'relayId': relayId,
      'kitNumber': kitNumber,
      'isActive': isActive ? 1 : 0,
      'at': at.millisecondsSinceEpoch,
      'raw': raw,
    };
  }

  factory RelayAck.fromMap(Map<String, dynamic> map) {
    return RelayAck(
      id: map['id'] as int?,
      relayId: map['relayId'] as int,
      kitNumber: map['kitNumber'] as String?,
      isActive: (map['isActive'] ?? 0) == 1,
      at: DateTime.fromMillisecondsSinceEpoch(map['at'] as int),
      raw: map['raw'] as String?,
    );
  }
}
