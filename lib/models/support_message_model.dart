/// Un message du fil d'assistance, dans un sens ou dans l'autre.
///
/// Le fil est porté par des SMS échangés avec le numéro du support : il faut
/// donc le persister, car une réponse peut arriver APPLICATION FERMÉE et doit
/// se retrouver dans la conversation au prochain lancement.
class SupportMessage {
  SupportMessage({
    this.id,
    required this.outgoing,
    required this.body,
    required this.at,
    this.kitNumber,
  });

  final int? id;

  /// Vrai si le message a été ENVOYÉ par l'utilisateur, faux s'il vient du
  /// support.
  final bool outgoing;

  final String body;
  final DateTime at;

  /// Kit concerné par la demande, quand elle en vise un (rappelé au support
  /// dans le message pour qu'il sache de quel boîtier on parle).
  final String? kitNumber;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'outgoing': outgoing ? 1 : 0,
        'body': body,
        'at': at.millisecondsSinceEpoch,
        'kitNumber': kitNumber,
      };

  factory SupportMessage.fromMap(Map<String, dynamic> map) => SupportMessage(
        id: map['id'] as int?,
        outgoing: (map['outgoing'] ?? 0) == 1,
        body: (map['body'] ?? '') as String,
        at: DateTime.fromMillisecondsSinceEpoch((map['at'] ?? 0) as int),
        kitNumber: map['kitNumber'] as String?,
      );
}
