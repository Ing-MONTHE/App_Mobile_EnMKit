import 'package:enmkit/core/utils/sms_parser.dart';
import 'package:enmkit/providers.dart';
import 'package:enmkit/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Clôture de configuration : geste PARTAGÉ entre l'onglet Config et la carte
/// du kit dans la liste, pour que la validation soit rigoureusement la même des
/// deux côtés (même message envoyé, même état persisté, mêmes retours visuels).
///
/// Déroulé : le kit a renvoyé la trame reçue et elle concorde → l'utilisateur
/// valide → l'application envoie « Fin_config », ce qui CLÔT la configuration.

/// Garde anti-empilement : une seule confirmation à l'écran à la fois.
bool _finalizeDialogOpen = false;

/// Popup de confirmation, puis envoi de la validation si l'utilisateur accepte.
///
/// Fermer la popup sans valider ne fait RIEN perdre : l'état « à valider » est
/// persisté, donc le bandeau et le badge restent disponibles pour rattraper.
Future<void> askAndFinalizeConfig(
  BuildContext context,
  WidgetRef ref,
  String kitNumber,
) async {
  // Déjà une confirmation à l'écran, ou plus rien à valider (un autre chemin
  // vient de le faire) : on n'ouvre pas.
  if (_finalizeDialogOpen) return;
  final vm = ref.read(kitProvider);
  await vm.fetchKits(); // l'état fait foi en base (écho reçu app fermée)
  if (!vm.isConfigAckPending(kitNumber)) return;
  if (!context.mounted) return;

  // Trame confirmée par le kit : relue ici pour être présentée en clair.
  final pending = vm.kitByNumber(kitNumber)?.pendingConfigMsg ?? '';
  final t = ref.read(tProvider);
  _finalizeDialogOpen = true;
  final bool? confirmed;
  try {
    confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            icon: const Icon(
              Icons.verified_rounded,
              color: AppTheme.success,
              size: 30,
            ),
            title: Text(t.t('config.finalizeTitle')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.t('config.finalizeBody'),
                      style: const TextStyle(fontSize: 13.5, height: 1.3)),
                  const SizedBox(height: 12),
                  // Ce que le kit a confirmé, une information PAR LIGNE. La
                  // trame brute n'a aucun sens pour l'utilisateur : ce sont ces
                  // valeurs-là qu'il doit relire avant de verrouiller.
                  ..._detailRows(t, pending),
                  const SizedBox(height: 12),
                  Text(t.t('config.finalizeCheck'),
                      style: const TextStyle(fontSize: 12.5, height: 1.35)),
                  const SizedBox(height: 10),
                  // Avertissement SOBRE mais explicite : on ne laisse pas
                  // l'utilisateur clore la configuration sans savoir que le
                  // geste est sans retour pour lui.
                  _FinalizeWarning(text: t.t('config.finalizeWarning')),
                ],
              ),
            ),
            actions: [
              // Annuler ramène à la configuration : rien n'est perdu, l'état
              // « à valider » reste et l'utilisateur peut corriger puis
              // renvoyer avant de verrouiller.
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(t.t('common.cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(t.t('config.finalizeCta')),
              ),
            ],
          ),
    );
  } finally {
    _finalizeDialogOpen = false;
  }
  if (confirmed != true) return;
  if (!context.mounted) return;
  await finalizeConfigNow(context, ref, kitNumber);
}

/// Traduit la trame confirmée en lignes lisibles : un libellé, une valeur.
/// Un champ vide s'affiche « aucun » plutôt que de disparaître, pour que
/// l'utilisateur voie bien qu'il n'est pas renseigné.
List<Widget> _detailRows(dynamic t, String frame) {
  final pairs = SmsParser.parseSentConfig(frame);
  if (pairs.isEmpty) return const [];
  String v(String k) {
    final raw = pairs[k] ?? '';
    return raw.isEmpty ? t.t('config.preview.none') : raw;
  }

  return [
    _DetailRow(label: t.t('config.preview.n1'), value: v('n1')),
    _DetailRow(label: t.t('config.preview.n2'), value: v('n2')),
    _DetailRow(label: t.t('config.preview.en'), value: "${v('en')} kWh"),
    _DetailRow(label: t.t('config.preview.ip'), value: v('ip')),
  ];
}

/// Une information de configuration : libellé à gauche, valeur à droite.
class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(label,
                style: TextStyle(
                    fontSize: 12.5, color: scheme.onSurfaceVariant)),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Envoie « Fin_config » puis efface l'état « à valider » du kit.
///
/// En cas d'échec d'envoi, l'état est VOLONTAIREMENT conservé : le bandeau et
/// le badge restent, et l'utilisateur peut réessayer. On ne clôt jamais une
/// configuration dont la validation n'est pas réellement partie.
Future<void> finalizeConfigNow(
  BuildContext context,
  WidgetRef ref,
  String kitNumber,
) async {
  final t = ref.read(tProvider);
  final kitVM = ref.read(kitProvider);
  // L'écho a pu être reconnu APPLICATION FERMÉE : l'état fait foi EN BASE, pas
  // dans la copie mémoire. On resynchronise avant de décider.
  await kitVM.fetchKits();
  // IDEMPOTENCE : si la validation est déjà partie (double appui, ou deux
  // chemins qui aboutissent en même temps), on ne renvoie pas un second SMS.
  if (!kitVM.isConfigAckPending(kitNumber)) return;
  try {
    await ref.read(kitSmsServiceProvider(kitNumber)).applyConfiguration();
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.tf('config.finalizeError', [e]))),
      );
    }
    return;
  }
  await kitVM.clearPendingConfig(kitNumber);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(t.t('config.finalized')),
      backgroundColor: AppTheme.success,
    ),
  );
}

/// Mention discrète rappelant que la validation ferme définitivement les mises
/// à jour de configuration. Volontairement sobre (pas d'alerte rouge) : c'est
/// une information, pas un obstacle.
class _FinalizeWarning extends StatelessWidget {
  const _FinalizeWarning({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lock_outline_rounded,
            size: 15, color: scheme.onSurfaceVariant),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
