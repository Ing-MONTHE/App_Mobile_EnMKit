import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:enmkit/core/qr_service.dart';

class QrPage extends StatefulWidget {
  final QrService qrService;

  const QrPage({super.key, required this.qrService});

  @override
  State<QrPage> createState() => _QrPageState();
}

class _QrPageState extends State<QrPage> {
  final ScreenshotController _screenshotController = ScreenshotController();

  Future<void> _shareQrCode() async {
    final Uint8List? image = await _screenshotController.capture();
    if (image != null) {
      final directory = await getTemporaryDirectory();
      final imagePath = File("${directory.path}/qr.png");
      await imagePath.writeAsBytes(image);

      await Share.shareXFiles(
        [XFile(imagePath.path)],
        text: "Voici mon QR Code du Kit 🔌📱",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<Widget>(
            future: widget.qrService.generateQrWidget(size: 220),
            builder: (context, snapshot) {
              Widget qrContent;
              if (snapshot.connectionState == ConnectionState.waiting) {
                qrContent = const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                qrContent = Center(child: Text("Erreur : ${snapshot.error}"));
              } else {
                qrContent = snapshot.data ??
                    const Icon(Icons.qr_code, size: 150, color: Colors.grey);
              }

              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "QR Code du Kit",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey.shade800,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Screenshot(
                      controller: _screenshotController,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 15,
                              spreadRadius: 2,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: qrContent,
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        elevation: 4,
                      ),
                      onPressed: _shareQrCode,
                      icon: const Icon(Icons.share_rounded),
                      label: const Text("Partager"),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
