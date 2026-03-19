import 'package:enmkit/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/onboarding/onboarding_page.dart';
import '../../widgets/onboarding/onboarding_indicator.dart';
import '../../widgets/onboarding/onboarding_buttons.dart';
import '../../../core/constants/onboarding_constants.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(onboardingVMProvider);
    final controller = vm.pageController;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: controller,
                itemCount: OnboardingTexts.titles.length,
                onPageChanged: vm.setPage,
                itemBuilder: (context, index) {
                  return OnboardingPage(
                    imagePath: 'assets/images/onboarding/step${index + 1}.png',
                    title: OnboardingTexts.titles[index],
                    description: OnboardingTexts.descriptions[index],
                  );
                },
              ),
            ),
            OnboardingIndicator(
              currentPage: vm.currentPage,
              totalPages: OnboardingTexts.titles.length,
            ),
            const SizedBox(height: 20),
            OnboardingButtons(
              currentPage: vm.currentPage,
              totalPages: OnboardingTexts.titles.length,
              onNext: vm.nextPage,
              onSkip: vm.skipOnboarding,
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
