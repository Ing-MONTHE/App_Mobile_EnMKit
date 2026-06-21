import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:enmkit/core/qr_service.dart';
import 'package:enmkit/providers.dart';
import 'package:enmkit/ui/theme/app_theme.dart';
import 'package:enmkit/ui/widgets/common/brand_loader.dart';

/// Affiche le QR Code d'un kit (export) avec une présentation soignée :
/// carte blanche surélevée, libellé, et partage en image.
class QrPage extends ConsumerStatefulWidget {
  final QrService qrService;

  /// Si fourni, le QR n'encode que ce kit (export multi-kits).
  final String? kitNumber;

  const QrPage({super.key, required this.qrService, this.kitNumber});

  @override
  ConsumerState<QrPage> createState() => _QrPageState();
}

class _QrPageState extends ConsumerState<QrPage> {
  final ScreenshotController _screenshotController = ScreenshotController();

  Future<void> _shareQrCode() async {
    final Uint8List? image = await _screenshotController.capture();
    if (image != null) {
      final directory = await getTemporaryDirectory();
      final imagePath = File("${directory.path}/qr.png");
      await imagePath.writeAsBytes(image);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(imagePath.path)],
          text: ref.read(tProvider).t('qr.shareText'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = ref.watch(tProvider);
    return Scaffold(
      appBar: AppBar(title: Text(t.t('qr.title'))),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.surface,
              AppTheme.brandBlue.withValues(alpha: 0.06),
            ],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<Widget>(
            future: widget.qrService
                .generateQrWidget(size: 220, kitNumber: widget.kitNumber),
            builder: (context, snapshot) {
              Widget qrContent;
              if (snapshot.connectionState == ConnectionState.waiting) {
                qrContent = const SizedBox(
                  width: 220,
                  height: 220,
                  child: BrandLoader(size: 72),
                );
              } else if (snapshot.hasError) {
                qrContent = SizedBox(
                  width: 220,
                  height: 220,
                  child: Center(
                      child: Text(t.tf('qr.error', [snapshot.error ?? '']))),
                );
              } else {
                qrContent = snapshot.data ??
                    const Icon(Icons.qr_code, size: 150, color: Colors.grey);
              }

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        t.t('qr.scanToImport'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 24),
                      Screenshot(
                        controller: _screenshotController,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.brandBlue.withValues(alpha: 0.15),
                                blurRadius: 30,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: qrContent,
                        ),
                      ),
                      const SizedBox(height: 32),
                      FilledButton.icon(
                        onPressed: _shareQrCode,
                        icon: const Icon(Icons.share_rounded),
                        label: Text(t.t('qr.share')),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
