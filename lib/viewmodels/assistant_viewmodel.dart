import 'package:enmkit/core/ai/energy_insights.dart';
import 'package:enmkit/core/ai/local_assistant.dart';
import 'package:enmkit/core/api/enmkit_api_client.dart';
import 'package:enmkit/models/server_config_model.dart';
import 'package:flutter/foundation.dart';

/// Public visé par l'assistant (contrat §5) : apprenant, propriétaire, formateur.
enum AssistantAudience { learner, owner, trainer }

/// Conversation avec l'assistant énergie. EN LIGNE si le serveur EnMKit est
/// configuré et joignable ; sinon (ou en cas d'échec / 503) réponse LOCALE
/// construite à partir des recommandations hors-ligne et des éco-gestes.
class AssistantViewModel extends ChangeNotifier {
  AssistantViewModel({
    required this.kitNumber,
    required ServerConfig Function() config,
    EnmkitApiClient Function(ServerConfig)? clientFactory,
    AssistantAudience audience = AssistantAudience.owner,
  })  : _config = config,
        _clientFactory = clientFactory ?? ((c) => EnmkitApiClient(c)),
        _audience = audience;

  final String? kitNumber;
  final ServerConfig Function() _config;
  final EnmkitApiClient Function(ServerConfig) _clientFactory;

  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  AssistantAudience _audience;
  AssistantAudience get audience => _audience;
  set audience(AssistantAudience a) {
    _audience = a;
    notifyListeners();
  }

  /// TP en cours (TP1…TP7) : l'assistant en ligne reçoit son contenu et
  /// joue le rôle de tuteur. Null = conversation générale.
  String? moduleCode;

  /// Questions restantes aujourd'hui, d'après la dernière réponse en ligne.
  int? _quotaRemaining;
  int? get quotaRemaining => _quotaRemaining;

  bool _sending = false;
  bool get sending => _sending;

  /// Dernière cause de repli hors-ligne (null = dernière réponse en ligne).
  ApiFailure? _lastFailure;
  ApiFailure? get lastFailure => _lastFailure;

  bool get onlineConfigured => _config().isConfigured;

  /// Envoie [text]. [insights] : analyse locale du kit, utilisée en repli.
  Future<void> send(String text, {required String lang, EnergyInsights? insights}) async {
    final q = text.trim();
    if (q.isEmpty || _sending) return;
    _messages.add(ChatMessage(role: 'user', content: q));
    _sending = true;
    notifyListeners();

    final cfg = _config();
    String reply;
    var local = false;
    if (!cfg.isConfigured) {
      _lastFailure = ApiFailure.notConfigured;
      reply = LocalAssistant.answer(q, lang: lang, insights: insights);
      local = true;
    } else {
      final api = _clientFactory(cfg);
      try {
        // Historique limité aux 12 derniers messages (coût et latence réseau).
        final history = _messages.length > 12
            ? _messages.sublist(_messages.length - 12)
            : List.of(_messages);
        final r = await api.chat(
          kitNumber: kitNumber,
          audience: _audience.name,
          lang: lang,
          messages: history,
          moduleCode: moduleCode,
        );
        reply = r.reply;
        _quotaRemaining = r.quotaRemaining;
        _lastFailure = null;
      } on ApiException catch (e) {
        _lastFailure = e.failure;
        reply = LocalAssistant.answer(q, lang: lang, insights: insights);
        local = true;
      } catch (_) {
        _lastFailure = ApiFailure.error;
        reply = LocalAssistant.answer(q, lang: lang, insights: insights);
        local = true;
      } finally {
        api.close();
      }
    }
    _messages.add(ChatMessage(role: 'assistant', content: reply, local: local));
    _sending = false;
    notifyListeners();
  }

  void clear() {
    _messages.clear();
    _lastFailure = null;
    notifyListeners();
  }
}
