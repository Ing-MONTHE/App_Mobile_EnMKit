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
    // Ici tu peux naviguer vers login ou home
    // Navigator.pushReplacementNamed(context, '/login');
    print('Onboarding terminé');
  }
}
