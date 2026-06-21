import 'package:enmkit/core/i18n/strings.dart';
import 'package:enmkit/providers.dart';
import 'package:enmkit/ui/theme/app_theme.dart';
import 'package:enmkit/ui/widgets/common/soft_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Configuration des questions mémo de récupération (2 questions au choix dans
/// une liste prédéfinie + réponses). Utilisé à la création du code (mode
/// [mandatory] : non annulable) et depuis les Réglages (modifiable).
class SecurityQuestionsScreen extends ConsumerStatefulWidget {
  const SecurityQuestionsScreen({super.key, this.mandatory = false});

  /// Vrai pendant la création du code : l'utilisateur ne peut pas revenir en
  /// arrière sans avoir défini ses questions (récupération garantie).
  final bool mandatory;

  @override
  ConsumerState<SecurityQuestionsScreen> createState() =>
      _SecurityQuestionsScreenState();
}

class _SecurityQuestionsScreenState
    extends ConsumerState<SecurityQuestionsScreen> {
  late String _q1 = AppStrings.securityQuestionKeys[0];
  late String _q2 = AppStrings.securityQuestionKeys[1];
  final _a1 = TextEditingController();
  final _a2 = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Pré-remplit avec les questions déjà choisies (réponses non récupérables).
    Future.microtask(() async {
      final keys = await ref.read(accessProvider).securityQuestionKeys();
      if (keys != null && keys.length == 2 && mounted) {
        setState(() {
          _q1 = keys[0];
          _q2 = keys[1];
        });
      }
    });
  }

  @override
  void dispose() {
    _a1.dispose();
    _a2.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final vm = ref.read(accessProvider);
    setState(() => _busy = true);
    final ok = await vm.setupSecurityQuestions(
      _q1,
      _a1.text,
      _q2,
      _a2.text,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      HapticFeedback.mediumImpact();
      Navigator.pop(context, true);
    } else {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.error ?? 'Échec')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(tProvider);
    final scheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: !widget.mandatory,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.t('recovery.title')),
          automaticallyImplyLeading: !widget.mandatory,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              t.t('recovery.subtitle'),
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
            ),
            const SizedBox(height: 20),
            _QuestionCard(
              index: 1,
              selected: _q1,
              answer: _a1,
              onChanged: (v) => setState(() => _q1 = v),
            ),
            const SizedBox(height: 14),
            _QuestionCard(
              index: 2,
              selected: _q2,
              answer: _a2,
              onChanged: (v) => setState(() => _q2 = v),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 15, color: scheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    t.t('recovery.answerHint'),
                    style: TextStyle(
                        color: scheme.onSurfaceVariant, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _save,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.shield_rounded, size: 19),
                label: Text(t.t('common.save')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionCard extends ConsumerWidget {
  const _QuestionCard({
    required this.index,
    required this.selected,
    required this.answer,
    required this.onChanged,
  });

  final int index;
  final String selected;
  final TextEditingController answer;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    final scheme = Theme.of(context).colorScheme;

    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${t.t('recovery.question')} $index',
            style: TextStyle(
              color: AppTheme.amber,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: ValueKey('q$index-$selected'),
            initialValue: selected,
            isExpanded: true,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusControl),
                borderSide: BorderSide.none,
              ),
            ),
            items: AppStrings.securityQuestionKeys
                .map((k) => DropdownMenuItem(
                      value: k,
                      child: Text(
                        t.t(k),
                        style: const TextStyle(fontSize: 13.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: answer,
            textCapitalization: TextCapitalization.none,
            decoration: InputDecoration(
              isDense: true,
              hintText: t.t('recovery.answer'),
              prefixIcon: const Icon(Icons.edit_rounded, size: 18),
              filled: true,
              fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusControl),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
