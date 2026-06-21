import 'package:enmkit/providers.dart';
import 'package:enmkit/ui/theme/app_theme.dart';
import 'package:enmkit/ui/widgets/common/soft_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Récupération du code : l'utilisateur répond à ses deux questions mémo puis
/// définit un nouveau code. Seul moyen de récupération (pas de réinitialisation
/// silencieuse). En cas de réussite, l'app est déverrouillée.
class ForgotPinScreen extends ConsumerStatefulWidget {
  const ForgotPinScreen({super.key});

  @override
  ConsumerState<ForgotPinScreen> createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends ConsumerState<ForgotPinScreen> {
  List<String>? _keys;
  bool _loaded = false;
  bool _busy = false;

  final _a1 = TextEditingController();
  final _a2 = TextEditingController();
  final _newPin = TextEditingController();
  final _conf = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final keys = await ref.read(accessProvider).securityQuestionKeys();
      if (mounted) {
        setState(() {
          _keys = keys;
          _loaded = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _a1.dispose();
    _a2.dispose();
    _newPin.dispose();
    _conf.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    final vm = ref.read(accessProvider);
    setState(() => _busy = true);
    final ok = await vm.resetPinWithAnswers(
      _a1.text,
      _a2.text,
      _newPin.text.trim(),
      _conf.text.trim(),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    final t = ref.read(tProvider);
    if (ok) {
      HapticFeedback.mediumImpact();
      // L'app est déverrouillée : on retire l'écran (le wrapper affiche l'accueil).
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.t('forgot.success'))),
      );
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

    return Scaffold(
      appBar: AppBar(title: Text(t.t('forgot.title'))),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : (_keys == null
              ? _NoQuestions(message: t.t('forgot.noQuestions'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    Text(
                      t.t('forgot.subtitle'),
                      style: TextStyle(
                          color: scheme.onSurfaceVariant, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    _AnswerCard(
                      questionText: t.t(_keys![0]),
                      controller: _a1,
                      answerHint: t.t('recovery.answer'),
                    ),
                    const SizedBox(height: 14),
                    _AnswerCard(
                      questionText: t.t(_keys![1]),
                      controller: _a2,
                      answerHint: t.t('recovery.answer'),
                    ),
                    const SizedBox(height: 20),
                    SoftCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      child: Column(
                        children: [
                          TextField(
                            controller: _newPin,
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            decoration: _pinDeco(
                                context, t.t('forgot.newPin'),
                                Icons.lock_rounded),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _conf,
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            decoration: _pinDeco(context,
                                t.t('forgot.confirmPin'), Icons.lock_rounded),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _busy ? null : _reset,
                        icon: _busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.lock_reset_rounded, size: 19),
                        label: Text(t.t('forgot.reset')),
                      ),
                    ),
                  ],
                )),
    );
  }

  InputDecoration _pinDeco(BuildContext context, String hint, IconData icon) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      isDense: true,
      hintText: hint,
      prefixIcon: Icon(icon, size: 18),
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusControl),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({
    required this.questionText,
    required this.controller,
    required this.answerHint,
  });

  final String questionText;
  final TextEditingController controller;
  final String answerHint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            questionText,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              isDense: true,
              hintText: answerHint,
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

class _NoQuestions extends StatelessWidget {
  const _NoQuestions({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.help_outline_rounded,
                size: 48, color: scheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14.5),
            ),
          ],
        ),
      ),
    );
  }
}
