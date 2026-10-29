// Rendu des nouveaux écrans (Analyse IA, module Apprendre, fiches TP, quiz,
// assistant) avec des dépôts factices : détecte les erreurs de mise en page
// (débordements, contraintes) sans base de données ni SMS.

import 'package:enmkit/core/db_service.dart';
import 'package:enmkit/core/education/education_content.dart';
import 'package:enmkit/core/i18n/strings.dart';
import 'package:enmkit/core/sms_service_hybrid.dart';
import 'package:enmkit/models/education_models.dart';
import 'package:enmkit/models/hourly_consumption_model.dart';
import 'package:enmkit/models/kit_model.dart';
import 'package:enmkit/models/server_config_model.dart';
import 'package:enmkit/providers.dart';
import 'package:enmkit/repositories/consumption_repository.dart';
import 'package:enmkit/repositories/education_repository.dart';
import 'package:enmkit/repositories/hourly_consumption_repository.dart';
import 'package:enmkit/repositories/kit_repository.dart';
import 'package:enmkit/repositories/server_config_repository.dart';
import 'package:enmkit/ui/screens/assistant/assistant_screen.dart';
import 'package:enmkit/ui/screens/education/education_screen.dart';
import 'package:enmkit/ui/screens/education/quiz_screen.dart';
import 'package:enmkit/ui/screens/education/reference_screens.dart';
import 'package:enmkit/ui/screens/education/tp_detail_screen.dart';
import 'package:enmkit/ui/screens/kit_detail/widgets/analysis_tab.dart';
import 'package:enmkit/ui/widgets/common/soft_card.dart';
import 'package:enmkit/viewmodels/consumption_viewmodel.dart';
import 'package:enmkit/viewmodels/education_viewmodel.dart';
import 'package:enmkit/viewmodels/hourly_consumption_viewmodel.dart';
import 'package:enmkit/viewmodels/kit_viewmodel.dart';
import 'package:enmkit/viewmodels/relay_viewmodel.dart';
import 'package:enmkit/viewmodels/server_config_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

const _kit = '+237699000000';
final _now = DateTime(2026, 6, 28, 23, 30);

class _FakeHourlyRepo extends HourlyConsumptionRepository {
  _FakeHourlyRepo(this.rows) : super(DBService());
  final List<HourlyConsumptionModel> rows;
  @override
  Future<List<HourlyConsumptionModel>> getHourly(String kitNumber,
          {DateTime? from, DateTime? to}) async =>
      rows;
}

class _FakeEduRepo extends EducationRepository {
  _FakeEduRepo() : super(DBService());
  @override
  Future<Map<String, Set<int>>> loadProgress() async => {};
  @override
  Future<Map<String, QuizRecord>> loadScores() async => {};
  @override
  Future<List<ScenarioWindow>> loadScenarios() async => [];
  @override
  Future<void> setStep(String tpCode, int stepIndex, bool done) async {}
  @override
  Future<void> saveScore(QuizRecord record) async {}
  @override
  Future<void> saveScenario(ScenarioWindow w) async {}
}

class _FakeServerRepo extends ServerConfigRepository {
  _FakeServerRepo() : super(DBService());
  @override
  Future<ServerConfig> load() async => const ServerConfig();
}

class _FakeKitVM extends KitViewModel {
  _FakeKitVM(this._list) : super(DBService());
  final List<KitModel> _list;
  @override
  List<KitModel> get kits => _list;
  @override
  Future<void> fetchKits() async {}
}

class _FakeRelayVM extends RelayViewModel {
  _FakeRelayVM()
      : super(DBService(), SmsServiceHybrid(KitRepository(DBService())));
  @override
  Future<void> fetchRelays() async {}
}

List<HourlyConsumptionModel> _rows() => [
      for (var d = 0; d < 28; d++)
        for (var h = 0; h < 24; h++)
          HourlyConsumptionModel(
            kitNumber: _kit,
            hourStart: DateTime(2026, 6, 1 + d, h),
            kwh: h <= 5 ? 0.05 : (h <= 17 ? 0.2 : (h <= 22 ? 0.6 : 0.1)) +
                (d == 27 && h == 20 ? 1.4 : 0),
            receivedAt: DateTime(2026, 6, 1 + d, h + 1),
          ),
    ];

Widget _app(Widget child, {List<HourlyConsumptionModel>? rows, String lang = 'fr'}) {
  return ProviderScope(
    overrides: [
      tProvider.overrideWithValue(AppStrings(lang)),
      kitProvider.overrideWith((ref) =>
          _FakeKitVM([KitModel(kitNumber: _kit, name: 'Banc', pulseCount: 1000)])),
      kitHourlyProvider.overrideWith((ref, k) {
        final vm = HourlyConsumptionViewModel(_FakeHourlyRepo(rows ?? _rows()),
            kitNumber: k, clock: () => _now);
        vm.load();
        return vm;
      }),
      kitConsumptionProvider.overrideWith(
          (ref, k) => ConsumptionViewModel(ConsumptionRepository(DBService()), kitNumber: k)),
      kitRelaysProvider.overrideWith((ref, k) => _FakeRelayVM()),
      educationProvider.overrideWith((ref) {
        final vm = EducationViewModel(_FakeEduRepo());
        vm.load();
        return vm;
      }),
      serverConfigProvider
          .overrideWith((ref) => ServerConfigViewModel(_FakeServerRepo())),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

/// Démonte l'arbre et laisse expirer les minuteries d'animation en attente.
Future<void> _end(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 5));
}

Future<void> _pump(WidgetTester tester, Widget w) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(w);
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  // Pas de téléchargement de police pendant les tests.
  GoogleFonts.config.allowRuntimeFetching = false;
  // google_fonts signale (en asynchrone) l'absence de police locale : sans
  // incidence sur la mise en page testée ici.
  final origOnError = FlutterError.onError;
  setUp(() {
    FlutterError.onError = (d) {
      if ('${d.exception}'.contains('GoogleFonts') ||
          '${d.exception}'.contains('google_fonts')) {
        return;
      }
      origOnError?.call(d);
    };
  });
  tearDown(() => FlutterError.onError = origOnError);

  testWidgets('Analyse IA avec données (FR)', (tester) async {
    await _pump(tester, _app(const AnalysisTab(kitNumber: _kit)));
    expect(find.textContaining('Note'), findsWidgets);
    await tester.drag(find.byType(ListView).first, const Offset(0, -3000));
    await tester.pump(const Duration(seconds: 1));
    await _end(tester);
  });

  testWidgets('Analyse IA vide (EN)', (tester) async {
    await _pump(tester, _app(const AnalysisTab(kitNumber: _kit), rows: const [], lang: 'en'));
    expect(find.text('No hourly frames yet'), findsOneWidget);
    await _end(tester);
  });

  testWidgets('Module Apprendre (hub)', (tester) async {
    await _pump(tester, _app(const EducationScreen()));
    expect(find.text('Éducation énergétique'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -4000));
    await tester.pump(const Duration(seconds: 1));
    await _end(tester);
  });

  for (final m in EducationContent.modules) {
    testWidgets('Fiche ${m.code}', (tester) async {
      await _pump(tester, _app(TpDetailScreen(code: m.code)));
      expect(find.textContaining(m.code), findsWidgets);
      await tester.drag(find.byType(ListView).first, const Offset(0, -5000));
      await tester.pump(const Duration(seconds: 1));
      await _end(tester);
    });
  }

  testWidgets('Quiz TP1 : répondre et valider', (tester) async {
    await _pump(tester, _app(const QuizScreen(code: 'TP1')));
    final q = EducationContent.byCode('TP1')!.quiz;
    for (var i = 0; i < q.length; i++) {
      final label = q[i].choices[q[i].answerIndex].fr;
      // Un même libellé peut figurer dans deux questions : on cible la carte.
      final title = find.text('${i + 1}. ${q[i].question.fr}');
      await tester.scrollUntilVisible(title, 200,
          scrollable: find.byType(Scrollable).first);
      final f = find.descendant(
          of: find.ancestor(of: title, matching: find.byType(SoftCard)),
          matching: find.text(label));
      await tester.ensureVisible(f);
      await tester.tap(f);
      await tester.pump();
    }
    final validate = find.text('Valider mes réponses');
    await tester.scrollUntilVisible(validate, 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(validate);
    await tester.pump(const Duration(milliseconds: 300));
    // Le résultat s'affiche en tête de liste : on remonte.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 5000));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('4/4'), findsOneWidget);
    await _end(tester);
  });

  testWidgets('Glossaire et éco-gestes', (tester) async {
    await _pump(tester, _app(const GlossaryScreen()));
    expect(find.text('Glossaire'), findsOneWidget);
    await _pump(tester, _app(const TipsScreen()));
    expect(find.text('Éco-gestes'), findsOneWidget);
    await _end(tester);
  });

  testWidgets('Assistant hors-ligne', (tester) async {
    await _pump(tester, _app(const AssistantScreen(kitNumber: _kit)));
    await tester.tap(find.text('Qu\'est-ce que la veille ?'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Réponse hors-ligne'), findsOneWidget);
    await _end(tester);
  });
}
