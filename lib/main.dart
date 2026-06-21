import 'package:enmkit/providers.dart';
import 'package:enmkit/ui/screens/wrapper/wrapper.dart';
import 'package:enmkit/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).settings;
    return MaterialApp(
      title: 'EnMKit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(accent: settings.accent),
      darkTheme: AppTheme.dark(accent: settings.accent),
      themeMode: settings.themeMode,
      // Internationalisation : la langue suit le réglage de l'utilisateur.
      locale: Locale(settings.locale),
      supportedLocales: const [Locale('fr'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const RootPage(),
    );
  }
}
