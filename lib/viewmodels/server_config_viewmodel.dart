import 'package:enmkit/core/api/enmkit_api_client.dart';
import 'package:enmkit/models/server_config_model.dart';
import 'package:enmkit/repositories/server_config_repository.dart';
import 'package:flutter/foundation.dart';

enum ServerTestStatus { idle, testing, ok, failed }

/// Réglage OPTIONNEL du serveur EnMKit (URL + clé client) et test de
/// connexion (`GET /api/v1/app/me`). Sans configuration, l'app fonctionne
/// intégralement hors-ligne.
class ServerConfigViewModel extends ChangeNotifier {
  ServerConfigViewModel(this._repo);
  final ServerConfigRepository _repo;

  ServerConfig _config = const ServerConfig();
  ServerConfig get config => _config;

  ServerTestStatus _status = ServerTestStatus.idle;
  ServerTestStatus get status => _status;
  ApiFailure? _failure;
  ApiFailure? get failure => _failure;
  AppMe? _me;
  AppMe? get me => _me;

  Future<void> load() async {
    try {
      _config = await _repo.load();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> save(String apiUrl, String clientKey) async {
    _config = ServerConfig(apiUrl: apiUrl.trim(), clientKey: clientKey.trim());
    _status = ServerTestStatus.idle;
    _me = null;
    _failure = null;
    notifyListeners();
    await _repo.save(_config);
  }

  Future<void> clear() async {
    _config = const ServerConfig();
    _status = ServerTestStatus.idle;
    _me = null;
    _failure = null;
    notifyListeners();
    await _repo.clear();
  }

  /// Teste la connexion avec la configuration enregistrée.
  Future<void> test() async {
    _status = ServerTestStatus.testing;
    _failure = null;
    notifyListeners();
    final api = EnmkitApiClient(_config, timeout: const Duration(seconds: 12));
    try {
      _me = await api.me();
      _status = ServerTestStatus.ok;
    } on ApiException catch (e) {
      _failure = e.failure;
      _status = ServerTestStatus.failed;
    } catch (_) {
      _failure = ApiFailure.error;
      _status = ServerTestStatus.failed;
    } finally {
      api.close();
      notifyListeners();
    }
  }
}
