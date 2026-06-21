import 'package:enmkit/models/allowed_number_model.dart';
import 'package:enmkit/models/kit_model.dart';
import 'package:enmkit/providers.dart';
import 'package:enmkit/ui/screens/qr_screen.dart';
import 'package:enmkit/ui/theme/app_theme.dart';
import 'package:enmkit/ui/widgets/common/app_sheet.dart';
import 'package:enmkit/ui/widgets/common/soft_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Onglet Configuration : paramètres du kit, numéros autorisés, envoi de la
/// configuration par SMS et génération du QR Code (scopé sur [kit]).
class ConfigTab extends ConsumerWidget {
  const ConfigTab({super.key, required this.kit});
  final KitModel kit;

  String? get _kitNumber => kit.kitNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kitVM = ref.watch(kitProvider);
    final current = kitVM.kits.firstWhere(
      (k) => k.kitNumber == kit.kitNumber,
      orElse: () => kit,
    );
    final allowedVM = ref.watch(kitAllowedNumbersProvider(_kitNumber));
    final t = ref.watch(tProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        _SectionCard(
          title: t.t('config.kitInfo'),
          icon: Icons.info_rounded,
          accent: AppTheme.brandBlue,
          onEdit: () => _editInfo(context, ref, current),
          children: [
            _InfoRow(
              icon: Icons.label_outline_rounded,
              label: t.t('config.name'),
              value: current.displayName,
            ),
            _InfoRow(
              icon: Icons.sim_card_outlined,
              label: t.t('config.gsm'),
              value: current.kitNumber ?? t.t('config.notSet'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: t.t('config.meter'),
          icon: Icons.speed_rounded,
          accent: AppTheme.mint,
          onEdit: () => _editCounter(context, ref, current),
          children: [
            _InfoRow(
              icon: Icons.timeline_rounded,
              label: t.t('config.pulses'),
              value: '${current.pulseCount ?? 0}',
            ),
            _InfoRow(
              icon: Icons.speed_rounded,
              label: t.t('config.initialCons'),
              value: '${current.initialConsumption ?? 0} kWh',
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Le kit ne gère que DEUX numéros : deux champs fixes (pas de bouton +).
        _AllowedNumbersSection(kitNumber: _kitNumber),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => _sendConfig(context, ref, current, allowedVM.allowedNumbers),
          icon: const Icon(Icons.send_rounded),
          label: Text(t.t('config.sendConfig')),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _openQr(context, ref),
          icon: const Icon(Icons.qr_code_rounded),
          label: Text(t.t('config.genQr')),
        ),
      ],
    );
  }

  // ---- Actions -------------------------------------------------------------

  /// Édition des infos du kit : nom + numéro GSM (la modif du numéro répercute
  /// sur relais/conso/numéros). Confirmation avant d'appliquer (action délicate).
  Future<void> _editInfo(BuildContext context, WidgetRef ref, KitModel kit) async {
    final nameC = TextEditingController(text: kit.name);
    final numberC = TextEditingController(text: kit.kitNumber ?? '');
    final t = ref.read(tProvider);
    final oldNumber = kit.kitNumber;

    await showAppSheet<void>(
      context: context,
      icon: Icons.info_rounded,
      title: t.t('config.editInfo'),
      subtitle: t.t('config.editInfo.sub'),
      accent: AppTheme.brandBlue,
      builder: (ctx) => Column(
        children: [
          SheetField(
            controller: nameC,
            label: t.t('kits.name'),
            hint: t.t('kits.name.hint'),
            icon: Icons.label_outline_rounded,
            textCapitalization: TextCapitalization.words,
            autofocus: true,
          ),
          const SizedBox(height: 16),
          SheetField(
            controller: numberC,
            label: t.t('kits.gsm'),
            hint: t.t('config.gsm.hint'),
            icon: Icons.sim_card_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                final newName = nameC.text.trim();
                final newNumber = numberC.text.trim();
                if (newNumber.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(t.t('kits.gsm.required'))),
                  );
                  return;
                }
                final confirmed = await _confirm(
                  ctx, t,
                  title: t.t('config.editInfo.confirm'),
                  cta: t.t('common.save'),
                );
                if (confirmed != true) return;

                final updated = kit.copyWith(
                  name: newName.isEmpty ? null : newName,
                  kitNumber: newNumber,
                );
                if (oldNumber != null && oldNumber != newNumber) {
                  await ref.read(kitProvider).changeKitNumber(oldNumber, updated);
                } else {
                  await ref.read(kitProvider).updateKit(updated);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              icon: const Icon(Icons.check_rounded),
              label: Text(t.t('common.save')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editCounter(BuildContext context, WidgetRef ref, KitModel kit) async {
    final pulses = TextEditingController(text: '${kit.pulseCount ?? ''}');
    final initial =
        TextEditingController(text: '${kit.initialConsumption ?? ''}');
    final t = ref.read(tProvider);

    await showAppSheet<void>(
      context: context,
      icon: Icons.speed_rounded,
      title: t.t('config.meterTitle'),
      subtitle: t.t('config.meter.sub'),
      accent: AppTheme.emerald,
      builder: (ctx) => Column(
        children: [
          SheetField(
            controller: pulses,
            label: t.t('config.pulses.label'),
            hint: t.t('config.pulses.hint'),
            icon: Icons.timeline_rounded,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          SheetField(
            controller: initial,
            label: t.t('config.initial.label'),
            hint: t.t('config.initial.hint'),
            icon: Icons.bolt_rounded,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                final confirmed = await _confirm(
                  ctx, t,
                  title: t.t('config.editInfo.confirm'),
                  cta: t.t('common.save'),
                );
                if (confirmed != true) return;
                await ref.read(kitProvider).updateKit(
                      kit.copyWith(
                        pulseCount: int.tryParse(pulses.text.trim()),
                        initialConsumption:
                            double.tryParse(initial.text.trim()),
                      ),
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              icon: const Icon(Icons.check_rounded),
              label: Text(t.t('common.save')),
            ),
          ),
        ],
      ),
    );
  }

  /// Confirmation générique avant une action délicate (édition/suppression).
  Future<bool?> _confirm(
    BuildContext context,
    dynamic t, {
    required String title,
    required String cta,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.t('common.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(cta),
          ),
        ],
      ),
    );
  }

  /// Aperçu de la configuration AVANT envoi : récapitulatif lisible + message
  /// SMS brut, avec un bouton de validation explicite. Retourne true si l'on
  /// confirme l'envoi.
  Future<bool?> _previewConfig(
    BuildContext context,
    dynamic t, {
    required String? firstPhone,
    required String? secondPhone,
    required double consInitial,
    required int pulsation,
    required String raw,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.fact_check_rounded,
            color: AppTheme.brandBlue, size: 30),
        title: Text(t.t('config.preview.title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.t('config.preview.sub'),
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 14),
            _PreviewRow(
              label: t.t('config.preview.n1'),
              value: (firstPhone == null || firstPhone.isEmpty)
                  ? t.t('config.preview.none')
                  : firstPhone,
            ),
            if (secondPhone != null && secondPhone.isNotEmpty)
              _PreviewRow(label: t.t('config.preview.n2'), value: secondPhone),
            _PreviewRow(
                label: t.t('config.preview.en'), value: '$consInitial kWh'),
            _PreviewRow(label: t.t('config.preview.ip'), value: '$pulsation'),
            const SizedBox(height: 14),
            // Message SMS exact qui sera transmis.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                raw,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12.5,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.t('common.cancel')),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.send_rounded, size: 18),
            label: Text(t.t('config.preview.send')),
          ),
        ],
      ),
    );
  }

  Future<void> _sendConfig(
    BuildContext context,
    WidgetRef ref,
    KitModel kit,
    List<AllowedNumberModel> numbers,
  ) async {
    final sms = ref.read(kitSmsServiceProvider(_kitNumber));
    final listener = ref.read(kitSmsListenerProvider(_kitNumber));
    final t = ref.read(tProvider);

    final firstPhone = numbers.isNotEmpty ? numbers.first.phoneNumber : null;
    final secondPhone = numbers.length > 1 ? numbers[1].phoneNumber : null;
    final consInitial = kit.initialConsumption ?? 0.0;
    final pulsation = kit.pulseCount ?? 0;

    // 0) APERÇU + validation explicite : on montre exactement ce qui partira au
    //    kit, et on n'envoie (donc on ne consomme un SMS) qu'après confirmation.
    final rawMessage = sms.buildConcatenatedConfig(
      firstPhone: firstPhone,
      secondPhone: secondPhone,
      initialConsumption: consInitial,
      pulsation: pulsation,
    );
    final confirmed = await _previewConfig(
      context,
      t,
      firstPhone: firstPhone,
      secondPhone: secondPhone,
      consInitial: consInitial,
      pulsation: pulsation,
      raw: rawMessage,
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    // Le kit ré-écho la config reçue (écho d'accusé), mais avec un FORMAT
    // VARIABLE (espaces, casse, « kWh » en suffixe, entier au lieu de décimal).
    // On attend donc chaque paire clé→valeur envoyée et on compare de façon
    // TOLÉRANTE (cf. waitForConfigAck), ce qui confirme la réception ET les
    // bonnes valeurs sans casser sur une simple différence de format.
    final raw = sms.generateExpectedMessages(
      firstPhone: firstPhone,
      secondPhone: secondPhone,
      initialConsumption: consInitial,
      pulsation: pulsation,
    );
    // {clé: "clé:valeur"} -> {clé: "valeur"} (on retire le préfixe « clé: »).
    final expected = {
      for (final e in raw.entries) e.key: e.value.substring(e.key.length + 1),
    };

    // On s'abonne AVANT l'envoi pour ne manquer aucun accusé arrivant tôt.
    // Délai large : un aller-retour SMS réel (surtout réseau chargé) peut
    // dépasser une minute.
    final ackFuture = listener.waitForConfigAck(
      expected,
      totalTimeout: const Duration(seconds: 120),
    );

    try {
      await sms.sendConcatenatedSystemConfig(
        firstPhone: firstPhone,
        secondPhone: secondPhone,
        initialConsumption: consInitial,
        pulsation: pulsation,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.tf('config.sendError', [e]))),
        );
      }
      return;
    }

    if (!context.mounted) return;

    // Dialogue d'attente bloquant pendant que le kit confirme par SMS.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AckWaitDialog(message: t.t('config.waitingAck')),
    );

    final ok = await ackFuture;

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // ferme le dialogue d'attente

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? t.t('config.ackOk') : t.t('config.ackTimeout')),
        backgroundColor: ok ? AppTheme.success : null,
      ),
    );
  }

  void _openQr(BuildContext context, WidgetRef ref) {
    final qrService = ref.read(qrServiceProvider);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QrPage(qrService: qrService, kitNumber: _kitNumber),
      ),
    );
  }

}

/// Section « Numéros autorisés » : DEUX champs fixes (le kit ne gère que deux
/// numéros), pré-remplis depuis les numéros enregistrés, avec un bouton
/// d'enregistrement. Plus de bouton « + » ni de liste dynamique.
class _AllowedNumbersSection extends ConsumerStatefulWidget {
  const _AllowedNumbersSection({required this.kitNumber});
  final String? kitNumber;

  @override
  ConsumerState<_AllowedNumbersSection> createState() =>
      _AllowedNumbersSectionState();
}

class _AllowedNumbersSectionState
    extends ConsumerState<_AllowedNumbersSection> {
  final _c1 = TextEditingController();
  final _c2 = TextEditingController();
  bool _prefilled = false;

  @override
  void dispose() {
    _c1.dispose();
    _c2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(tProvider);
    final vm = ref.watch(kitAllowedNumbersProvider(widget.kitNumber));
    // Pré-remplissage une seule fois, dès que les numéros sont chargés.
    if (!_prefilled && vm.allowedNumbers.isNotEmpty) {
      _prefilled = true;
      final nums = vm.allowedNumbers;
      _c1.text = nums.isNotEmpty ? nums[0].phoneNumber : '';
      _c2.text = nums.length > 1 ? nums[1].phoneNumber : '';
    }

    return _SectionCard(
      title: t.t('config.allowed'),
      icon: Icons.contacts_rounded,
      accent: AppTheme.lavender,
      children: [
        const SizedBox(height: 4),
        SheetField(
          controller: _c1,
          label: t.t('config.preview.n1'),
          hint: t.t('config.gsm.hint'),
          icon: Icons.phone_android_rounded,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        SheetField(
          controller: _c2,
          label: t.t('config.preview.n2'),
          hint: t.t('config.gsm.hint'),
          icon: Icons.phone_android_rounded,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () async {
              await ref
                  .read(kitAllowedNumbersProvider(widget.kitNumber))
                  .setTwoNumbers(_c1.text, _c2.text);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t.t('config.numbers.saved'))),
                );
              }
            },
            icon: const Icon(Icons.check_rounded, size: 18),
            label: Text(t.t('common.save')),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.accent,
    required this.children,
    this.onEdit,
  });
  final String title;
  final IconData icon;
  final Color accent;
  final List<Widget> children;

  /// Bouton d'édition au niveau de la section (en-tête) au lieu de chaque ligne.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconPill(icon: icon, color: accent, size: 32),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (onEdit != null)
                _SectionEditButton(accent: accent, onTap: onEdit!),
            ],
          ),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }
}

/// Petit bouton d'édition discret en pastille (en-tête de section).
class _SectionEditButton extends StatelessWidget {
  const _SectionEditButton({required this.accent, required this.onTap});
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accent.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(Icons.edit_rounded, size: 17, color: accent),
        ),
      ),
    );
  }
}

/// Ligne « libellé : valeur » dans l'aperçu de configuration.
class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label : ',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13.5)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 19, color: scheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                  fontSize: 13.5, color: scheme.onSurfaceVariant)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 14.5, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialogue d'attente affiché pendant que le kit confirme la configuration
/// par SMS (accusés de réception). Non annulable : se ferme à la réception
/// de tous les accusés ou à l'expiration du délai côté appelant.
class _AckWaitDialog extends StatelessWidget {
  const _AckWaitDialog({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      content: Row(
        children: [
          SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2.6,
              valueColor: AlwaysStoppedAnimation(scheme.primary),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
