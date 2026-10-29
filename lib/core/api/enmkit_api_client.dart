import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:enmkit/models/server_config_model.dart';
import 'package:http/http.dart' as http;

/// Cause d'échec d'un appel au serveur EnMKit. L'application doit rester
/// pleinement utilisable hors-ligne : chaque cause a un repli local.
enum ApiFailure {
  /// URL ou clé non renseignées.
  notConfigured,

  /// Pas de réseau / serveur injoignable / délai dépassé.
  offline,

  /// Clé refusée (401/403).
  unauthorized,

  /// Assistant indisponible côté serveur (503 `assistant_unavailable`).
  unavailable,

  /// Quota journalier de questions atteint (429 `assistant_quota_exceeded`).
  quotaExceeded,

  /// Autre erreur (4xx/5xx, réponse illisible).
  error,
}

class ApiException implements Exception {
  const ApiException(this.failure, [this.detail]);
  final ApiFailure failure;
  final String? detail;
  @override
  String toString() => 'ApiException($failure${detail != null ? ', $detail' : ''})';
}

/// Résultat de `GET /api/v1/app/me` (contrat §5).
class AppMe {
  const AppMe({required this.clientName, required this.kitNumbers});
  final String clientName;
  final List<String> kitNumbers;
}

/// Message d'une conversation avec l'assistant.
class ChatMessage {
  const ChatMessage({required this.role, required this.content, this.local = false});

  /// 'user' | 'assistant'.
  final String role;
  final String content;

  /// Vrai si la réponse a été produite HORS-LIGNE (repli local).
  final bool local;

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

class ChatReply {
  const ChatReply({
    required this.reply,
    this.model,
    this.usedInsights = false,
    this.quotaRemaining,
  });
  final String reply;
  final String? model;
  final bool usedInsights;

  /// Questions restantes aujourd'hui (null = illimité).
  final int? quotaRemaining;
}

/// Client HTTP minimal de l'API EnMKit (endpoints « app », clé `X-Client-Key`).
///
/// SÉCURITÉ : la clé client n'est placée QUE dans l'en-tête `X-Client-Key` ;
/// elle n'est jamais journalisée ni incluse dans les messages d'erreur.
class EnmkitApiClient {
  EnmkitApiClient(this.config, {http.Client? client, this.timeout = const Duration(seconds: 20)})
      : _client = client ?? http.Client();

  final ServerConfig config;
  final http.Client _client;
  final Duration timeout;

  Map<String, String> get _headers => {
        'X-Client-Key': config.clientKey.trim(),
        'Accept': 'application/json',
        'Content-Type': 'application/json; charset=utf-8',
      };

  Uri _uri(String path) => Uri.parse('${config.baseUrl}/api/v1$path');

  /// `GET /api/v1/app/me` : vérifie la clé et liste les kits du client.
  Future<AppMe> me() async {
    final json = await _send(() => _client.get(_uri('/app/me'), headers: _headers));
    final client = (json['client'] as Map?) ?? const {};
    final kits = (json['kits'] as List?) ?? const [];
    return AppMe(
      clientName: (client['name'] as String?) ?? '-',
      kitNumbers: [
        for (final k in kits)
          if (k is Map && k['kit_number'] is String) k['kit_number'] as String
      ],
    );
  }

  /// `POST /api/v1/app/assistant/chat`.
  Future<ChatReply> chat({
    String? kitNumber,
    required String audience,
    required String lang,
    required List<ChatMessage> messages,
    String? moduleCode,
  }) async {
    final body = jsonEncode({
      if (kitNumber != null && kitNumber.isNotEmpty) 'kit_number': kitNumber,
      if (moduleCode != null) 'module_code': moduleCode,
      'audience': audience,
      'lang': lang,
      'messages': messages.map((m) => m.toJson()).toList(),
    });
    final json = await _send(() =>
        _client.post(_uri('/app/assistant/chat'), headers: _headers, body: body));
    final reply = json['reply'];
    if (reply is! String || reply.trim().isEmpty) {
      throw const ApiException(ApiFailure.error, 'empty_reply');
    }
    return ChatReply(
      reply: reply,
      model: json['model'] as String?,
      usedInsights: json['used_insights'] == true,
      quotaRemaining: (json['quota_remaining'] as num?)?.toInt(),
    );
  }

  Future<Map<String, dynamic>> _send(Future<http.Response> Function() call) async {
    if (!config.isConfigured) throw const ApiException(ApiFailure.notConfigured);
    http.Response res;
    try {
      res = await call().timeout(timeout);
    } on TimeoutException {
      throw const ApiException(ApiFailure.offline, 'timeout');
    } on SocketException {
      throw const ApiException(ApiFailure.offline);
    } on http.ClientException {
      throw const ApiException(ApiFailure.offline);
    } on HandshakeException {
      throw const ApiException(ApiFailure.offline, 'tls');
    } on FormatException {
      throw const ApiException(ApiFailure.error, 'bad_url');
    } on ArgumentError {
      throw const ApiException(ApiFailure.error, 'bad_url');
    }
    String? detail;
    Map<String, dynamic>? json;
    try {
      // JSON = UTF-8 par définition (FastAPI n'annonce pas toujours le
      // charset) ; repli sur le décodage déclaré par l'en-tête sinon.
      String text;
      try {
        text = utf8.decode(res.bodyBytes);
      } on FormatException {
        text = res.body;
      }
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) {
        json = decoded;
        final d = decoded['detail'];
        if (d is String) detail = d;
      }
    } catch (_) {}
    if (res.statusCode == 401 || res.statusCode == 403) {
      throw ApiException(ApiFailure.unauthorized, detail);
    }
    if (res.statusCode == 503) throw ApiException(ApiFailure.unavailable, detail);
    if (res.statusCode == 429) throw ApiException(ApiFailure.quotaExceeded, detail);
    if (res.statusCode < 200 || res.statusCode >= 300 || json == null) {
      throw ApiException(ApiFailure.error, detail ?? 'HTTP ${res.statusCode}');
    }
    return json;
  }

  void close() => _client.close();
}
