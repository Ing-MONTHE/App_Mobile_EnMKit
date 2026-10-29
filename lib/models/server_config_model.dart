/// Configuration OPTIONNELLE du serveur EnMKit (table `server_settings`, id=1).
///
/// La clé client `ck_…` est un secret : elle n'est jamais journalisée ni
/// affichée en clair (voir [maskedKey]).
class ServerConfig {
  const ServerConfig({this.apiUrl = '', this.clientKey = ''});

  final String apiUrl;
  final String clientKey;

  /// Configuré = URL ET clé renseignées.
  bool get isConfigured => apiUrl.trim().isNotEmpty && clientKey.trim().isNotEmpty;

  /// URL normalisée : sans « / » final, schéma https par défaut.
  String get baseUrl {
    var u = apiUrl.trim();
    if (u.isEmpty) return u;
    if (!u.startsWith('http://') && !u.startsWith('https://')) u = 'https://$u';
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  /// Clé masquée pour l'affichage : « ck_ab…yz ».
  String get maskedKey {
    final k = clientKey.trim();
    if (k.isEmpty) return '';
    if (k.length <= 8) return '••••';
    return '${k.substring(0, 5)}…${k.substring(k.length - 2)}';
  }

  Map<String, dynamic> toMap() => {
        'id': 1,
        'apiUrl': apiUrl.trim(),
        'clientKey': clientKey.trim(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

  factory ServerConfig.fromMap(Map<String, dynamic> m) => ServerConfig(
        apiUrl: (m['apiUrl'] as String?) ?? '',
        clientKey: (m['clientKey'] as String?) ?? '',
      );

  /// Ne JAMAIS exposer la clé, même par mégarde dans un log.
  @override
  String toString() => 'ServerConfig($baseUrl, key: $maskedKey)';
}
