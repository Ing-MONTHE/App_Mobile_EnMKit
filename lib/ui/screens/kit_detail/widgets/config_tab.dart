import 'package:enmkit/models/allowed_number_model.dart';
import 'package:enmkit/models/kit_model.dart';
import 'package:enmkit/providers.dart';
import 'package:enmkit/ui/screens/qr_screen.dart';
import 'package:enmkit/ui/theme/app_theme.dart';
import 'package:enmkit/viewmodels/sms_viewmodel.dart';
import 'package:enmkit/ui/widgets/common/app_sheet.dart';
import 'package:enmkit/ui/widgets/common/config_finalize.dart';
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

    // Écho de configuration reçu PENDANT que cet écran est ouvert, hors de la
    // fenêtre d'attente de l'envoi (le kit peut répondre bien plus tard) : on
    // ouvre la confirmation sans attendre que l'utilisateur revienne.
    ref.listen<SmsListenerViewModel>(kitSmsListenerProvider(_kitNumber),
        (prev, next) {
      if (!next.configEchoPending) return;
      next.clearConfigEchoSignal();
      final number = _kitNumber;
      if (number == null) return;
      // La persistance DOIT précéder l'ouverture : la popup ne s'affiche que si
      // le kit est réellement « à valider ».
      kitVM.markConfigAckPending(number).then((_) {
        // Jamais de dialogue pendant la phase de construction.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) askAndFinalizeConfig(context, ref, number);
        });
      });
    });

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        // VOLET D'ÉTAT : où en est la configuration face au kit.
        //  • verrouillée   → plus aucune config possible (cadenas)
        //  • OK            → le retour du kit correspond : bouton de validation
        //  • en cours      → envoyée, le kit n'a pas encore répondu
        if (_kitNumber != null) ...[
          _ConfigStatusCard(
            kit: current,
            onFinalize: () => finalizeConfigNow(context, ref, _kitNumber!),
          ),
          const SizedBox(height: 16),
        ],
        _SectionCard(
          title: t.t('config.kitInfo'),
          icon: Icons.info_rounded,
          accent: AppTheme.brandBlue,
          locked: current.configSent,
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
          locked: current.configSent,
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
        _AllowedNumbersSection(
          kitNumber: _kitNumber,
          locked: current.configSent,
        ),
        const SizedBox(height: 24),
        // Verrouillée : plus aucun envoi de configuration possible. Le bouton
        // disparaît au lieu d'être grisé : il n'y a plus rien à tenter.
        if (!current.configSent)
          FilledButton.icon(
            onPressed: () =>
                _sendConfig(context, ref, current, allowedVM.allowedNumbers),
            icon: const Icon(Icons.send_rounded),
            label: Text(t.t('config.sendConfig')),
          ),
        if (!current.configSent) const SizedBox(height: 12),
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
                // Impulsion par kWh : 0 (ou négatif) n'est pas admissible.
                final pulseText = pulses.text.trim();
                final pulseCount = int.tryParse(pulseText);
                if (pulseText.isNotEmpty &&
                    (pulseCount == null || pulseCount <= 0)) {
                  await _invalidPulses(ctx, t);
                  return;
                }
                final confirmed = await _confirm(
                  ctx, t,
                  title: t.t('config.editInfo.confirm'),
                  cta: t.t('common.save'),
                );
                if (confirmed != true) return;
                await ref.read(kitProvider).updateKit(
                      kit.copyWith(
                        pulseCount: pulseCount,
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

  /// Signale une impulsion par kWh non admissible (vide à l'envoi, 0 ou négative).
  Future<void> _invalidPulses(BuildContext context, dynamic t) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.error_outline_rounded,
            color: AppTheme.amber, size: 30),
        content: Text(t.t('config.pulses.invalid')),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
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
            // Toujours affichée : le champ part dans la trame même vide
            // (« n2:: »), l'aperçu doit donc raconter la même chose que le
            // message brut montré juste en dessous.
            _PreviewRow(
              label: t.t('config.preview.n2'),
              value: (secondPhone == null || secondPhone.isEmpty)
                  ? t.t('config.preview.none')
                  : secondPhone,
            ),
            _PreviewRow(
                label: t.t('config.preview.en'), value: '$consInitial kWh'),
            _PreviewRow(label: t.t('config.preview.ip'), value: '$pulsation'),
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
    final t = ref.read(tProvider);

    final firstPhone = numbers.isNotEmpty ? numbers.first.phoneNumber : null;
    final secondPhone = numbers.length > 1 ? numbers[1].phoneNumber : null;
    final consInitial = kit.initialConsumption ?? 0.0;
    final pulsation = kit.pulseCount ?? 0;

    // Impulsion par kWh non renseignée ou à 0 : on n'envoie pas « ip:0 » au kit.
    if (pulsation <= 0) {
      await _invalidPulses(context, t);
      return;
    }

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
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    // ENVOI SANS BLOCAGE. Le kit peut mettre plusieurs minutes à répondre
    // (mesuré : 3 min 47 s) : un dialogue d'attente modal emprisonnait
    // l'utilisateur, et l'écho arrivait après expiration. Désormais l'écho est
    // reconnu par les chemins de réception, y compris application fermée, et
    // c'est le volet « État de la configuration » qui prend le relais.
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

    // Trame envoyée MÉMORISÉE en base : c'est elle qui permettra de reconnaître
    // l'écho du kit, y compris s'il arrive application fermée.
    if (_kitNumber != null) {
      await ref.read(kitProvider).setPendingConfig(_kitNumber!, rawMessage);
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.t('config.sentWaiting'))),
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

/// Section « Numéros autorisés » : DEUX numéros (le kit n'en gère pas plus),
/// chacun validé INDIVIDUELLEMENT par un bouton placé juste à sa droite.
///
/// Ergonomie alignée sur l'édition des lignes : une fois validé, le numéro
/// s'affiche en lecture seule (les boutons valider/annuler disparaissent) et un
/// DOUBLE-TAP le repasse en édition. Quand la configuration est verrouillée,
/// plus aucune édition n'est possible et un cadenas le signale.
class _AllowedNumbersSection extends ConsumerWidget {
  const _AllowedNumbersSection({required this.kitNumber, this.locked = false});
  final String? kitNumber;
  final bool locked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    final vm = ref.watch(kitAllowedNumbersProvider(kitNumber));
    final nums = vm.allowedNumbers;
    final n1 = nums.isNotEmpty ? nums[0].phoneNumber : '';
    final n2 = nums.length > 1 ? nums[1].phoneNumber : '';

    Future<void> save(String first, String second) async {
      await ref
          .read(kitAllowedNumbersProvider(kitNumber))
          .setTwoNumbers(first, second);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.t('config.numbers.saved'))),
        );
      }
    }

    return _SectionCard(
      title: t.t('config.allowed'),
      icon: Icons.contacts_rounded,
      accent: AppTheme.lavender,
      locked: locked,
      children: [
        const SizedBox(height: 4),
        // La clé porte la valeur enregistrée : quand elle change, la ligne
        // repart proprement de l'état en base.
        _NumberRow(
          key: ValueKey('n1:$n1:$locked'),
          label: t.t('config.preview.n1'),
          value: n1,
          locked: locked,
          onSave: (v) => save(v, n2),
        ),
        const SizedBox(height: 10),
        _NumberRow(
          key: ValueKey('n2:$n2:$locked'),
          label: t.t('config.preview.n2'),
          value: n2,
          locked: locked,
          onSave: (v) => save(n1, v),
        ),
      ],
    );
  }
}

/// Une ligne « numéro autorisé » : lecture seule par défaut, édition inline au
/// double-tap, validation par le bouton vert à droite, abandon par le rouge.
class _NumberRow extends StatefulWidget {
  const _NumberRow({
    super.key,
    required this.label,
    required this.value,
    required this.locked,
    required this.onSave,
  });

  final String label;
  final String value;
  final bool locked;
  final Future<void> Function(String) onSave;

  @override
  State<_NumberRow> createState() => _NumberRowState();
}

class _NumberRowState extends State<_NumberRow> {
  late final TextEditingController _c =
      TextEditingController(text: widget.value);

  /// Un numéro encore vide s'ouvre directement en saisie : sans cela, il
  /// faudrait deviner qu'un double-tap est nécessaire pour le renseigner.
  late bool _editing = widget.value.isEmpty && !widget.locked;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _cancel() {
    _c.text = widget.value;
    setState(() => _editing = false);
  }

  Future<void> _validate() async {
    final v = _c.text.trim();
    await widget.onSave(v);
    if (mounted) setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (!_editing) {
      final empty = widget.value.isEmpty;
      return GestureDetector(
        // Double-tap : repasse en édition (impossible si verrouillé).
        onDoubleTap: widget.locked ? null : () => setState(() => _editing = true),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(Icons.phone_android_rounded,
                  size: 18, color: scheme.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: TextStyle(
                          fontSize: 11.5, color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      empty ? '-' : widget.value,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: empty ? scheme.onSurfaceVariant : null,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.locked)
                Icon(Icons.lock_rounded,
                    size: 16,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.75)),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: SheetField(
            controller: _c,
            label: widget.label,
            hint: '+2376XXXXXXXX',
            icon: Icons.phone_android_rounded,
            keyboardType: TextInputType.phone,
          ),
        ),
        const SizedBox(width: 8),
        _RoundAction(
          icon: Icons.check_rounded,
          color: AppTheme.success,
          onTap: _validate,
        ),
        const SizedBox(width: 6),
        _RoundAction(
          icon: Icons.close_rounded,
          color: AppTheme.coral,
          onTap: _cancel,
        ),
      ],
    );
  }
}

/// Bouton circulaire compact (valider / annuler), épuré et doux.
class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.14),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 19, color: color),
        ),
      ),
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
    this.locked = false,
  });
  final String title;
  final IconData icon;
  final Color accent;
  final List<Widget> children;

  /// Bouton d'édition au niveau de la section (en-tête) au lieu de chaque ligne.
  final VoidCallback? onEdit;

  /// Configuration close : l'édition est retirée et un cadenas prend sa place,
  /// pour que l'impossibilité se VOIE au lieu d'être découverte à l'usage.
  final bool locked;

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
              if (locked)
                const _LockBadge()
              else if (onEdit != null)
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


/// Volet « État de la configuration » : où en est-on face au kit.
///
/// Trois états, mutuellement exclusifs :
///  • **verrouillée** : « Fin_config » est parti : la configuration est CLOSE.
///    Plus aucun envoi de configuration n'est possible, il ne reste que le
///    pilotage des lignes et la consommation. Matérialisé par un cadenas.
///  • **OK**          : le retour du kit correspond exactement à ce qui a été
///    envoyé : il ne manque que la validation, proposée ici.
///  • **en cours**    : la configuration est partie, le kit n'a pas encore
///    répondu. Le kit peut mettre plusieurs minutes ; rien ne bloque l'app, et
///    l'écho sera reconnu même application fermée.
class _ConfigStatusCard extends ConsumerWidget {
  const _ConfigStatusCard({required this.kit, required this.onFinalize});

  final KitModel kit;
  final VoidCallback onFinalize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    final scheme = Theme.of(context).colorScheme;

    final bool locked = kit.configSent;
    final bool matched = kit.configAckPending;
    final bool waiting =
        !locked && !matched && (kit.pendingConfigMsg?.isNotEmpty ?? false);

    // Aucune configuration n'a jamais été envoyée : rien à raconter.
    if (!locked && !matched && !waiting) return const SizedBox.shrink();

    final Color accent = locked
        ? scheme.onSurfaceVariant
        : (matched ? AppTheme.success : AppTheme.amber);
    final IconData icon = locked
        ? Icons.lock_rounded
        : (matched ? Icons.check_circle_rounded : Icons.hourglass_top_rounded);
    final String title = locked
        ? t.t('config.state.lockedTitle')
        : (matched
            ? t.t('config.state.okTitle')
            : t.t('config.state.waitingTitle'));
    final String body = locked
        ? t.t('config.state.lockedBody')
        : (matched
            ? t.t('config.state.okBody')
            : t.t('config.state.waitingBody'));

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
              // Pastille d'état, lisible d'un coup d'œil.
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  locked
                      ? t.t('config.state.badgeLocked')
                      : (matched
                          ? t.t('config.state.badgeOk')
                          : t.t('config.state.badgeWaiting')),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
          ),
          if (matched) ...[
            const SizedBox(height: 12),
            // Même mention que dans la popup : le geste est sans retour côté
            // utilisateur, il doit le savoir AVANT d'appuyer.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline_rounded,
                    size: 15, color: scheme.onSurfaceVariant),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    t.t('config.finalizeWarning'),
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onFinalize,
                icon: const Icon(Icons.lock_rounded),
                label: Text(t.t('config.state.finalizeCta')),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Cadenas discret : matérialise visuellement qu'un élément n'est plus
/// modifiable parce que la configuration a été close.
class _LockBadge extends StatelessWidget {
  const _LockBadge();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(7),
      child: Icon(Icons.lock_rounded,
          size: 17, color: scheme.onSurfaceVariant.withValues(alpha: 0.75)),
    );
  }
}
