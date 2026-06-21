import 'package:flutter/material.dart';

class OnboardingVM extends ChangeNotifier {
  final PageController pageController = PageController();
  int currentPage = 0;

  void setPage(int index) {
    currentPage = index;
    notifyListeners();
  }

  void nextPage() {
    if (currentPage < 2) { // total pages - 1
      pageController.animateToPage(
        currentPage + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      skipOnboarding(); // dernier écran
    }
  }

  void skipOnboarding() {
    // Fin de l'onboarding : la navigation est gérée par le wrapper selon l'état.
  }
}
