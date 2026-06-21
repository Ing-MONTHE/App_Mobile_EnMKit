import 'package:enmkit/providers.dart';
import 'package:enmkit/ui/screens/access/security_questions_screen.dart';
import 'package:enmkit/ui/screens/faq_screen.dart';
import 'package:enmkit/ui/theme/app_theme.dart';
import 'package:enmkit/ui/widgets/common/app_sheet.dart';
import 'package:enmkit/ui/widgets/common/soft_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// (i18n via ref.watch(tProvider).t('clé'))

/// Écran Réglages : apparence (thème), couleur d'accent (« styles »), langue,
/// sécurité (code), à propos. Tout est persisté et appliqué en direct.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(settingsProvider);
    final s = vm.settings;
    final t = ref.watch(tProvider);
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
      children: [
        Text(t.t('settings.title'),
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(
          t.t('settings.subtitle'),
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
        ),
        const SizedBox(height: 22),

        // --- Apparence -------------------------------------------------------
        _Section(
          icon: Icons.dark_mode_rounded,
          accent: AppTheme.indigo,
          title: t.t('settings.appearance'),
          child: _ThemeSelector(
            value: s.themeMode,
            labels: (t.t('settings.light'), t.t('settings.dark'), t.t('settings.auto')),
            onChanged: (m) => ref.read(settingsProvider).setThemeMode(m),
          ),
        ),
        const SizedBox(height: 16),

        // --- Couleur d'accent (styles) --------------------------------------
        _Section(
          icon: Icons.palette_rounded,
          accent: AppTheme.coral,
          title: t.t('settings.accent'),
          subtitle: t.t('settings.accent.sub'),
          child: _AccentSelector(
            value: s.accent,
            onChanged: (a) => ref.read(settingsProvider).setAccent(a),
          ),
        ),
        const SizedBox(height: 16),

        // --- Langue ----------------------------------------------------------
        _Section(
          icon: Icons.translate_rounded,
          accent: AppTheme.emerald,
          title: t.t('settings.language'),
          child: Column(
            children: [
              _RadioRow(
                label: 'Français',
                trailing: '🇫🇷',
                selected: s.locale == 'fr',
                onTap: () => ref.read(settingsProvider).setLocale('fr'),
              ),
              _RadioRow(
                label: 'English',
                trailing: '🇬🇧',
                selected: s.locale == 'en',
                onTap: () => ref.read(settingsProvider).setLocale('en'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // --- Sécurité --------------------------------------------------------
        _Section(
          icon: Icons.lock_rounded,
          accent: AppTheme.amber,
          title: t.t('settings.security'),
          child: Column(
            children: [
              _SwitchRow(
                label: t.t('settings.security.enable'),
                subtitle: t.t('settings.security.enable.sub'),
                value: s.securityCodeEnabled,
                onChanged: (v) => _toggleSecurity(context, ref, v),
              ),
              if (s.securityCodeEnabled) ...[
                const Divider(height: 18),
                _SwitchRow(
                  label: t.t('settings.biometric'),
                  subtitle: t.t('settings.biometric.sub'),
                  value: s.biometricEnabled,
                  onChanged: (v) => _toggleBiometric(context, ref, v),
                ),
                const Divider(height: 18),
                _TileButton(
                  icon: Icons.help_center_rounded,
                  label: t.t('settings.recovery'),
                  onTap: () => _editRecovery(context, ref),
                ),
                const Divider(height: 18),
                _TileButton(
                  icon: Icons.pin_rounded,
                  label: t.t('settings.changePin'),
                  onTap: () => _changePin(context, ref),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // --- Aide (FAQ) ------------------------------------------------------
        _Section(
          icon: Icons.help_outline_rounded,
          accent: AppTheme.violet,
          title: t.t('settings.help'),
          child: _TileButton(
            icon: Icons.quiz_rounded,
            label: t.t('settings.help.faq'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FaqScreen()),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // --- À propos --------------------------------------------------------
        _Section(
          icon: Icons.info_rounded,
          accent: AppTheme.cyan,
          title: t.t('settings.about'),
          child: Column(
            children: [
              _InfoLine(label: t.t('settings.app'), value: 'EnMKit'),
              _InfoLine(label: t.t('settings.version'), value: '1.0.0'),
            ],
          ),
        ),
      ],
    );
  }

  /// Bascule le code de sécurité : active (création) ou désactive (vérification).
  Future<void> _toggleSecurity(
      BuildContext context, WidgetRef ref, bool enable) async {
    if (enable) {
      await _enableSecurity(context, ref);
    } else {
      await _disableSecurity(context, ref);
    }
  }

  /// Active la sécurité : demande la création d'un nouveau code (+ confirmation).
  Future<void> _enableSecurity(BuildContext context, WidgetRef ref) async {
    final newC = TextEditingController();
    final confC = TextEditingController();
    final t = ref.read(tProvider);

    await showAppSheet<void>(
      context: context,
      icon: Icons.lock_rounded,
      title: t.t('settings.security.create.title'),
      subtitle: t.t('settings.security.create.sub'),
      accent: AppTheme.amber,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          return Column(
            children: [
              SheetField(
                controller: newC,
                label: t.t('settings.newPin'),
                icon: Icons.lock_rounded,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),
              SheetField(
                controller: confC,
                label: t.t('settings.confirmPin'),
                icon: Icons.lock_rounded,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final ok = await ref.read(accessProvider).setupSecurity(
                          newC.text.trim(),
                          confC.text.trim(),
                        );
                    if (!ctx.mounted) return;
                    if (ok) {
                      await ref
                          .read(settingsProvider)
                          .setSecurityCodeEnabled(true);
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      HapticFeedback.mediumImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(t.t('settings.security.enabled'))),
                      );
                      // Récupération garantie : on configure les questions mémo
                      // dans la foulée de l'activation du code.
                      if (context.mounted) {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SecurityQuestionsScreen(),
                          ),
                        );
                      }
                    } else {
                      setLocal(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                ref.read(accessProvider).error ?? 'Échec')),
                      );
                    }
                  },
                  child: Text(t.t('common.save')),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Désactive la sécurité : exige le code actuel avant de l'effacer.
  Future<void> _disableSecurity(BuildContext context, WidgetRef ref) async {
    final curC = TextEditingController();
    final t = ref.read(tProvider);

    await showAppSheet<void>(
      context: context,
      icon: Icons.lock_open_rounded,
      title: t.t('settings.security.disable.title'),
      subtitle: t.t('settings.security.disable.sub'),
      accent: AppTheme.amber,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          return Column(
            children: [
              SheetField(
                controller: curC,
                label: t.t('settings.currentPin'),
                icon: Icons.lock_outline_rounded,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final ok = await ref
                        .read(accessProvider)
                        .disableSecurity(curC.text.trim());
                    if (!ctx.mounted) return;
                    if (ok) {
                      await ref
                          .read(settingsProvider)
                          .setSecurityCodeEnabled(false);
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      HapticFeedback.mediumImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text(t.t('settings.security.disabled'))),
                      );
                    } else {
                      setLocal(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                ref.read(accessProvider).error ?? 'Échec')),
                      );
                    }
                  },
                  child: Text(t.t('common.save')),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Active/désactive le déverrouillage par empreinte (vérifie la disponibilité).
  Future<void> _toggleBiometric(
      BuildContext context, WidgetRef ref, bool enable) async {
    final t = ref.read(tProvider);
    if (enable) {
      final available = await ref.read(accessProvider).biometricAvailable();
      if (!context.mounted) return;
      if (!available) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.t('settings.biometric.unavailable'))),
        );
        return;
      }
    }
    await ref.read(settingsProvider).setBiometricEnabled(enable);
    HapticFeedback.selectionClick();
  }

  /// Ouvre l'écran d'édition des questions mémo de récupération.
  Future<void> _editRecovery(BuildContext context, WidgetRef ref) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SecurityQuestionsScreen()),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(tProvider).t('recovery.saved'))),
      );
    }
  }

  Future<void> _changePin(BuildContext context, WidgetRef ref) async {
    final oldC = TextEditingController();
    final newC = TextEditingController();
    final confC = TextEditingController();

    final t = ref.read(tProvider);
    await showAppSheet<void>(
      context: context,
      icon: Icons.pin_rounded,
      title: t.t('settings.changePin.title'),
      subtitle: t.t('settings.changePin.sub'),
      accent: AppTheme.amber,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          return Column(
            children: [
              SheetField(
                controller: oldC,
                label: t.t('settings.currentPin'),
                icon: Icons.lock_outline_rounded,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),
              SheetField(
                controller: newC,
                label: t.t('settings.newPin'),
                icon: Icons.lock_rounded,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),
              SheetField(
                controller: confC,
                label: t.t('settings.confirmPin'),
                icon: Icons.lock_rounded,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final ok = await ref.read(accessProvider).changePin(
                          oldC.text.trim(),
                          newC.text.trim(),
                          confC.text.trim(),
                        );
                    if (!ctx.mounted) return;
                    if (ok) {
                      Navigator.pop(ctx);
                      HapticFeedback.mediumImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(t.t('settings.pinUpdated'))),
                      );
                    } else {
                      setLocal(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(ref.read(accessProvider).error ??
                                'Échec')),
                      );
                    }
                  },
                  child: Text(t.t('common.save')),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.accent,
    required this.title,
    this.subtitle,
    required this.child,
  });
  final IconData icon;
  final Color accent;
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconPill(icon: icon, color: accent, size: 32),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// Sélecteur de thème segmenté (Clair / Sombre / Auto).
class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({
    required this.value,
    required this.labels,
    required this.onChanged,
  });
  final ThemeMode value;
  final (String, String, String) labels;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = [
      (ThemeMode.light, Icons.light_mode_rounded, labels.$1),
      (ThemeMode.dark, Icons.dark_mode_rounded, labels.$2),
      (ThemeMode.system, Icons.brightness_auto_rounded, labels.$3),
    ];
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: items.map((it) {
          final sel = value == it.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(it.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: sel ? scheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Column(
                  children: [
                    Icon(it.$2,
                        size: 20,
                        color: sel ? Colors.white : scheme.onSurfaceVariant),
                    const SizedBox(height: 4),
                    Text(
                      it.$3,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Palette d'accents : pastilles colorées sélectionnables.
class _AccentSelector extends StatelessWidget {
  const _AccentSelector({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: AppTheme.accents.entries.map((e) {
        final sel = value == e.key;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(e.key);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [e.value, Color.lerp(e.value, Colors.white, 0.3)!],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: e.value.withValues(alpha: sel ? 0.5 : 0.25),
                  blurRadius: sel ? 14 : 8,
                  offset: const Offset(0, 5),
                ),
              ],
              border: sel
                  ? Border.all(
                      color: Theme.of(context).colorScheme.onSurface, width: 2.5)
                  : null,
            ),
            child: sel
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

class _RadioRow extends StatelessWidget {
  const _RadioRow({
    required this.label,
    required this.trailing,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String trailing;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ),
            Text(trailing,
                style:
                    TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _TileButton extends StatelessWidget {
  const _TileButton(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 21, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(
                child: Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: scheme.onSurfaceVariant)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
