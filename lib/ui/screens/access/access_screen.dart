import 'package:enmkit/providers.dart';
import 'package:enmkit/ui/screens/access/forgot_pin_screen.dart';
import 'package:enmkit/ui/screens/access/security_questions_screen.dart';
import 'package:enmkit/ui/theme/app_theme.dart';
import 'package:enmkit/ui/widgets/common/app_logo.dart';
import 'package:enmkit/ui/widgets/common/app_sheet.dart';
import 'package:enmkit/ui/widgets/common/doodle_background.dart';
import 'package:enmkit/viewmodels/access_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Écran de code d'accès (PIN), style fintech : logo, entrée animée, pavé
/// numérique premium. Création au 1er lancement puis déverrouillage.
class AccessScreen extends ConsumerStatefulWidget {
  const AccessScreen({super.key, this.firstRunSetup = false});

  /// Proposition de code au tout premier lancement : affiche un bouton
  /// « Passer » pour rendre la création de code optionnelle (non bloquante).
  final bool firstRunSetup;

  @override
  ConsumerState<AccessScreen> createState() => _AccessScreenState();
}

class _AccessScreenState extends ConsumerState<AccessScreen> {
  static const int _pinLength = 4;

  String _entry = '';
  String? _firstEntry;
  bool _bioReady = false; // empreinte disponible + activée (mode déverrouillage)

  bool get _isSetup =>
      ref.read(accessProvider).status == AccessStatus.needsSetup;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initBiometric());
  }

  /// Au déverrouillage : si l'empreinte est activée et disponible, on l'affiche
  /// et on lance l'invite automatiquement (le code reste accessible en secours).
  Future<void> _initBiometric() async {
    final vm = ref.read(accessProvider);
    if (vm.status != AccessStatus.locked) return;
    if (!ref.read(settingsProvider).settings.biometricEnabled) return;
    if (!await vm.biometricAvailable()) return;
    if (!mounted) return;
    setState(() => _bioReady = true);
    await _biometricUnlock();
  }

  Future<void> _biometricUnlock() async {
    final vm = ref.read(accessProvider);
    final t = ref.read(tProvider);
    await vm.unlockWithBiometric(t.t('access.biometricReason'));
  }

  void _openForgot() {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ForgotPinScreen()),
    );
  }

  void _onDigit(String d) {
    final vm = ref.read(accessProvider);
    vm.clearError();
    if (_entry.length >= _pinLength) return;
    HapticFeedback.selectionClick();
    setState(() => _entry += d);
    if (_entry.length == _pinLength) _submit();
  }

  void _onBackspace() {
    if (_entry.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _entry = _entry.substring(0, _entry.length - 1));
  }

  Future<void> _submit() async {
    final vm = ref.read(accessProvider);
    if (vm.status == AccessStatus.needsSetup) {
      if (_firstEntry == null) {
        setState(() {
          _firstEntry = _entry;
          _entry = '';
        });
        return;
      }
      await vm.createPin(_firstEntry!, _entry);
      if (vm.status == AccessStatus.needsRecoverySetup) {
        // Code créé : on enchaîne sur les questions mémo (obligatoires) puis la
        // proposition d'empreinte, avant de finaliser et déverrouiller.
        await _runRecoverySetup();
      } else {
        // Échec (codes non concordants, trop court…).
        HapticFeedback.heavyImpact();
        setState(() {
          _firstEntry = null;
          _entry = '';
        });
      }
    } else {
      await vm.unlock(_entry);
      if (vm.status != AccessStatus.unlocked) {
        HapticFeedback.heavyImpact();
        setState(() => _entry = '');
      }
    }
  }

  /// « Passer » : clôt la proposition initiale sans activer de code.
  void _skip() {
    HapticFeedback.selectionClick();
    ref.read(settingsProvider).completeSecurityPrompt(enabled: false);
  }

  /// Après création du code : questions mémo obligatoires, puis proposition
  /// d'empreinte, puis activation de la sécurité et déverrouillage.
  Future<void> _runRecoverySetup() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SecurityQuestionsScreen(mandatory: true),
      ),
    );
    if (!mounted) return;
    await _proposeBiometric();
    if (!mounted) return;
    if (widget.firstRunSetup) {
      await ref.read(settingsProvider).completeSecurityPrompt(enabled: true);
    } else {
      await ref.read(settingsProvider).setSecurityCodeEnabled(true);
    }
    ref.read(accessProvider).finishRecoverySetup();
  }

  /// Propose (si l'appareil le permet) d'activer le déverrouillage par empreinte.
  Future<void> _proposeBiometric() async {
    final vm = ref.read(accessProvider);
    if (!await vm.biometricAvailable()) return;
    if (!mounted) return;
    final t = ref.read(tProvider);
    final enable = await showAppSheet<bool>(
      context: context,
      icon: Icons.fingerprint_rounded,
      title: t.t('biometric.proposeTitle'),
      subtitle: t.t('biometric.proposeSub'),
      accent: AppTheme.indigo,
      builder: (ctx) => Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.fingerprint_rounded),
              label: Text(t.t('biometric.enable')),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t.t('biometric.later')),
            ),
          ),
        ],
      ),
    );
    if (enable == true) {
      await ref.read(settingsProvider).setBiometricEnabled(true);
    }
  }

  String get _title {
    if (!_isSetup) return 'Bon retour 👋';
    return _firstEntry == null ? 'Créez votre code' : 'Confirmez le code';
  }

  String get _subtitle {
    if (!_isSetup) return 'Saisissez votre code pour continuer.';
    return _firstEntry == null
        ? 'Ce code protégera l\'accès à l\'application.'
        : 'Saisissez à nouveau le même code.';
  }

  /// Boutons sous le pavé : « Passer » à la création, ou empreinte + « Code
  /// oublié ? » au déverrouillage.
  Widget _bottomActions(AccessViewModel vm, ColorScheme scheme) {
    final t = ref.read(tProvider);
    if (widget.firstRunSetup) {
      return SizedBox(
        height: 52,
        child: Center(
          child: TextButton(
            onPressed: vm.busy ? null : _skip,
            child: Text(
              'Passer pour l\'instant',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }
    if (vm.status == AccessStatus.locked) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_bioReady)
            TextButton.icon(
              onPressed: vm.busy ? null : _biometricUnlock,
              icon: const Icon(Icons.fingerprint_rounded, size: 20),
              label: Text(t.t('access.useBiometric')),
            ),
          TextButton(
            onPressed: _openForgot,
            child: Text(
              t.t('access.forgot'),
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }
    return const SizedBox(height: 52);
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(accessProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DoodleBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 2),
                const AppLogo(size: 84),
                const SizedBox(height: 30),
                Text(
                  _title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                Text(
                  _subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 38),
                _Dots(
                  filled: _entry.length,
                  total: _pinLength,
                  error: vm.error != null,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 22,
                  child: vm.error != null
                      ? Text(
                          vm.error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppTheme.coral,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        )
                      : null,
                ),
                const Spacer(flex: 3),
                _Keypad(
                  onDigit: _onDigit,
                  onBackspace: _onBackspace,
                  disabled: vm.busy,
                ),
                _bottomActions(vm, scheme),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.filled, required this.total, this.error = false});
  final int filled;
  final int total;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final base = error ? AppTheme.coral : AppTheme.indigo;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final on = i < filled;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          margin: const EdgeInsets.symmetric(horizontal: 9),
          width: on ? 20 : 14,
          height: on ? 20 : 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: on ? AppTheme.brandGradient : null,
            color: on ? null : Colors.transparent,
            border: Border.all(
                color: on ? Colors.transparent : base.withValues(alpha: 0.4),
                width: 2),
            boxShadow: on
                ? [
                    BoxShadow(
                      color: base.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.onDigit,
    required this.onBackspace,
    required this.disabled,
  });
  final void Function(String) onDigit;
  final VoidCallback onBackspace;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '<'];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.9,
      children: keys.map((k) {
        if (k.isEmpty) return const SizedBox.shrink();
        final isBack = k == '<';
        return _KeyButton(
          label: isBack ? null : k,
          icon: isBack ? Icons.backspace_rounded : null,
          onTap: disabled ? null : (isBack ? onBackspace : () => onDigit(k)),
        );
      }).toList(),
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({this.label, this.icon, this.onTap});
  final String? label;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.elevedShadow(strength: 0.5),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Center(
            child: icon != null
                ? Icon(icon, size: 22, color: AppTheme.indigo)
                : Text(
                    label!,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
