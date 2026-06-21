import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../repositories/kit_repository.dart';
import '../repositories/relay_repository.dart';
import '../repositories/allowed_number_repository.dart';

class QrService {
  final KitRepository kitRepo;
  final RelayRepository relayRepo;
  final AllowedNumberRepository allowedRepo;

  QrService({
    required this.kitRepo,
    required this.relayRepo,
    required this.allowedRepo,
  });

  /// Génère le JSON du QR Code. Si [kitNumber] est fourni, n'exporte QUE ce kit
  /// et ses entités rattachées (relais, numéros autorisés) — export multi-kits.
  Future<String> generateQrData({String? kitNumber}) async {
    // 1️⃣ Récupérer le(s) kit(s) — filtré sur le kit ciblé si demandé
    final allKits = await kitRepo.getKit();
    final kit = kitNumber == null
        ? allKits
        : allKits.where((k) => k.kitNumber == kitNumber).toList();

    // 2️⃣ Récupérer les relais du kit
    final relays = await relayRepo.getAllRelays(kitNumber: kitNumber);

    // 3️⃣ Récupérer les numéros autorisés du kit
    final allowedUsers = await allowedRepo.getAllNumbers(kitNumber: kitNumber);

    // 4️⃣ Créer un objet complet
    final qrObject = {
      'kit': kit.map((k) => k.toMap()).toList(),
      'relays': relays.map((r) => r.toMap()).toList(),
      'allowedUsers': allowedUsers.map((u) => u.toMap()).toList(),
    };

    // 5️⃣ Convertir en JSON
    return jsonEncode(qrObject);
  }

  /// Génère le QR Code en Base64 (optionnel, utile pour stockage ou partage)
  Future<String> generateQrDataBase64({String? kitNumber}) async {
    final jsonData = await generateQrData(kitNumber: kitNumber);
    final bytes = utf8.encode(jsonData);
    return base64Encode(bytes);
  }

  /// Widget PrettyQr généré à partir du JSON
  Future<Widget> generateQrWidget({double size = 200, String? kitNumber}) async {
    final qrData = await generateQrData(kitNumber: kitNumber);

    return SizedBox(
      width: size,
      height: size,
      child: PrettyQrView.data(
        data: qrData,
        errorCorrectLevel: QrErrorCorrectLevel.M,
        // Coins arrondis (équivalent de l'ancien roundEdges: true).
        decoration: const PrettyQrDecoration(
          shape: PrettyQrSmoothSymbol(),
        ),
      ),
    );
  }
}
