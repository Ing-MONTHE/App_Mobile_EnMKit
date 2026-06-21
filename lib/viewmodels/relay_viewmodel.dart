// import 'package:enmkit/core/sms_service.dart';
import 'dart:async';

import 'package:enmkit/core/sms_service_hybrid.dart';
import 'package:flutter/material.dart';
import 'package:enmkit/core/db_service.dart';
import 'package:enmkit/models/relay_ack_model.dart';
import 'package:enmkit/models/relay_model.dart';
import 'package:enmkit/repositories/relay_repository.dart';


class RelayViewModel extends ChangeNotifier {
  final RelayRepository _repository;
  final SmsServiceHybrid _smsService;
  // final SmsService _smsService;

  /// Kit ciblé par ce ViewModel (null = tous les relais, compat. mono-kit).
  final String? kitNumber;

  // Liste des relais
  List<RelayModel> _relays = [];
  List<RelayModel> get relays => _relays;

  // Indicateur de chargement
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Etat d'accusé de réception par ligne (mémoire volatile, non persistée)
  final Map<int, bool> _ackReceivedByRelayId = {};

  // Historique horodaté des accusés par ligne (du plus récent au plus ancien),
  // chargé depuis la base et complété en direct à la réception des échos.
  final Map<int, List<RelayAck>> _acksByRelayId = {};

  /// Historique des accusés d'une ligne (plus récent en tête).
  List<RelayAck> acksForRelay(int? relayId) {
    if (relayId == null) return const [];
    return _acksByRelayId[relayId] ?? const [];
  }

  /// Vrai si la ligne possède au moins un accusé enregistré.
  bool hasHistoryForRelay(int? relayId) {
    if (relayId == null) return false;
    return (_acksByRelayId[relayId]?.isNotEmpty) ?? false;
  }

  // Commande en attente de confirmation : id ligne -> état demandé (true = ON).
  // Permet d'afficher « commande envoyée, en attente du kit » sur le bon segment
  // sans modifier l'état réel affiché (qui ne change qu'à l'écho SMS du kit).
  final Map<int, bool> _pendingTargetByRelayId = {};

  // Délai au-delà duquel on cesse d'afficher l'attente si le kit n'a pas
  // répondu (commande quand même envoyée ; on retombe sur le dernier état réel).
  static const Duration _pendingTimeout = Duration(seconds: 60);
  final Map<int, Timer> _pendingTimers = {};

  /// État demandé pour une ligne en attente de l'écho du kit, ou null si aucune
  /// commande n'est en vol pour cette ligne.
  bool? pendingTargetForRelay(int? relayId) {
    if (relayId == null) return null;
    return _pendingTargetByRelayId[relayId];
  }

  bool ackReceivedForRelay(int? relayId) {
    if (relayId == null) return false;
    // Si non présent en mémoire, retomber sur la valeur persistée du modèle
    final inMemory = _ackReceivedByRelayId[relayId];
    if (inMemory != null) return inMemory;
    final model = _relays.firstWhere((r) => r.id == relayId, orElse: () => RelayModel(id: relayId, amperage: 0));
    return model.ackReceived;
  }

  // RelayViewModel(DBService dbService, SmsService smsService)
  //     : _repository = RelayRepository(dbService),
  //       _smsService = smsService {
  //   fetchRelays();
  // }
  RelayViewModel(DBService dbService, SmsServiceHybrid smsService, {this.kitNumber})
      : _repository = RelayRepository(dbService),
        _smsService = smsService {
    fetchRelays();
  }

  /// Charger les relais (du kit ciblé si défini) depuis la base de données
  Future<void> fetchRelays() async {
    _isLoading = true;
    notifyListeners();

    _relays = await _repository.getAllRelays(kitNumber: kitNumber);
    // Trié par id = ordre de création = ordre des lignes dans le kit (Ligne 1..N).
    // La POSITION dans cette liste (1-based) est le NUMÉRO DE LIGNE attendu par
    // le kit (r1..r7) — indépendant de l'id base (qui peut valoir 10, 11, …).
    _relays.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));
    await _loadAckHistory();

    _isLoading = false;
    notifyListeners();
  }

  /// Numéro de ligne (1..N) tel que reconnu par le kit = position de la ligne
  /// dans ce kit (ordre de création), et NON l'id base. Le kit n'accepte que
  /// r1..r7 ; on ne lui envoie donc jamais un numéro construit sur l'id.
  int? _lineNumberOf(RelayModel relay) {
    final idx = _relays.indexWhere((r) => r.id == relay.id);
    return idx == -1 ? null : idx + 1;
  }

  /// (Re)charge l'historique des accusés du kit et le regroupe par ligne.
  Future<void> _loadAckHistory() async {
    final all = await _repository.getAcksForKit(kitNumber);
    _acksByRelayId.clear();
    for (final ack in all) {
      (_acksByRelayId[ack.relayId] ??= <RelayAck>[]).add(ack);
    }
  }

  /// Ajouter un nouveau relais (rattaché au kit ciblé)
  Future<void> addRelay(RelayModel relay) async {
    relay.kitNumber ??= kitNumber;
    await _repository.addRelay(relay);
    _relays.add(relay);
    notifyListeners();
  }

  /// Mettre à jour un relais complet
  Future<void> updateRelay(RelayModel relay) async {
    await _repository.updateRelay(relay);
    final index = _relays.indexWhere((r) => r.id == relay.id);
    if (index != -1) {
      _relays[index] = relay;
      notifyListeners();
    }
  }

  /// Toggle relais (mise à jour DB + envoi SMS)
  Future<void> toggleRelay(RelayModel relay) async {
    if (relay.id == null) return;

    // Changer l'état localement
    relay.isActive = !relay.isActive;

    // 1️⃣ Mettre à jour la DB
    await _repository.updateRelay(relay);

    // 2️⃣ Envoyer le SMS correspondant (par NUMÉRO DE LIGNE du kit, pas l'id)
    // Préparer l'attente d'ACK côté VM (case à cocher désactivée jusqu'à réception)
    _markAckPending(relay.id!);
    final line = _lineNumberOf(relay);
    try {
      if (line == null) throw Exception('Ligne introuvable');
      await _smsService.commandLine(line, relay.isActive);
    } catch (e) {
      // Si échec du SMS, on peut revenir à l'état précédent
      relay.isActive = !relay.isActive;
      await _repository.updateRelay(relay);
      notifyListeners();
      rethrow; // pour gestion côté UI
    }

    notifyListeners();
  }

  /// Commande une ligne vers l'état [on] (bouton ON / OFF dédié).
  ///
  /// IMPORTANT : on **n'altère PAS** l'état affiché (`isActive`) ici. Le kit
  /// peut être piloté par une autre personne ; la seule source de vérité est
  /// l'écho SMS renvoyé par le kit (`rXon` / `rXoff`), traité par
  /// [processIncomingSms]. Cliquer ne fait donc qu'**envoyer la commande** et
  /// marquer la ligne « en attente d'accusé » jusqu'à confirmation réelle.
  Future<void> setRelay(RelayModel relay, bool on) async {
    if (relay.id == null) return;

    // Indique visuellement « commande envoyée, en attente du kit ».
    _pendingTargetByRelayId[relay.id!] = on;
    _armPendingTimeout(relay.id!);
    _markAckPending(relay.id!);
    final line = _lineNumberOf(relay);
    try {
      if (line == null) throw Exception('Ligne introuvable');
      await _smsService.commandLine(line, on); // numéro de ligne kit (1..N)
    } catch (e) {
      // Échec d'envoi : on lève l'attente (rien n'a changé d'état réel).
      _clearPending(relay.id!);
      _ackReceivedByRelayId.remove(relay.id);
      notifyListeners();
      rethrow;
    }
  }

  /// Action groupée : met TOUTES les lignes sur [on] (tout allumer / éteindre).
  /// N'envoie une commande que pour les lignes qui changent réellement d'état,
  /// avec un léger délai entre chaque SMS.
  Future<void> setAllRelays(bool on) async {
    for (final relay in _relays) {
      if (relay.id == null || relay.isActive == on) continue;
      // Pas de mutation optimiste : on commande, l'état suivra l'écho du kit.
      _pendingTargetByRelayId[relay.id!] = on;
      _armPendingTimeout(relay.id!);
      _markAckPending(relay.id!);
      final line = _lineNumberOf(relay);
      try {
        if (line == null) throw Exception('Ligne introuvable');
        await _smsService.commandLine(line, on); // numéro de ligne kit (1..N)
      } catch (_) {
        _clearPending(relay.id!);
        _ackReceivedByRelayId.remove(relay.id);
      }
      await Future.delayed(const Duration(milliseconds: 400));
    }
    notifyListeners();
  }

  /// Supprimer un relais
  Future<void> deleteRelay(int id) async {
    await _repository.deleteRelay(id);
    _relays.removeWhere((r) => r.id == id);
    _acksByRelayId.remove(id);
    notifyListeners();
  }

  /// Supprimer tous les relais
  Future<void> clearRelays() async {
    await _repository.clearRelays();
    _relays.clear();
    notifyListeners();
  }

  /// Mettre à jour uniquement le nom du relais
  Future<void> updateRelayName(int id, String newName) async {
    await _repository.updateRelayName(id, newName);
    final index = _relays.indexWhere((r) => r.id == id);
    if (index != -1) {
      _relays[index].name = newName;
      notifyListeners();
    }
  }

  int get activeRelaysCount {
    return _relays.where((r) => r.isActive).length;
  }

  /// Retourne le nombre de relais inactifs
  int get inactiveRelaysCount {
    return _relays.where((r) => !r.isActive).length;
  }

  /// Arme (ou ré-arme) le délai d'expiration de l'attente pour une ligne.
  void _armPendingTimeout(int relayId) {
    _pendingTimers.remove(relayId)?.cancel();
    _pendingTimers[relayId] = Timer(_pendingTimeout, () {
      _pendingTimers.remove(relayId);
      if (_pendingTargetByRelayId.remove(relayId) != null) {
        notifyListeners();
      }
    });
  }

  /// Lève l'attente d'une ligne (confirmation reçue, échec ou expiration).
  void _clearPending(int relayId) {
    _pendingTimers.remove(relayId)?.cancel();
    _pendingTargetByRelayId.remove(relayId);
  }

  /// Marque une ligne « en attente d'accusé » (case décochée jusqu'à réception).
  void _markAckPending(int relayId) {
    _ackReceivedByRelayId[relayId] = false;
    final index = _relays.indexWhere((r) => r.id == relayId);
    if (index != -1) {
      _relays[index].ackReceived = false;
      _repository.updateRelayAck(relayId, false);
    }
    notifyListeners();
  }

  /// A appeler depuis la couche supérieure lorsqu'un SMS du kit est reçu.
  ///
  /// Le kit renvoie la commande soumise (« rXon » / « rXoff »). On reflète
  /// l'état réel ON/OFF de la ligne concernée — que cette app ait initié
  /// l'action ou non — afin que tous les numéros autorisés restent synchronisés.
  void processIncomingSms(String message) {
    if (message.isEmpty) return;
    final lower = message.toLowerCase();
    bool changed = false;
    final matches = RegExp(r'r(\d+)\s*(on|off)').allMatches(lower);
    for (final m in matches) {
      // Le kit renvoie « rN » où N = NUMÉRO DE LIGNE (1..N), pas l'id base.
      final line = int.tryParse(m.group(1)!);
      if (line == null || line < 1 || line > _relays.length) continue;
      final relay = _relays[line - 1]; // _relays trié par id => position = ligne
      final relayId = relay.id;
      if (relayId == null) continue;
      final isOn = m.group(2) == 'on';
      relay.isActive = isOn;
      relay.ackReceived = true;
      _ackReceivedByRelayId[relayId] = true;
      _clearPending(relayId); // confirmation reçue : on lève l'attente + timer
      // Retour visuel instantané : on reflète l'état réel confirmé par le kit.
      _repository.applyKitAck(relayId, isActive: isOn, kitNumber: kitNumber);
      changed = true;
    }
    // IMPORTANT — l'HISTORISATION de l'accusé (journal horodaté + texte brut)
    // est délibérément confiée au SEUL chemin natif d'arrière-plan
    // (SmsInboxProcessor), pour deux raisons :
    //   1) il s'exécute aussi quand l'app est fermée ou sur un autre onglet ;
    //   2) il draine chaque SMS exactement une fois.
    // Ce widget premier-plan, lui, réémet le même SMS à chaque reconstruction
    // (StreamBuilder) : s'il journalisait, il faudrait déduplicquer, et c'est
    // cette déduplication par fenêtre temporelle qui écrasait les RÉPÉTITIONS
    // d'une même commande. En laissant le natif comme écrivain unique, rejouer
    // la même commande est désormais capturé à chaque fois.
    if (changed) notifyListeners();
  }

  @override
  void dispose() {
    for (final t in _pendingTimers.values) {
      t.cancel();
    }
    _pendingTimers.clear();
    super.dispose();
  }
}
