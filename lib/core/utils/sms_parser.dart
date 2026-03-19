// lib/core/utils/sms_parser.dart

/// Utilitaire pour parser les messages SMS
class SmsParser {
  static Map<String, String> parseAckMessage(String ackMessage) {
    final Map<String, String> configData = {};
    final normalizedMessage = ackMessage.replaceAll(RegExp(r'\s+'), '').toLowerCase();
    
    final patterns = {
      'n1': RegExp(r'n1:([^:]+?)(?=(?:n2|en|ip):|$)', caseSensitive: false),
      'n2': RegExp(r'n2:([^:]+?)(?=(?:n1|en|ip):|$)', caseSensitive: false),
      'en': RegExp(r'en:([^:]+?)(?=(?:n1|n2|ip):|$)', caseSensitive: false),
      'ip': RegExp(r'ip:([^:]+?)(?=(?:n1|n2|en):|$)', caseSensitive: false),
    };
    
    for (final entry in patterns.entries) {
      final match = entry.value.firstMatch(normalizedMessage);
      if (match != null) {
        final value = match.group(1) ?? '';
        if (value.isNotEmpty) configData[entry.key] = value;
      }
    }
    
    return configData;
  }
  
  static bool verifyAckMessage(String ackMessage, String expectedMessage) {
    final normalizedAck = ackMessage.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    final normalizedExpected = expectedMessage.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    
    if (expectedMessage.contains(':') && expectedMessage.split(':').length > 2) {
      final expectedParts = normalizedExpected.split(':');
      for (int i = 0; i < expectedParts.length - 1; i += 2) {
        if (!normalizedAck.contains('${expectedParts[i]}:${expectedParts[i + 1]}')) {
          return false;
        }
      }
      return true;
    }
    
    return normalizedAck.contains(normalizedExpected);
  }
  
  static String buildRelayCommand(int relayId, bool turnOn) {
    return 'r$relayId${turnOn ? "on" : "off"}';
  }
  
  static String buildConfigCommand({
    String? firstPhone,
    String? secondPhone,
    double? initialConsumption,
    int? pulsation,
  }) {
    final List<String> parts = [];
    if (firstPhone != null && firstPhone.isNotEmpty) parts.add('n1:$firstPhone');
    if (secondPhone != null && secondPhone.isNotEmpty) parts.add('n2:$secondPhone');
    if (initialConsumption != null) parts.add('en:$initialConsumption');
    if (pulsation != null) parts.add('ip:$pulsation');
    return parts.join(':');
  }
}
