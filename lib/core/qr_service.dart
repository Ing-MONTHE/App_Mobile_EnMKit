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

  /// Génère le JSON complet pour le QR Code
  Future<String> generateQrData() async {
    // 1️⃣ Récupérer les données du kit
    final kit = await kitRepo.getKit();

    // 2️⃣ Récupérer les relais
    final relays = await relayRepo.getAllRelays();

    // 3️⃣ Récupérer les numéros autorisés
    final allowedUsers = await allowedRepo.getAllNumbers();

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
  Future<String> generateQrDataBase64() async {
    final jsonData = await generateQrData();
    final bytes = utf8.encode(jsonData);
    return base64Encode(bytes);
  }

  /// Widget PrettyQr généré à partir du JSON
  Future<Widget> generateQrWidget({double size = 200}) async {
    final qrData = await generateQrData();

    return PrettyQr(
      data: qrData,
      size: size,
      roundEdges: true,
      // typeNumber retiré : PrettyQr choisit automatiquement la version
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );
  }
}
