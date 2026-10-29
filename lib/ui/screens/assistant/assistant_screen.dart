import 'package:enmkit/core/ai/energy_insights.dart';
import 'package:enmkit/core/api/enmkit_api_client.dart';
import 'package:enmkit/providers.dart';
import 'package:enmkit/ui/theme/app_theme.dart';
import 'package:enmkit/ui/widgets/common/doodle_background.dart';
import 'package:enmkit/ui/widgets/common/soft_card.dart';
import 'package:enmkit/viewmodels/assistant_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Assistant énergie : conversation EN LIGNE (`POST /app/assistant/chat`) si le
/// serveur EnMKit est configuré et joignable, sinon réponses HORS-LIGNE tirées
/// des recommandations locales, des éco-gestes et du glossaire.
class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({
    super.key,
    this.kitNumber,
    this.initialAudience = AssistantAudience.owner,
  });

  /// Kit dont l'analyse sert de contexte (null = question générale).
  final String? kitNumber;
  final AssistantAudience initialAudience;

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(assistantProvider(widget.kitNumber)).audience =
          widget.initialAudience;
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  EnergyInsights? _insights(String lang) {
    final k = widget.kitNumber;
    if (k == null) return null;
    final vm = ref.read(kitHourlyProvider(k));
    return vm.hasData ? vm.insights(lang) : null;
  }

  Future<void> _send(String text) async {
    final t = ref.read(tProvider);
    _input.clear();
    await ref
        .read(assistantProvider(widget.kitNumber))
        .send(text, lang: t.locale, insights: _insights(t.locale));
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: AppTheme.normal, curve: Curves.easeOut);
      }
    });
  }

  String _failureText(ApiFailure f) => ref.read(tProvider).t(switch (f) {
        ApiFailure.notConfigured => 'asst.fail.notConfigured',
        ApiFailure.offline => 'asst.fail.offline',
        ApiFailure.unauthorized => 'asst.fail.unauthorized',
        ApiFailure.unavailable => 'asst.fail.unavailable',
        ApiFailure.error => 'asst.fail.error',
      });

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(tProvider);
    final vm = ref.watch(assistantProvider(widget.kitNumber));
    // Garde la config serveur chargée (lecture paresseuse au premier envoi).
    ref.watch(serverConfigProvider);
    final scheme = Theme.of(context).colorScheme;
    final online = vm.onlineConfigured && vm.lastFailure == null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(t.t('asst.title')),
        actions: [
          if (vm.messages.isNotEmpty)
            IconButton(
              tooltip: t.t('asst.clear'),
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: vm.clear,
            ),
        ],
      ),
      body: DoodleBackground(
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Statut + public visé.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusBadge(
                      label: t.t(online
                          ? 'asst.status.online'
                          : 'asst.status.offline'),
                      color: online ? AppTheme.emerald : AppTheme.amber,
                    ),
                    if (vm.lastFailure != null &&
                        vm.lastFailure != ApiFailure.notConfigured) ...[
                      const SizedBox(height: 4),
                      Text(_failureText(vm.lastFailure!),
                          style: TextStyle(
                              fontSize: 12, color: scheme.onSurfaceVariant)),
                    ],
                    const SizedBox(height: 8),
                    SegmentedButton<AssistantAudience>(
                      showSelectedIcon: false,
                      segments: [
                        for (final a in AssistantAudience.values)
                          ButtonSegment(
                            value: a,
                            label: Text(t.t('asst.audience.${a.name}'),
                                style: const TextStyle(fontSize: 12.5)),
                          ),
                      ],
                      selected: {vm.audience},
                      onSelectionChanged: (s) => vm.audience = s.first,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: vm.messages.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          SoftCard(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const IconPill(
                                    icon: Icons.forum_rounded,
                                    color: AppTheme.indigo,
                                    size: 40),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(t.t('asst.welcome'),
                                      style: const TextStyle(height: 1.4)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final k in ['asst.s1', 'asst.s2', 'asst.s3'])
                                ActionChip(
                                  label: Text(t.t(k)),
                                  onPressed: () => _send(t.t(k)),
                                ),
                            ],
                          ),
                        ],
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        itemCount: vm.messages.length + (vm.sending ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i >= vm.messages.length) {
                            return const Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.4),
                                ),
                              ),
                            );
                          }
                          return _ChatBubble(
                            message: vm.messages[i],
                            localBadge: t.t('asst.localBadge'),
                          );
                        },
                      ),
              ),
              // Saisie.
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: vm.sending ? null : _send,
                        decoration: InputDecoration(
                          hintText: t.t('asst.hint'),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed:
                          vm.sending ? null : () => _send(_input.text),
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.localBadge});
  final ChatMessage message;
  final String localBadge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final out = message.role == 'user';
    return Align(
      alignment: out ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.84),
        decoration: BoxDecoration(
          color: out
              ? AppTheme.brandBlue.withValues(alpha: 0.13)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.75),
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
            if (message.local) ...[
              StatusBadge(label: localBadge, color: AppTheme.amber),
              const SizedBox(height: 6),
            ],
            SelectableText(message.content,
                style: const TextStyle(fontSize: 13.5, height: 1.35)),
          ],
        ),
      ),
    );
  }
}
