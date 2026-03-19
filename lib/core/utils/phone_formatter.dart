// lib/core/utils/phone_formatter.dart

/// Utilitaire pour formater les numéros de téléphone
class PhoneFormatter {
  static const String _defaultCountryCode = '+237';
  
  static String format(String phoneNumber, {String? countryCode}) {
    final code = countryCode ?? _defaultCountryCode;
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (cleanNumber.startsWith(code)) return cleanNumber;
    if (cleanNumber.startsWith(code.substring(1))) return '+$cleanNumber';
    if (cleanNumber.startsWith('0')) return '$code${cleanNumber.substring(1)}';
    if (cleanNumber.length >= 6 && cleanNumber.length <= 9) return '$code$cleanNumber';
    
    return cleanNumber;
  }
  
  static bool isValid(String phoneNumber, {int minLength = 9}) {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    return cleanNumber.length >= minLength;
  }
}
