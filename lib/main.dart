import 'package:enmkit/ui/screens/wrapper/wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Contrôle Kit Électrique',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,  // automatique selon les réglages du téléphone
      home: const RootPage(),
    );
  }
}

