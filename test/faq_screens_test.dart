// Rendu de la FAQ (accueil + catégories) en français et en anglais, et
// complétude des clés de traduction `faq.*`.

import 'package:enmkit/core/i18n/strings.dart';
import 'package:enmkit/providers.dart';
import 'package:enmkit/ui/screens/faq_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Widget _app(String lang) => ProviderScope(
      overrides: [tProvider.overrideWithValue(AppStrings(lang))],
      child: const MaterialApp(home: FaqScreen()),
    );

Future<void> _pump(WidgetTester tester, String lang) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(lang));
  await tester.pumpAndSettle();
}

/// Nombre de questions par catégorie (doit suivre les écrans).
const _counts = {'access': 7, 'kit': 9, 'qr': 5, 'ai': 10, 'trouble': 7};

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  test('Chaque question et réponse existe en FR et en EN, sans tiret long', () {
    final fr = AppStrings('fr');
    final en = AppStrings('en');
    final keys = <String>['faq.title'];
    _counts.forEach((cat, n) {
      keys.addAll(['faq.home.$cat', 'faq.home.$cat.sub']);
      for (var i = 1; i <= n; i++) {
        keys.addAll(['faq.$cat.q$i', 'faq.$cat.a$i']);
      }
    });
    for (final k in keys) {
      expect(fr.t(k), isNot(k), reason: 'clé FR manquante : $k');
      expect(en.t(k), isNot(k), reason: 'clé EN manquante : $k');
      if (k != 'faq.title') {
        expect(en.t(k), isNot(fr.t(k)), reason: 'EN non traduit : $k');
      }
      for (final s in [fr.t(k), en.t(k)]) {
        expect(s.contains('—') || s.contains('–'), isFalse, reason: k);
      }
    }
  });

  testWidgets('FAQ en français : accueil puis Kit et lignes', (tester) async {
    await _pump(tester, 'fr');
    expect(find.text('Accès et sécurité'), findsOneWidget);
    expect(find.text('IA et apprentissage'), findsOneWidget);
    expect(find.text('Dépannage'), findsOneWidget);

    await tester.tap(find.text('Kit et lignes'));
    await tester.pumpAndSettle();
    expect(find.text('Comment ajouter un kit ?'), findsOneWidget);
    await tester.tap(find.text('Comment vérifier que le kit répond ?'));
    await tester.pumpAndSettle();
    expect(find.textContaining('« Tester »'), findsOneWidget);
  });

  testWidgets('FAQ in English: home then Access and security', (tester) async {
    await _pump(tester, 'en');
    expect(find.text('Kit and lines'), findsOneWidget);
    expect(find.text('AI and learning'), findsOneWidget);

    await tester.tap(find.text('Access and security'));
    await tester.pumpAndSettle();
    expect(find.text('Is the access code mandatory?'), findsOneWidget);
    await tester.tap(find.text('How do I create the code?'));
    await tester.pumpAndSettle();
    expect(find.textContaining('exactly 4 digits'), findsOneWidget);
  });

  testWidgets('FAQ IA et apprentissage (EN) se construit', (tester) async {
    await _pump(tester, 'en');
    await tester.tap(find.text('AI and learning'));
    await tester.pumpAndSettle();
    expect(find.text('Where does the AI analysis data come from?'), findsOneWidget);
  });
}
