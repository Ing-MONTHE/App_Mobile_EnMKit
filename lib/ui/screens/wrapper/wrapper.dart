import 'dart:async';

import 'package:enmkit/providers.dart';
import 'package:enmkit/ui/screens/access/access_screen.dart';
import 'package:enmkit/ui/screens/onboarding/onboarding_screen.dart';
import 'package:enmkit/ui/screens/shell/main_shell.dart';
import 'package:enmkit/ui/widgets/common/brand_loader.dart';
import 'package:enmkit/viewmodels/access_viewmodel.dart';
import 'package:enmkit/viewmodels/settings_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

/// Point d'entrée : l'accès à l'app est gardé par un code d'accès (PIN).
/// Gère aussi la réception des SMS en arrière-plan : à l'ouverture et à chaque
/// reprise, on draine la file native des SMS du kit et on les traite.
class RootPage extends ConsumerStatefulWidget {
  const RootPage({super.key});

  @override
  ConsumerState<RootPage> createState() => _RootPageState();
}

class _RootPageState extends ConsumerState<RootPage>
    with WidgetsBindingObserver {
  StreamSubscription<void>? _smsTickSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _requestPermissions();
      await _syncAndDrain();
    });
    // Drain immédiat quand un SMS de kit arrive pendant que l'app est ouverte.
    _smsTickSub =
        ref.read(backgroundSmsBridgeProvider).onNewSms.listen((_) => _drain());
  }

  @override
  void dispose() {
    _smsTickSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncAndDrain();
    } else if (state == AppLifecycleState.paused) {
      // Reverrouille l'app : il faudra ressaisir le code à la reprise.
      ref.read(accessProvider).lock();
    }
  }

  Future<void> _requestPermissions() async {
    // SMS (réception/envoi) et notifications (Android 13+).
    await [Permission.sms, Permission.notification].request();
  }

  Future<void> _syncAndDrain() async {
    await _pushKitNumbers();
    await _drain();
  }

  /// Pousse au natif la liste des numéros de kits, pour le filtrage à la réception.
  Future<void> _pushKitNumbers() async {
    try {
      final kits = await ref.read(kitRepositoryProvider).getKit();
      final numbers = kits
          .map((k) => k.kitNumber)
          .whereType<String>()
          .where((n) => n.isNotEmpty)
          .toList();
      await ref.read(backgroundSmsBridgeProvider).setKitNumbers(numbers);
    } catch (_) {
      // Canal natif indisponible (ex. plateforme non Android) : ignore.
    }
  }

  /// Draine la file native et applique les SMS à la base, puis rafraîchit l'UI.
  Future<void> _drain() async {
    try {
      final msgs = await ref.read(backgroundSmsBridgeProvider).drainPending();
      if (msgs.isEmpty) return;
      final processor = ref.read(smsInboxProcessorProvider);
      final affected = <String>{};
      for (final m in msgs) {
        final kitNumber = await processor.process(m);
        if (kitNumber != null) {
          affected.add(kitNumber);
          // Réinjecte le SMS brut dans le flux temps réel du kit : ainsi les
          // attentes d'accusé (confirmation de config, joignabilité) le voient
          // même si readsms n'a rien émis — le natif étant la voie fiable.
          ref.read(kitSmsListenerProvider(kitNumber)).injectTrustedSms(m.body);
        }
      }
      // Invalide les providers scopés des kits impactés pour rafraîchir l'écran.
      for (final k in affected) {
        ref.invalidate(kitConsumptionProvider(k));
        ref.invalidate(kitRelaysProvider(k));
      }
    } catch (_) {
      // Ne jamais faire planter l'app sur un drain raté.
    }
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(accessProvider);
    final settingsVM = ref.watch(settingsProvider);

    // Transition douce entre les grands états de l'app
    // (splash → onboarding → PIN → accueil).
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      child: _screenFor(access.status, settingsVM),
    );
  }

  Widget _screenFor(AccessStatus status, SettingsViewModel settingsVM) {
    // Au tout premier lancement : tutoriel d'accueil avant le code d'accès.
    if (settingsVM.loaded && !settingsVM.settings.onboardingSeen) {
      return OnboardingScreen(
        key: const ValueKey('onboarding'),
        onDone: () => ref.read(settingsProvider).setOnboardingSeen(),
      );
    }

    // Premier lancement : on PROPOSE de créer un code, mais de façon SKIPPABLE
    // (bouton « Passer »). La sécurité est offerte, jamais imposée.
    if (settingsVM.loaded &&
        !settingsVM.settings.securityCodeEnabled &&
        !settingsVM.settings.securityPromptSeen) {
      return const AccessScreen(
        key: ValueKey('access-setup'),
        firstRunSetup: true,
      );
    }

    // Code de sécurité optionnel : s'il est désactivé, on entre directement.
    if (settingsVM.loaded && !settingsVM.settings.securityCodeEnabled) {
      return const MainShell(key: ValueKey('shell'));
    }

    switch (status) {
      case AccessStatus.unknown:
        return const BrandLoadingScreen(
          key: ValueKey('splash'),
          message: 'EnMKit',
        );
      case AccessStatus.needsSetup:
      case AccessStatus.needsRecoverySetup:
      case AccessStatus.locked:
        return const AccessScreen(key: ValueKey('access'));
      case AccessStatus.unlocked:
        return const MainShell(key: ValueKey('shell'));
    }
  }
}
