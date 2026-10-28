import 'package:enmkit/core/db_service.dart';
import 'package:enmkit/core/security_reset.dart';
import 'package:enmkit/providers.dart';
import 'package:enmkit/ui/screens/wrapper/wrapper.dart';
import 'package:enmkit/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // À chaque (ré)installation/mise à jour : réinitialise le code secret (et lui
  // seul) AVANT l'affichage, pour que l'écran de verrouillage reflète l'état
  // réinitialisé. N'échoue jamais le démarrage si la vérification a un souci.
  try {
    await SecurityResetService(DBService()).resetPinIfBuildChanged();
  } catch (_) {}
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
