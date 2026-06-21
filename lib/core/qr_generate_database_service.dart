import 'dart:convert';

import 'package:enmkit/models/allowed_number_model.dart';
import 'package:enmkit/models/kit_model.dart';
import 'package:enmkit/models/relay_model.dart';
import 'package:enmkit/repositories/allowed_number_repository.dart';
import 'package:enmkit/repositories/kit_repository.dart';
import 'package:enmkit/repositories/relay_repository.dart';

class DatabaseRegenerator {
  final KitRepository kitRepo;
  final RelayRepository relayRepo;
  final AllowedNumberRepository allowedRepo;

  DatabaseRegenerator({
    required this.kitRepo,
    required this.relayRepo,
    required this.allowedRepo,
  });

  /// Importe un kit depuis un JSON de QR Code, de façon **multi-kits sûre** :
  /// on ne réinitialise QUE le kit importé et ses entités rattachées
  /// (relais, numéros autorisés) ; les autres kits sont préservés.
  ///
  /// Retourne le [KitModel] importé.
  Future<KitModel> regenerateFromJson(String jsonText) async {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonText);

      // --- 1. Kit (upsert : on n'efface pas les autres kits) ---
      if (!data.containsKey('kit')) {
        throw Exception('QR Code invalide : aucun kit trouvé');
      }
      final kits = data['kit'] as List<dynamic>;
      if (kits.isEmpty) {
        throw Exception('QR Code invalide : kit vide');
      }
      final kit = KitModel.fromMap(kits.first as Map<String, dynamic>);
      final kitNumber = kit.kitNumber;

      final existing = await kitRepo.getKit();
      final alreadyPresent =
          existing.any((k) => k.kitNumber == kitNumber);
      if (alreadyPresent) {
        await kitRepo.updateKit(kit);
      } else {
        await kitRepo.addKit(kit);
      }

      // --- 2. Relais : on remplace ceux de CE kit uniquement ---
      if (data.containsKey('relays')) {
        final relaysData = data['relays'] as List<dynamic>;
        await relayRepo.clearRelays(kitNumber: kitNumber);
        for (final r in relaysData) {
          final relay = RelayModel.fromMap(r as Map<String, dynamic>);
          relay.kitNumber = kitNumber; // garantit le rattachement au bon kit
          relay.id = null; // laisse SQLite régénérer l'id
          await relayRepo.addRelay(relay);
        }
      }

      // --- 3. Numéros autorisés : on remplace ceux de CE kit uniquement ---
      if (data.containsKey('allowedUsers')) {
        final usersData = data['allowedUsers'] as List<dynamic>;
        await allowedRepo.clearAllowedNumbers(kitNumber: kitNumber);
        for (final u in usersData) {
          final user = AllowedNumberModel.fromMap(u as Map<String, dynamic>);
          user.kitNumber = kitNumber;
          user.id = null;
          await allowedRepo.addNumber(user);
        }
      }

      return kit;
    } catch (e) {
      throw Exception("Erreur lors de l'import du kit : $e");
    }
  }
}
