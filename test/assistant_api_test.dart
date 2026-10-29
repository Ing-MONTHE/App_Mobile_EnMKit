// Assistant énergie : appel en ligne (POST /app/assistant/chat) avec la clé
// `X-Client-Key`, et repli HORS-LIGNE sur les conseils locaux quand le serveur
// n'est pas configuré, injoignable ou renvoie 503.

import 'dart:convert';

import 'package:enmkit/core/api/enmkit_api_client.dart';
import 'package:enmkit/models/server_config_model.dart';
import 'package:enmkit/viewmodels/assistant_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _cfg = ServerConfig(apiUrl: 'api.enmkit.test/', clientKey: 'ck_demo_secret_key');

void main() {
  group('ServerConfig', () {
    test('URL normalisée (https par défaut, sans / final)', () {
      expect(_cfg.baseUrl, 'https://api.enmkit.test');
      expect(const ServerConfig(apiUrl: 'http://10.0.2.2:8000//').baseUrl,
          'http://10.0.2.2:8000');
    });

    test('la clé n\'apparaît jamais en clair dans toString / maskedKey', () {
      expect(_cfg.toString(), isNot(contains('secret')));
      expect(_cfg.maskedKey, isNot(contains('secret')));
      expect(const ServerConfig().isConfigured, isFalse);
    });
  });

  group('EnmkitApiClient', () {
    test('GET /app/me avec X-Client-Key', () async {
      late http.Request seen;
      final client = MockClient((req) async {
        seen = req;
        // Corps UTF-8 SANS charset déclaré (cas de FastAPI).
        return http.Response.bytes(
            utf8.encode(jsonEncode({
              'client': {'name': 'Lycée technique'},
              'kits': [
                {'kit_number': '237699000000'}
              ],
            })),
            200,
            headers: {'content-type': 'application/json'});
      });
      final me = await EnmkitApiClient(_cfg, client: client).me();
      expect(seen.url.toString(), 'https://api.enmkit.test/api/v1/app/me');
      expect(seen.headers['X-Client-Key'], 'ck_demo_secret_key');
      expect(me.clientName, 'Lycée technique');
      expect(me.kitNumbers, ['237699000000']);
    });

    test('codes HTTP => causes d\'échec typées', () async {
      Future<ApiFailure> fail(int code) async {
        final c = MockClient((_) async =>
            http.Response(jsonEncode({'detail': 'x'}), code));
        try {
          await EnmkitApiClient(_cfg, client: c).me();
        } on ApiException catch (e) {
          return e.failure;
        }
        throw StateError('pas d\'exception');
      }

      expect(await fail(401), ApiFailure.unauthorized);
      expect(await fail(503), ApiFailure.unavailable);
      expect(await fail(429), ApiFailure.quotaExceeded);
      expect(await fail(500), ApiFailure.error);
    });

    test('réseau absent => offline', () async {
      final c = MockClient((_) async => throw http.ClientException('no route'));
      expect(
        () => EnmkitApiClient(_cfg, client: c).me(),
        throwsA(isA<ApiException>()
            .having((e) => e.failure, 'failure', ApiFailure.offline)),
      );
    });
  });

  group('AssistantViewModel', () {
    test('en ligne : corps conforme au contrat et réponse du serveur', () async {
      Map<String, dynamic>? body;
      final vm = AssistantViewModel(
        kitNumber: '237699000000',
        config: () => _cfg,
        audience: AssistantAudience.learner,
        clientFactory: (c) => EnmkitApiClient(c,
            client: MockClient((req) async {
              body = jsonDecode(req.body) as Map<String, dynamic>;
              return http.Response(
                  jsonEncode({'reply': 'Bonjour !', 'model': 'm', 'used_insights': true}),
                  200);
            })),
      );
      await vm.send('Qu\'est-ce que la veille ?', lang: 'fr');
      expect(body!['kit_number'], '237699000000');
      expect(body!['audience'], 'learner');
      expect(body!['lang'], 'fr');
      expect((body!['messages'] as List).single['role'], 'user');
      expect(vm.messages.last.content, 'Bonjour !');
      expect(vm.messages.last.local, isFalse);
      expect(vm.lastFailure, isNull);
    });

    test('503 => repli hors-ligne avec conseils locaux', () async {
      final vm = AssistantViewModel(
        kitNumber: null,
        config: () => _cfg,
        clientFactory: (c) => EnmkitApiClient(c,
            client: MockClient((_) async => http.Response(
                jsonEncode({'detail': 'assistant_unavailable'}), 503))),
      );
      await vm.send('Comment réduire la veille ?', lang: 'fr');
      expect(vm.lastFailure, ApiFailure.unavailable);
      expect(vm.messages.last.local, isTrue);
      expect(vm.messages.last.content, contains('hors-ligne'));
      expect(vm.messages.last.content.toLowerCase(), contains('veille'));
    });

    test('non configuré => réponse locale, aucun appel réseau', () async {
      var called = false;
      final vm = AssistantViewModel(
        kitNumber: null,
        config: () => const ServerConfig(),
        clientFactory: (c) => EnmkitApiClient(c,
            client: MockClient((_) async {
              called = true;
              return http.Response('{}', 200);
            })),
      );
      await vm.send('How can I lower my bill?', lang: 'en');
      expect(called, isFalse);
      expect(vm.lastFailure, ApiFailure.notConfigured);
      expect(vm.messages.last.content, contains('Offline answer'));
    });

    test('TP en cours : module_code envoyé, quota restant exposé', () async {
      Map<String, dynamic>? body;
      final vm = AssistantViewModel(
        kitNumber: null,
        config: () => _cfg,
        clientFactory: (c) => EnmkitApiClient(c,
            client: MockClient((req) async {
              body = jsonDecode(req.body) as Map<String, dynamic>;
              return http.Response(
                  jsonEncode({
                    'reply': 'Quelle puissance as-tu relevée ?',
                    'model': 'm',
                    'used_insights': false,
                    'used_module': 'TP1',
                    'quota_remaining': 29,
                  }),
                  200);
            })),
      )..moduleCode = 'TP1';
      await vm.send('Comment calculer l\'énergie ?', lang: 'fr');
      expect(body!['module_code'], 'TP1');
      expect(vm.quotaRemaining, 29);
      expect(vm.messages.last.local, isFalse);
    });

    test('429 quota atteint => repli hors-ligne', () async {
      final vm = AssistantViewModel(
        kitNumber: null,
        config: () => _cfg,
        clientFactory: (c) => EnmkitApiClient(c,
            client: MockClient((_) async => http.Response(
                jsonEncode({'detail': 'assistant_quota_exceeded'}), 429))),
      );
      await vm.send('Comment réduire la veille ?', lang: 'fr');
      expect(vm.lastFailure, ApiFailure.quotaExceeded);
      expect(vm.messages.last.local, isTrue);
    });
  });
}
