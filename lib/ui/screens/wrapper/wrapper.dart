import 'package:enmkit/providers.dart';
import 'package:enmkit/ui/screens/auth/auth_screen.dart';
import 'package:enmkit/ui/screens/home/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RootPage extends ConsumerWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Loader si en cours
    if (authState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Si user connecté => HomePage
    if (authState.user != null) {
      return const MainScreen();
    }

    // Sinon => LoginPage
    return const AuthScreen();
  }
}
