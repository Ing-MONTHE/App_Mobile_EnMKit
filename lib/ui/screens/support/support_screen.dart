import 'package:enmkit/core/support_service.dart';
import 'package:enmkit/models/kit_model.dart';
import 'package:enmkit/models/support_message_model.dart';
import 'package:enmkit/providers.dart';
import 'package:enmkit/ui/theme/app_theme.dart';
import 'package:enmkit/ui/widgets/common/app_sheet.dart';
import 'package:enmkit/ui/widgets/common/soft_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Écran d'assistance : l'utilisateur exprime un besoin par un questionnaire
/// guidé, la demande part au support par SMS, et la conversation se poursuit
/// dans le fil ci-dessous — les réponses du support arrivant par SMS, y
/// compris application fermée.
class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  SupportTopic? _topic;
  NumberAction? _action;
  String? _kitNumber;
  final _numberC = TextEditingController();
  final _detailsC = TextEditingController();
  final _replyC = TextEditingController();

  @override
  void dispose() {
    _numberC.dispose();
    _detailsC.dispose();
    _replyC.dispose();
    super.dispose();
  }

  /// Un numéro n'est demandé que là où il a un sens : c'est tout l'intérêt du
  /// questionnaire, ne réclamer que ce qui sert à traiter la demande.
  bool get _needsNumber => _topic == SupportTopic.numberConfig;

  /// La demande est complète quand l'objet est choisi, et — pour une
  /// configuration de numéro — que l'action et le numéro sont renseignés.
  bool get _canSend {
    if (_topic == null) return false;
    if (_topic == SupportTopic.numberConfig) {
      return _action != null && _numberC.text.trim().isNotEmpty;
    }
    return true;
  }

  KitModel? get _selectedKit {
    final kits = ref.read(kitProvider).kits;
    if (kits.isEmpty) return null;
    final i = kits.indexWhere((k) => k.kitNumber == _kitNumber);
    return i == -1 ? kits.first : kits[i];
  }

  String _composed() {
    final kit = _selectedKit;
    return SupportService.buildRequest(
      topic: _topic!,
      action: _action,
      targetNumber: _numberC.text,
      details: _detailsC.text,
      kitNumber: kit?.kitNumber,
      kitName: kit?.name,
    );
  }

  Future<void> _sendRequest() async {
    if (!_canSend) return;
    final t = ref.read(tProvider);
    final text = _composed();
    final ok = await ref
        .read(supportProvider)
        .send(text, kitNumber: _selectedKit?.kitNumber);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? t.t('help.sent') : t.t('help.sendFailed')),
        backgroundColor: ok ? AppTheme.success : null,
      ),
    );
    if (ok) {
      setState(() {
        _topic = null;
        _action = null;
        _numberC.clear();
        _detailsC.clear();
      });
    }
  }

  Future<void> _sendReply() async {
    final text = _replyC.text.trim();
    if (text.isEmpty) return;
    final t = ref.read(tProvider);
    final ok = await ref.read(supportProvider).send(text);
    if (!mounted) return;
    if (ok) {
      _replyC.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.t('help.sendFailed'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(tProvider);
    final vm = ref.watch(supportProvider);
    final kits = ref.watch(kitProvider).kits;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      children: [
        Text(
          t.t('help.title'),
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          t.t('help.sub'),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12.5,
          ),
        ),
        const SizedBox(height: 14),

        // ---- Questionnaire guidé -------------------------------------------
        SoftCard(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Label(text: t.t('help.q.topic')),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: SupportTopic.values
                    .map((e) => _Choice(
                          label: SupportService.topicLabel(e),
                          selected: _topic == e,
                          onTap: () => setState(() {
                            _topic = e;
                            _action = null;
                          }),
                        ))
                    .toList(),
              ),

              // Sous-question : seulement pour la configuration d'un numéro.
              if (_topic == SupportTopic.numberConfig) ...[
                const SizedBox(height: 14),
                _Label(text: t.t('help.q.action')),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: NumberAction.values
                      .map((e) => _Choice(
                            label: SupportService.actionLabel(e),
                            selected: _action == e,
                            onTap: () => setState(() => _action = e),
                          ))
                      .toList(),
                ),
              ],

              if (_needsNumber && _action != null) ...[
                const SizedBox(height: 14),
                _Label(text: t.t('help.q.number')),
                const SizedBox(height: 10),
                SheetField(
                  controller: _numberC,
                  label: t.t('help.q.number'),
                  hint: '+2376XXXXXXXX',
                  icon: Icons.phone_android_rounded,
                  keyboardType: TextInputType.phone,
                  onChanged: (_) => setState(() {}),
                ),
              ],

              // Kit concerné : rappelé au support dans le message, pour qu'il
              // sache de quel boîtier il s'agit.
              if (kits.isNotEmpty) ...[
                const SizedBox(height: 14),
                _Label(text: t.t('help.q.kit')),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: kits
                      .map((k) => _Choice(
                            label: k.displayName,
                            selected: (_selectedKit?.kitNumber) == k.kitNumber,
                            onTap: () =>
                                setState(() => _kitNumber = k.kitNumber),
                          ))
                      .toList(),
                ),
              ],

              const SizedBox(height: 14),
              _Label(text: t.t('help.q.details')),
              const SizedBox(height: 10),
              SheetField(
                controller: _detailsC,
                label: t.t('help.q.details'),
                hint: t.t('help.q.details.hint'),
                icon: Icons.notes_rounded,
                maxLines: 3,
              ),

              // Aperçu : l'utilisateur voit EXACTEMENT ce qui partira.
              if (_canSend) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _composed(),
                    style: const TextStyle(
                        fontFamily: 'monospace', fontSize: 12, height: 1.35),
                  ),
                ),
              ],

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: (_canSend && !vm.sending) ? _sendRequest : null,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: Text(t.t('help.send')),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => ref
                      .read(supportProvider)
                      .openWhatsApp(text: _topic == null ? null : _composed()),
                  icon: const Icon(Icons.chat_rounded, size: 18),
                  label: Text(t.t('help.whatsapp')),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ---- Fil de conversation -------------------------------------------
        Row(
          children: [
            Text(
              t.t('help.thread'),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Text(
              SupportService.supportNumber,
              style: TextStyle(
                fontSize: 12.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (vm.thread.isEmpty)
          SoftCard(
            padding: const EdgeInsets.all(18),
            child: Text(
              t.t('help.threadEmpty'),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          )
        else
          ...vm.thread.map((m) => _Bubble(message: m)),

        const SizedBox(height: 14),
        // Réponse libre : la conversation continue sans repasser par le
        // questionnaire.
        Row(
          children: [
            Expanded(
              child: SheetField(
                controller: _replyC,
                label: t.t('help.reply'),
                hint: t.t('help.reply.hint'),
                icon: Icons.edit_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: AppTheme.brandBlue,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: vm.sending ? null : _sendReply,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.send_rounded, size: 20, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
}

/// Puce de choix du questionnaire.
class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? AppTheme.brandBlue.withValues(alpha: 0.14)
          : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppTheme.brandBlue.withValues(alpha: 0.55)
                  : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppTheme.brandBlue : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// Bulle de conversation : demande envoyée à droite, réponse du support à
/// gauche — lecture immédiate du sens de l'échange.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final SupportMessage message;

  String get _time {
    final h = message.at.hour.toString().padLeft(2, '0');
    final m = message.at.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final out = message.outgoing;
    return Align(
      alignment: out ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(13, 10, 13, 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: out
              ? AppTheme.brandBlue.withValues(alpha: 0.13)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.65),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(out ? 16 : 4),
            bottomRight: Radius.circular(out ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              out ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(message.body,
                style: const TextStyle(fontSize: 13, height: 1.3)),
            const SizedBox(height: 3),
            Text(
              _time,
              style: TextStyle(
                fontSize: 10.5,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// L'écran d'aide ouvert comme page à part entière (depuis la FAQ par exemple),
/// et non comme onglet de la coquille principale.
class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aide & assistance')),
      body: const SafeArea(child: SupportScreen()),
    );
  }
}
