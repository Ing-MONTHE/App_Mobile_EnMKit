import 'package:enmkit/providers.dart';
import 'package:enmkit/ui/screens/onboarding/onboarding_art.dart';
import 'package:enmkit/ui/widgets/common/doodle_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tutoriel d'accueil affiché au tout premier lancement (3 pages illustrées).
/// À la fin (ou « Passer »), [onDone] marque l'onboarding comme vu.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next(int total) {
    if (_page < total - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(tProvider);
    final scheme = Theme.of(context).colorScheme;

    final pages = <_OnbPage>[
      _OnbPage(
        art: const ArtRemoteControl(),
        title: t.t('onb.1.title'),
        desc: t.t('onb.1.desc'),
      ),
      _OnbPage(
        art: const ArtConsumption(),
        title: t.t('onb.2.title'),
        desc: t.t('onb.2.desc'),
      ),
      _OnbPage(
        art: const ArtSecurity(),
        title: t.t('onb.3.title'),
        desc: t.t('onb.3.desc'),
      ),
    ];

    final isLast = _page == pages.length - 1;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DoodleBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Bouton "Passer".
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8, top: 4),
                  child: TextButton(
                    onPressed: widget.onDone,
                    child: Text(t.t('onb.skip')),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: pages.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) => pages[i],
                ),
              ),
              // Indicateur de pages.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pages.length, (i) {
                  final sel = i == _page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: sel ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: sel
                          ? scheme.primary
                          : scheme.primary.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _next(pages.length),
                    child: Text(
                      isLast ? t.t('onb.start') : t.t('onb.next'),
                    ),
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

class _OnbPage extends StatelessWidget {
  const _OnbPage({
    required this.art,
    required this.title,
    required this.desc,
  });
  final Widget art;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration vectorielle de la page.
          art
              .animate(key: ValueKey(title))
              .scale(
                  begin: const Offset(0.85, 0.85),
                  duration: 450.ms,
                  curve: Curves.easeOutBack)
              .fadeIn(),
          const SizedBox(height: 36),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ).animate(key: ValueKey('$title-t')).fadeIn(delay: 120.ms).slideY(
              begin: 0.2, end: 0, curve: Curves.easeOut),
          const SizedBox(height: 14),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 15,
              height: 1.5,
            ),
          ).animate(key: ValueKey('$title-d')).fadeIn(delay: 220.ms),
        ],
      ),
    );
  }
}
