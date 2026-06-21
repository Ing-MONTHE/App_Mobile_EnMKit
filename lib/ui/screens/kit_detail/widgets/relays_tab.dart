import 'package:enmkit/core/constants/defaults.dart';
import 'package:enmkit/models/relay_ack_model.dart';
import 'package:enmkit/models/relay_model.dart';
import 'package:enmkit/providers.dart';
import 'package:enmkit/ui/theme/app_theme.dart';
import 'package:enmkit/ui/widgets/common/app_sheet.dart';
import 'package:enmkit/ui/widgets/common/brand_loader.dart';
import 'package:enmkit/ui/widgets/common/soft_card.dart';
import 'package:enmkit/ui/widgets/common/state_views.dart';
import 'package:enmkit/viewmodels/relay_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Onglet Relais : liste, pilotage, édition et suppression des relais d'un kit
/// (scopé sur [kitNumber]). Maximum [DefaultData.maxRelaysPerKit] relais.
class RelaysTab extends ConsumerWidget {
  const RelaysTab({super.key, required this.kitNumber});
  final String? kitNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(kitRelaysProvider(kitNumber));
    final listener = ref.watch(kitSmsListenerProvider(kitNumber));
    final t = ref.watch(tProvider);

    return StreamBuilder<String>(
      stream: listener.trustedSms$,
      builder: (context, snapshot) {
        final sms = snapshot.data ?? '';
        if (sms.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            vm.processIncomingSms(sms);
          });
        }

        if (vm.isLoading) {
          return BrandLoader(message: t.t('relays.loading'));
        }

        final canAdd = vm.relays.length < DefaultData.maxRelaysPerKit;

        return RefreshIndicator(
          onRefresh: () => vm.fetchRelays(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              _KitControlCard(kitNumber: kitNumber, vm: vm)
                  .animate()
                  .fadeIn(duration: 350.ms)
                  .slideY(begin: 0.10, end: 0, curve: Curves.easeOutCubic),
              const SizedBox(height: 22),
              if (vm.relays.isEmpty)
                EmptyStateView(
                  icon: Icons.power_rounded,
                  title: t.t('relays.empty.title'),
                  message: t.t('relays.empty.msg'),
                  actionLabel: t.t('relays.add'),
                  onAction: () => _showRelaySheet(context, ref, vm),
                )
              else ...[
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 12),
                  child: Row(
                    children: [
                      Text(
                        t.t('relays.control'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      Text(
                        '${vm.relays.length}/${DefaultData.maxRelaysPerKit}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                ...vm.relays.asMap().entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _RelayCard(
                          relay: e.value,
                          vm: vm,
                          onDelete: () => _confirmDelete(context, ref, vm, e.value),
                        )
                            .animate()
                            .fadeIn(
                                delay: (180 + 70 * e.key).ms, duration: 350.ms)
                            .slideX(begin: 0.12, end: 0, curve: Curves.easeOut),
                      ),
                    ),
                const SizedBox(height: 4),
                if (canAdd)
                  OutlinedButton.icon(
                    onPressed: () => _showRelaySheet(context, ref, vm),
                    icon: const Icon(Icons.add),
                    label: Text(t.t('relays.add')),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    child: Text(
                      t.tf('relays.max', [DefaultData.maxRelaysPerKit]),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Feuille d'ajout d'une ligne (nom uniquement — l'édition se fait en ligne
  /// par double-appui sur la carte, voir [_RelayCard]).
  Future<void> _showRelaySheet(
    BuildContext context,
    WidgetRef ref,
    RelayViewModel vm,
  ) async {
    final t = ref.read(tProvider);

    // Garde-fou : pas plus de 7 lignes.
    if (vm.relays.length >= DefaultData.maxRelaysPerKit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.tf('relays.max', [DefaultData.maxRelaysPerKit]))),
      );
      return;
    }

    final nameController = TextEditingController();

    await showAppSheet<void>(
      context: context,
      icon: Icons.electrical_services_rounded,
      title: t.t('relays.add'),
      subtitle: t.t('relays.add.sub'),
      accent: AppTheme.emerald,
      builder: (ctx) => Column(
        children: [
          SheetField(
            controller: nameController,
            label: t.t('relays.name'),
            hint: t.t('relays.name.hint'),
            icon: Icons.lightbulb_outline_rounded,
            textCapitalization: TextCapitalization.words,
            autofocus: true,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                final name = nameController.text.trim();
                await vm.addRelay(RelayModel(
                  name: name.isEmpty ? null : name,
                  amperage: DefaultData.defaultAmperage,
                  kitNumber: kitNumber,
                ));
                await vm.fetchRelays();
                if (ctx.mounted) Navigator.pop(ctx);
              },
              icon: const Icon(Icons.check_rounded),
              label: Text(t.t('relays.add.cta')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    RelayViewModel vm,
    RelayModel relay,
  ) async {
    final t = ref.read(tProvider);
    final ok = await _confirmDialog(
      context,
      t,
      title: t.t('relays.delete.confirm'),
      message: relay.name ?? 'Ligne ${relay.id ?? ''}',
      cta: t.t('relays.delete'),
      danger: true,
    );
    if (ok == true && relay.id != null) {
      await vm.deleteRelay(relay.id!);
    }
  }
}

/// Boîte de confirmation réutilisable (édition / suppression).
Future<bool?> _confirmDialog(
  BuildContext context,
  dynamic t, {
  required String title,
  required String message,
  required String cta,
  required bool danger,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(t.t('common.cancel')),
        ),
        FilledButton(
          style: danger
              ? FilledButton.styleFrom(backgroundColor: AppTheme.danger)
              : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(cta),
        ),
      ],
    ),
  );
}

/// Carte de contrôle du kit : test de joignabilité (ping « hello ») + actions
/// groupées (tout allumer / tout éteindre).
class _KitControlCard extends ConsumerWidget {
  const _KitControlCard({required this.kitNumber, required this.vm});
  final String? kitNumber;
  final RelayViewModel vm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    final scheme = Theme.of(context).colorScheme;
    // Section « Connexion du kit » retirée (pour l'instant). On ne garde que les
    // actions rapides Tout allumer / Tout éteindre.
    if (vm.relays.isEmpty) return const SizedBox.shrink();

    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.t('relays.quickActions'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _BulkButton(
                  icon: Icons.flash_on_rounded,
                  label: t.t('relays.allOn'),
                  color: AppTheme.success,
                  onTap: () => _setAll(context, ref, true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BulkButton(
                  icon: Icons.flash_off_rounded,
                  label: t.t('relays.allOff'),
                  color: AppTheme.inkSoft,
                  onTap: () => _setAll(context, ref, false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _setAll(BuildContext context, WidgetRef ref, bool on) async {
    final t = ref.read(tProvider);
    try {
      await vm.setAllRelays(on);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.tf('relays.failed', [e]))),
        );
      }
    }
  }
}

/// Bouton d'action groupée (tout allumer / tout éteindre), doux et teinté.
class _BulkButton extends StatelessWidget {
  const _BulkButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RelayCard extends ConsumerStatefulWidget {
  const _RelayCard({
    required this.relay,
    required this.vm,
    required this.onDelete,
  });
  final RelayModel relay;
  final RelayViewModel vm;
  final VoidCallback onDelete;

  @override
  ConsumerState<_RelayCard> createState() => _RelayCardState();
}

class _RelayCardState extends ConsumerState<_RelayCard> {
  bool _editing = false;
  late final TextEditingController _nameC =
      TextEditingController(text: widget.relay.name ?? '');

  @override
  void dispose() {
    _nameC.dispose();
    super.dispose();
  }

  void _enterEdit() {
    _nameC.text = widget.relay.name ?? '';
    setState(() => _editing = true);
  }

  Future<void> _save() async {
    final name = _nameC.text.trim();
    if (name.isNotEmpty && widget.relay.id != null) {
      await widget.vm.updateRelayName(widget.relay.id!, name);
    }
    if (mounted) setState(() => _editing = false);
  }

  /// Ouvre l'historique horodaté des accusés de réception de cette ligne.
  void _openHistory(BuildContext context) {
    final t = ref.read(tProvider);
    final relay = widget.relay;
    final acks = widget.vm.acksForRelay(relay.id);
    showAppSheet<void>(
      context: context,
      icon: Icons.history_rounded,
      title: t.t('relays.history.title'),
      subtitle: '${relay.name ?? 'Ligne ${relay.id ?? ''}'} · '
          '${t.t('relays.history.sub')}',
      accent: AppTheme.indigo,
      builder: (ctx) => _AckHistoryList(acks: acks),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = ref.watch(tProvider);
    final relay = widget.relay;
    // Icône volontairement NEUTRE et STATIQUE : la carte ne reflète JAMAIS
    // l'état (ON/OFF) « supposé » de la ligne. Le seul état fiable est celui
    // confirmé par le kit, consultable dans l'historique des accusés. Afficher
    // un état non confirmé sur la carte/les boutons pourrait induire en erreur.
    const accent = AppTheme.inkSoft;
    // Commande en vol : état demandé en attente de l'écho du kit (null = aucune).
    final pendingOn = widget.vm.pendingTargetForRelay(relay.id);
    // Historique d'accusés disponible pour cette ligne ?
    final hasHistory = widget.vm.hasHistoryForRelay(relay.id);

    return GestureDetector(
      onDoubleTap: _editing ? null : _enterEdit,
      child: SoftCard(
        // Plus d'ombre teintée verte : la carte reste neutre, qu'elle soit ON ou OFF.
        shadowTint: null,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            IconPill(
              icon: Icons.bolt_rounded,
              color: accent,
              size: 44,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                switchInCurve: Curves.easeOut,
                child: _editing
                    ? TextField(
                        key: const ValueKey('edit'),
                        controller: _nameC,
                        autofocus: true,
                        textCapitalization: TextCapitalization.words,
                        style: const TextStyle(
                            fontSize: 15.5, fontWeight: FontWeight.w700),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: t.t('relays.name.hint'),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          filled: true,
                          fillColor: scheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusControl),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _save(),
                      )
                    : Column(
                        key: const ValueKey('view'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  relay.name ?? 'Ligne ${relay.id ?? ''}',
                                  style: const TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Historique horodaté des accusés (n'apparaît que
                              // s'il existe au moins une confirmation du kit).
                              if (hasHistory)
                                _HistoryButton(
                                  onTap: () => _openHistory(context),
                                ),
                            ],
                          ),
                          // Plus de badge de statut (« En marche » / « En
                          // attente… ») sous le nom : l'état se lit uniquement
                          // sur le sélecteur ON/OFF, pour une fiche épurée.
                        ],
                      ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              switchInCurve: Curves.easeOutBack,
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: _editing
                  ? Row(
                      key: const ValueKey('actions'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _CircleAction(
                          icon: Icons.check_rounded,
                          color: AppTheme.success,
                          onTap: _save,
                        ),
                        const SizedBox(width: 10),
                        _CircleAction(
                          icon: Icons.close_rounded,
                          color: AppTheme.danger,
                          onTap: widget.onDelete,
                        ),
                      ],
                    )
                  : _OnOffControl(
                      key: const ValueKey('onoff'),
                      pendingOn: pendingOn,
                      onSelect: (on) async {
                        try {
                          await widget.vm.setRelay(relay, on);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(t.tf('relays.failed', [e]))),
                            );
                          }
                        }
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bouton d'action circulaire, doux et épuré (✓ vert / ✕ rouge).
class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.13),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

/// Contrôle ON / OFF — DEUX BOUTONS D'ACTION NEUTRES et identiques.
///
/// Choix volontaire : aucun bouton n'affiche l'état (ON/OFF) « supposé » de la
/// ligne. Montrer un état non confirmé pourrait induire en erreur — le seul
/// état fiable est celui confirmé par le kit, consultable dans l'historique des
/// accusés. Presser ON/OFF ne fait qu'ENVOYER la commande ; pendant que l'écho
/// du kit est attendu, le bouton pressé affiche un bref « envoi en cours » et
/// le contrôle est verrouillé pour éviter un double envoi (= un double SMS).
class _OnOffControl extends StatelessWidget {
  const _OnOffControl({
    super.key,
    required this.pendingOn,
    required this.onSelect,
  });

  /// Commande en vol en attente de l'écho du kit (null = aucune). `true` = ON
  /// demandé, `false` = OFF demandé. Sert UNIQUEMENT au retour « envoi en
  /// cours », jamais à afficher l'état de la ligne.
  final bool? pendingOn;
  final ValueChanged<bool> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Une commande est en vol : on verrouille TOUT le contrôle jusqu'à
    // confirmation (ou expiration). Impossible de presser l'autre segment tant
    // que la première action n'est pas achevée.
    final bool busy = pendingOn != null;
    return Container(
      padding: const EdgeInsets.all(3.5),
      decoration: BoxDecoration(
        // Piste neutre légèrement creusée (liseré fin = relief « inset »).
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: scheme.outline.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Seg(
            label: 'ON',
            icon: Icons.power_settings_new_rounded,
            pending: pendingOn == true,
            enabled: !busy,
            onTap: () => onSelect(true),
          ),
          const SizedBox(width: 3),
          _Seg(
            label: 'OFF',
            icon: Icons.power_settings_new_rounded,
            pending: pendingOn == false,
            enabled: !busy,
            onTap: () => onSelect(false),
          ),
        ],
      ),
    );
  }
}

/// Un bouton d'action du contrôle (ON ou OFF) — TOUJOURS neutre.
/// Il ne reflète jamais l'état de la ligne : c'est une simple commande.
class _Seg extends StatelessWidget {
  const _Seg({
    required this.label,
    required this.icon,
    required this.pending,
    required this.enabled,
    required this.onTap,
  });
  final String label;
  final IconData icon;

  /// Ce bouton vient-il d'être pressé et attend-il l'écho du kit ? (Affiche un
  /// bref « envoi en cours » — ce n'est PAS un indicateur d'état de la ligne.)
  final bool pending;

  /// Le bouton est-il cliquable ? (Faux dès qu'une commande est en vol sur la
  /// ligne, qu'elle vise ce bouton ou l'autre — pour éviter un double envoi.)
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Premier plan neutre, identique pour ON et OFF.
    final Color fg = scheme.onSurface.withValues(alpha: 0.78);
    // Bouton verrouillé par une commande en cours (et qui n'est pas celui en
    // « envoi ») : on l'estompe pour signaler qu'il n'est pas actionnable.
    final double opacity = (!enabled && !pending) ? 0.4 : 1.0;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: opacity,
        child: Container(
        width: 56,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          // Apparence NEUTRE et identique quel que soit l'état de la ligne.
          color: scheme.surface,
          borderRadius: BorderRadius.circular(11.5),
          border: Border.all(
            color: scheme.outline.withValues(alpha: 0.16),
            width: 1,
          ),
        ),
        child: pending
            ? SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(fg),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 13, color: fg),
                  const SizedBox(width: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 260),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: fg,
                    ),
                    child: Text(label),
                  ),
                ],
              ),
        ),
      ),
    );
  }
}

/// Petit bouton « horloge » ouvrant l'historique des accusés d'une ligne.
class _HistoryButton extends StatelessWidget {
  const _HistoryButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkResponse(
      onTap: onTap,
      radius: 22,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          Icons.history_rounded,
          size: 19,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Liste de l'historique des accusés de réception d'une ligne (sheet).
/// Regroupe les entrées par jour et affiche l'heure de chaque confirmation.
class _AckHistoryList extends ConsumerWidget {
  const _AckHistoryList({required this.acks});
  final List<RelayAck> acks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    final scheme = Theme.of(context).colorScheme;

    if (acks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          children: [
            Icon(Icons.history_toggle_off_rounded,
                size: 44, color: scheme.onSurfaceVariant),
            const SizedBox(height: 14),
            Text(
              t.t('relays.history.empty'),
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: scheme.onSurfaceVariant, fontSize: 13.5, height: 1.4),
            ),
          ],
        ),
      );
    }

    // Limite l'affichage et borne la hauteur pour rester dans la feuille.
    final items = acks.take(40).toList();
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final a = items[i];
          final on = a.isActive;
          final color = on ? AppTheme.success : AppTheme.inkSoft;
          final raw = a.raw?.trim();
          final hasRaw = raw != null && raw.isNotEmpty;
          return Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    on ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                    size: 18,
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        on
                            ? t.t('relays.history.on')
                            : t.t('relays.history.off'),
                        style: const TextStyle(
                            fontSize: 14.5, fontWeight: FontWeight.w700),
                      ),
                      // Accusé brut joint : la confirmation réellement reçue
                      // du kit (texte du SMS), pour lever toute ambiguïté.
                      if (hasRaw) ...[
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.sms_rounded,
                              size: 13,
                              color: scheme.onSurfaceVariant
                                  .withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                raw,
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                  fontSize: 12,
                                  height: 1.3,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _formatAckTime(t, a.at),
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Formate l'horodatage : « Aujourd'hui 14:32 », « Hier 09:05 » ou
  /// « 12/06 18:40 » pour les dates plus anciennes.
  String _formatAckTime(dynamic t, DateTime at) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(at.year, at.month, at.day);
    final hh = at.hour.toString().padLeft(2, '0');
    final mm = at.minute.toString().padLeft(2, '0');
    final time = '$hh:$mm';
    final diff = today.difference(day).inDays;
    if (diff == 0) return "${t.t('relays.history.today')} $time";
    if (diff == 1) return "${t.t('relays.history.yesterday')} $time";
    final d = at.day.toString().padLeft(2, '0');
    final mo = at.month.toString().padLeft(2, '0');
    return '$d/$mo $time';
  }
}
