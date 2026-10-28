import 'package:enmkit/models/relay_ack_model.dart';

/// Logique pure (sans base ni UI) entourant les accusés de réception du kit.
///
/// Extraite ici pour être testable directement et partagée entre le ViewModel
/// (insertion en mémoire) et la vue (ouverture automatique de la feuille de
/// confirmation), garantissant un comportement unique et vérifié.
class AckLogic {
  AckLogic._();

  /// Fenêtre (en secondes) pendant laquelle deux accusés identiques (même ligne,
  /// même état) sont considérés comme un doublon — alignée sur la déduplication
  /// faite en base par le chemin natif.
  static const int dedupWindowSeconds = 30;

  /// Un nouvel accusé `(isOn, at)` fait-il DOUBLON avec un accusé déjà présent
  /// dans [existing] ? Vrai s'il existe une entrée de MÊME état dans la fenêtre
  /// [windowSeconds]. Sert à éviter d'empiler le même accusé quand le SMS est
  /// rejoué (reconstruction) ou que l'historique a déjà été rechargé depuis la
  /// base après le drain natif.
  static bool isDuplicate(
    Iterable<RelayAck> existing,
    bool isOn,
    DateTime at, {
    int windowSeconds = dedupWindowSeconds,
  }) {
    return existing.any((a) =>
        a.isActive == isOn &&
        at.difference(a.at).inSeconds.abs() <= windowSeconds);
  }

  /// Fenêtre (en secondes) en deçà de laquelle un même accusé (même ligne, même
  /// état) qui ré-arrive est considéré comme une RE-LIVRAISON du même message —
  /// et non une nouvelle commande. Un accusé est livré par DEUX chemins (le flux
  /// `readsms` ET la réinjection du chemin natif), à quelques secondes d'écart :
  /// sans cette fenêtre, la feuille de confirmation s'ouvrirait deux fois.
  static const int autoOpenWindowSeconds = 20;

  /// L'accusé `(relayId, isOn, at)` est-il une RE-LIVRAISON du dernier accusé
  /// ayant déjà déclenché l'ouverture automatique de la feuille ?
  ///
  /// Vrai si c'est la même ligne, le même état, et qu'il arrive dans la fenêtre
  /// [windowSeconds]. Cette déduplication est volontairement INDÉPENDANTE de
  /// l'historique affiché (qui peut être rechargé depuis la base après le drain
  /// natif) : elle ne se base que sur le dernier accusé réellement ouvert, de
  /// sorte qu'une vraie commande identique répétée plus tard rouvre bien la
  /// feuille, tout en absorbant les doubles livraisons quasi simultanées.
  static bool isAutoOpenDuplicate({
    required int? lastRelayId,
    required bool? lastState,
    required DateTime? lastAt,
    required int relayId,
    required bool isOn,
    required DateTime at,
    int windowSeconds = autoOpenWindowSeconds,
  }) {
    if (lastRelayId == null || lastState == null || lastAt == null) return false;
    return lastRelayId == relayId &&
        lastState == isOn &&
        at.difference(lastAt).inSeconds.abs() <= windowSeconds;
  }
}
