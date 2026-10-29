import 'package:flutter/foundation.dart';
import 'package:sms_sender_background/sms_sender.dart';
import 'package:url_launcher/url_launcher.dart';

/// Nature de la demande d'assistance. Le questionnaire enchaîne ensuite les
/// précisions utiles à CHAQUE nature (ex. quel numéro supprimer), pour que le
/// support reçoive une demande exploitable du premier coup.
enum SupportTopic { numberConfig, consumption, lineControl, unreachable, other }

/// Sous-choix de la configuration d'un numéro.
enum NumberAction { add, edit, remove }

/// Assistance par SMS : envoi des demandes au support et relais WhatsApp.
///
/// Le fil est un échange de SMS ordinaires avec [supportNumber]. Les réponses
/// arrivent par le récepteur natif, à condition que ce numéro figure dans la
/// liste d'autorisation poussée au natif, au même titre que les kits.
class SupportService {
  /// Numéro du support. Écrit au format international pour que l'envoi et la
  /// comparaison des réponses soient cohérents avec le reste de l'application.
  static const String supportNumber = '+237696372245';

  /// Les huit derniers chiffres identifient un numéro, quel que soit le format
  /// d'affichage de l'opérateur (avec ou sans indicatif, avec un 0 de tête).
  static bool isSupportNumber(String? sender) {
    if (sender == null) return false;
    String tail(String s) {
      final d = s.replaceAll(RegExp(r'[^0-9]'), '');
      return d.length > 8 ? d.substring(d.length - 8) : d;
    }

    final a = tail(sender);
    return a.isNotEmpty && a == tail(supportNumber);
  }

  /// Compose la demande envoyée au support.
  ///
  /// PURE et sans effet de bord, donc directement testable. Le message rappelle
  /// TOUJOURS le kit concerné quand il y en a un : sans cette mention, le
  /// support ignore de quel boîtier on parle.
  static String buildRequest({
    required SupportTopic topic,
    NumberAction? action,
    String? targetNumber,
    String? details,
    String? kitNumber,
    String? kitName,
  }) {
    final b = StringBuffer('EnMKit · Demande d\'assistance');

    if (kitNumber != null && kitNumber.isNotEmpty) {
      final label = (kitName != null && kitName.trim().isNotEmpty)
          ? '$kitNumber ($kitName)'
          : kitNumber;
      b.write('\nKit : $label');
    }

    b.write('\nObjet : ${topicLabel(topic)}');
    if (topic == SupportTopic.numberConfig && action != null) {
      b.write(' · ${actionLabel(action)}');
    }
    if (targetNumber != null && targetNumber.trim().isNotEmpty) {
      b.write('\nNuméro concerné : ${targetNumber.trim()}');
    }
    if (details != null && details.trim().isNotEmpty) {
      b.write('\nDétail : ${details.trim()}');
    }
    return b.toString();
  }

  static String topicLabel(SupportTopic t) {
    switch (t) {
      case SupportTopic.numberConfig:
        return 'Configuration d\'un numéro';
      case SupportTopic.consumption:
        return 'Problème de réception de la consommation';
      case SupportTopic.lineControl:
        return 'Problème de commande d\'une ligne';
      case SupportTopic.unreachable:
        return 'Kit injoignable';
      case SupportTopic.other:
        return 'Autre demande';
    }
  }

  static String actionLabel(NumberAction a) {
    switch (a) {
      case NumberAction.add:
        return 'Ajouter un numéro';
      case NumberAction.edit:
        return 'Modifier un numéro';
      case NumberAction.remove:
        return 'Supprimer un numéro';
    }
  }

  /// Envoie [text] au support par SMS. Retourne false si l'envoi a échoué :
  /// l'appelant doit alors NE PAS faire croire que le message est parti.
  Future<bool> send(String text) async {
    try {
      final sender = SmsSender();
      if (!await sender.checkSmsPermission()) {
        await sender.requestSmsPermission();
      }
      return await sender.sendSms(
        phoneNumber: supportNumber,
        message: text,
        simSlot: 0,
      );
    } catch (e) {
      debugPrint('Envoi support échoué : $e');
      return false;
    }
  }

  /// Ouvre la conversation WhatsApp avec le support, message pré-rempli.
  /// Retourne false si WhatsApp (ou un navigateur) ne peut pas être ouvert.
  Future<bool> openWhatsApp({String? text}) async {
    final digits = supportNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse(
      'https://wa.me/$digits${(text != null && text.isNotEmpty) ? '?text=${Uri.encodeComponent(text)}' : ''}',
    );
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Ouverture WhatsApp échouée : $e');
      return false;
    }
  }
}
