import 'package:enmkit/core/support_service.dart';
import 'package:enmkit/models/support_message_model.dart';
import 'package:enmkit/repositories/support_repository.dart';
import 'package:flutter/foundation.dart';

/// Fil d'assistance : conversation SMS avec le support.
///
/// La base fait foi : les réponses peuvent arriver application fermée (elles
/// sont alors enregistrées par le drain), et l'écran se contente de refléter
/// ce que contient la base.
class SupportViewModel extends ChangeNotifier {
  SupportViewModel(this._repo, this._service) {
    load();
  }

  final SupportRepository _repo;
  final SupportService _service;

  List<SupportMessage> _thread = [];
  List<SupportMessage> get thread => _thread;

  bool _sending = false;
  bool get sending => _sending;

  bool _loading = true;
  bool get loading => _loading;

  /// Réponses du support non encore consultées : alimente la pastille de
  /// l'onglet Aide. Sans ce signal, une réponse arrivée en arrière-plan reste
  /// invisible tant que l'utilisateur n'ouvre pas le fil de lui-même.
  int _unread = 0;
  int get unread => _unread;

  Future<void> load() async {
    _thread = await _repo.getThread();
    _unread = await _repo.unreadCount();
    _loading = false;
    notifyListeners();
  }

  /// Le fil vient d'être ouvert : la pastille s'éteint.
  Future<void> markSeen() async {
    if (_unread == 0) return;
    await _repo.markSeen();
    _unread = 0;
    notifyListeners();
  }

  /// Envoie [text] au support et ne l'inscrit au fil QUE si l'envoi a réussi :
  /// afficher un message parti alors qu'il ne l'est pas ferait croire à une
  /// demande prise en compte.
  Future<bool> send(String text, {String? kitNumber}) async {
    if (text.trim().isEmpty || _sending) return false;
    _sending = true;
    notifyListeners();
    try {
      final ok = await _service.send(text);
      if (ok) {
        await _repo.add(SupportMessage(
          outgoing: true,
          body: text,
          at: DateTime.now(),
          kitNumber: kitNumber,
        ));
        await load();
      }
      return ok;
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

  /// Enregistre une réponse du support (appelée par le drain des SMS entrants).
  /// Ignore un doublon : le même SMS peut être livré deux fois.
  Future<void> receive(String body, DateTime at) async {
    if (body.trim().isEmpty) return;
    if (await _repo.isDuplicate(body, at)) return;
    await _repo.add(SupportMessage(outgoing: false, body: body, at: at));
    await load();
  }

  Future<bool> openWhatsApp({String? text}) => _service.openWhatsApp(text: text);
}
