import 'package:enmkit/core/ai/energy_insights.dart';
import 'package:enmkit/core/education/education_content.dart';
import 'package:enmkit/models/education_models.dart';
import 'package:enmkit/models/kit_model.dart';
import 'package:enmkit/providers.dart';
import 'package:enmkit/ui/screens/education/education_screen.dart';
import 'package:enmkit/ui/screens/kit_detail/kit_detail_screen.dart';
import 'package:enmkit/ui/screens/kit_detail/widgets/analysis_tab.dart'
    show gradeColor;
import 'package:enmkit/ui/theme/app_theme.dart';
import 'package:enmkit/ui/widgets/common/soft_card.dart';
import 'package:enmkit/viewmodels/education_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

String _two(int n) => n.toString().padLeft(2, '0');
String _dh(DateTime d) =>
    '${_two(d.day)}/${_two(d.month)} ${_two(d.hour)}:00';

/// Données « en direct » d'une fiche TP, tirées du kit du banc.
class EduLiveSection extends ConsumerWidget {
  const EduLiveSection({super.key, required this.module});
  final EduModule module;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kit = educationKit(ref);
    final cards = <Widget>[const EducationKitSelector()];
    if (kit != null) {
      switch (module.live) {
        case EduLive.meter:
          cards.addAll([_MeterCard(kit: kit), const EnergyCalculatorCard()]);
        case EduLive.circuits:
          cards.addAll([
            _CircuitsCard(kit: kit),
            const EnergyCalculatorCard(showCurrent: true),
          ]);
        case EduLive.remote:
          cards.add(_OpenKitCard(kit: kit, tab: 0));
        case EduLive.compare:
          cards.add(ScenarioCompareCard(module: module, kit: kit));
        case EduLive.efficiency:
          cards.addAll([
            _ScoreMiniCard(kit: kit),
            if (module.scenarioHint != null)
              ScenarioCompareCard(module: module, kit: kit),
          ]);
        case EduLive.iot:
          cards.addAll([
            _IotCard(kit: kit),
            _OpenKitCard(kit: kit, tab: KitDetailScreen.analysisTab),
          ]);
        case null:
          break;
      }
    }
    return Column(
      children: [
        for (final c in cards)
          Padding(padding: const EdgeInsets.only(bottom: 12), child: c),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

/// TP1 : constante du compteur, index, dernière trame → puissance moyenne.
class _MeterCard extends ConsumerWidget {
  const _MeterCard({required this.kit});
  final KitModel kit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    final cons = ref.watch(kitConsumptionProvider(kit.kitNumber)).consumptions;
    final hourly = ref.watch(kitHourlyProvider(kit.kitNumber));
    final ip = kit.pulseCount;
    final lastIndex = cons.isEmpty
        ? null
        : cons.reduce((a, b) => a.timestamp.isAfter(b.timestamp) ? a : b);
    final f = hourly.latest;
    return SoftCard(
      child: Column(
        children: [
          _Row(
            t.t('edu.meter.pulse'),
            ip == null || ip <= 0
                ? '-'
                : t.tf('edu.meter.pulseVal',
                    [ip, (1000 / ip).toStringAsFixed(ip >= 1000 ? 0 : 2)]),
          ),
          _Row(t.t('edu.meter.initial'),
              '${kit.initialConsumption ?? 0} kWh'),
          _Row(
            t.t('edu.meter.lastIndex'),
            lastIndex == null
                ? '-'
                : '${lastIndex.kwh} kWh · ${_dh(lastIndex.timestamp)}',
          ),
          _Row(
            t.t('edu.meter.lastFrame'),
            f == null
                ? '-'
                : t.tf('edu.meter.lastFrameVal', [
                    f.kwh.toStringAsFixed(2),
                    _two(f.hourStart.hour),
                    _two((f.hourStart.hour + 1) % 24),
                    (f.kwh * 1000).round(),
                  ]),
          ),
        ],
      ),
    );
  }
}

/// Calculatrice E = P × t (+ coût FCFA, + courant I = P/U en option).
class EnergyCalculatorCard extends ConsumerStatefulWidget {
  const EnergyCalculatorCard({super.key, this.showCurrent = false});
  final bool showCurrent;

  @override
  ConsumerState<EnergyCalculatorCard> createState() =>
      _EnergyCalculatorCardState();
}

class _EnergyCalculatorCardState extends ConsumerState<EnergyCalculatorCard> {
  final _p = TextEditingController(text: '60');
  final _h = TextEditingController(text: '5');

  @override
  void dispose() {
    _p.dispose();
    _h.dispose();
    super.dispose();
  }

  double _num(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.')) ?? 0;

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(tProvider);
    final p = _num(_p);
    final h = _num(_h).clamp(0, 24).toDouble();
    final day = p * h / 1000;
    final month = day * 30;
    final cost = EnergyTariff.costFcfa(month);
    InputDecoration deco(String label) => InputDecoration(
          labelText: label,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        );
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconPill(
                  icon: Icons.calculate_rounded,
                  color: AppTheme.indigo,
                  size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Text(t.t('edu.calc.title'),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _p,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: deco(t.t('edu.calc.power')),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _h,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: deco(t.t('edu.calc.hours')),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            t.tf('edu.calc.result', [
              day.toStringAsFixed(2),
              month.toStringAsFixed(1),
              cost.round(),
            ]),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (widget.showCurrent) ...[
            const SizedBox(height: 4),
            Text(t.tf('edu.calc.current', [(p / 220).toStringAsFixed(2)])),
          ],
        ],
      ),
    );
  }
}

/// TP2 : état des lignes du banc (L1-L2 ampoules, L3-L4 prises).
class _CircuitsCard extends ConsumerWidget {
  const _CircuitsCard({required this.kit});
  final KitModel kit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    final relays = [...ref.watch(kitRelaysProvider(kit.kitNumber)).relays]
      ..sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));
    final scheme = Theme.of(context).colorScheme;
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.t('edu.circuits.lines'),
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(t.t('edu.circuits.hint'),
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5)),
          const SizedBox(height: 8),
          for (var i = 0; i < relays.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    i < 2 ? Icons.lightbulb_rounded : Icons.power_rounded,
                    size: 20,
                    color: relays[i].isActive
                        ? AppTheme.amber
                        : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text('L${i + 1} · ${relays[i].name ?? ''}')),
                  StatusBadge(
                    label: t.t(relays[i].isActive ? 'edu.on' : 'edu.off'),
                    color: relays[i].isActive
                        ? AppTheme.emerald
                        : scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          _OpenKitButton(kit: kit, tab: 0, label: t.t('edu.open.kit')),
        ],
      ),
    );
  }
}

class _OpenKitButton extends StatelessWidget {
  const _OpenKitButton(
      {required this.kit, required this.tab, required this.label});
  final KitModel kit;
  final int tab;
  final String label;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => KitDetailScreen(kit: kit, initialTab: tab)),
        ),
        icon: Icon(tab == KitDetailScreen.analysisTab
            ? Icons.auto_graph_rounded
            : Icons.toggle_on_rounded),
        label: Text(label),
      );
}

class _OpenKitCard extends ConsumerWidget {
  const _OpenKitCard({required this.kit, required this.tab});
  final KitModel kit;
  final int tab;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    return SizedBox(
      width: double.infinity,
      child: _OpenKitButton(
        kit: kit,
        tab: tab,
        label: t.t(tab == KitDetailScreen.analysisTab
            ? 'edu.open.analysis'
            : 'edu.open.kit'),
      ),
    );
  }
}

/// TP5 : rappel du score d'efficacité et de la veille, lien vers l'analyse.
class _ScoreMiniCard extends ConsumerWidget {
  const _ScoreMiniCard({required this.kit});
  final KitModel kit;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    final vm = ref.watch(kitHourlyProvider(kit.kitNumber));
    if (!vm.hasData) {
      return SoftCard(
        child: Text(t.t('ai.empty.title'),
            style: const TextStyle(fontWeight: FontWeight.w600)),
      );
    }
    final ins = vm.insights(t.locale);
    final c = gradeColor(ins.score.grade);
    return SoftCard(
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: c,
                child: Text(ins.score.grade,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                    '${t.t('ai.score')} : ${ins.score.value.round()}/100',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _Row(t.t('ai.baseLoad'),
              '${(ins.baseLoadKw * 1000).round()} W · ${(ins.baseLoadShare * 100).round()} %'),
          _Row(
              t.t('ai.peakHour'),
              ins.peakHour == null
                  ? '-'
                  : '${_two(ins.peakHour!)}h · ${(ins.peakShare * 100).round()} %'),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: _OpenKitButton(
                kit: kit,
                tab: KitDetailScreen.analysisTab,
                label: t.t('edu.open.analysis')),
          ),
        ],
      ),
    );
  }
}

/// TP6 : dernière trame brute et décodée + qualité des données.
class _IotCard extends ConsumerWidget {
  const _IotCard({required this.kit});
  final KitModel kit;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    final vm = ref.watch(kitHourlyProvider(kit.kitNumber));
    final f = vm.latest;
    final scheme = Theme.of(context).colorScheme;
    if (f == null) {
      return SoftCard(
        child: Text(t.t('edu.iot.none'),
            style: TextStyle(color: scheme.onSurfaceVariant)),
      );
    }
    final d = f.hourStart;
    final raw =
        '${_two(d.day)}/${_two(d.month)}/${_two(d.year % 100)};${_two(d.hour)};${f.kwh.toStringAsFixed(2)}';
    final ins = vm.insights(t.locale);
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.t('edu.iot.title'),
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(raw,
                style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
          _Row(t.t('edu.iot.date'),
              '${_two(d.day)}/${_two(d.month)}/${d.year}'),
          _Row(t.t('edu.iot.slot'),
              '${_two(d.hour)}:00 → ${_two((d.hour + 1) % 24)}:00'),
          _Row(t.t('edu.iot.energy'),
              '${f.kwh.toStringAsFixed(2)} kWh (≈ ${(f.kwh * 1000).round()} W)'),
          _Row(t.t('edu.iot.count'), '${vm.points.length}'),
          _Row(t.t('edu.iot.completeness'),
              '${(ins.dataQuality.completeness * 100).round()} %'),
        ],
      ),
    );
  }
}

/// TP4 / TP5 / TP7 : fenêtres « Scénario A » et « Scénario B » marquées par
/// l'apprenant, énergie calculée à partir des trames horaires, comparaison.
class ScenarioCompareCard extends ConsumerWidget {
  const ScenarioCompareCard(
      {super.key, required this.module, required this.kit});
  final EduModule module;
  final KitModel kit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    final edu = ref.watch(educationProvider);
    final hourly = ref.watch(kitHourlyProvider(kit.kitNumber));
    final scheme = Theme.of(context).colorScheme;
    final now = EducationViewModel.roundHour(DateTime.now());

    ({double kwh, int expectedHours, int receivedHours})? measure(
        ScenarioWindow? w) {
      if (w == null) return null;
      return hourly.energyBetween(w.startAt, w.endAt ?? now);
    }

    final a = edu.scenario(module.code, 'A');
    final b = edu.scenario(module.code, 'B');
    final ma = measure(a);
    final mb = measure(b);

    Widget? result;
    if (a?.endAt != null &&
        b?.endAt != null &&
        ma != null &&
        mb != null &&
        ma.expectedHours > 0 &&
        mb.expectedHours > 0 &&
        ma.receivedHours > 0 &&
        mb.receivedHours > 0) {
      // Comparaison PAR HEURE : équitable même si les durées diffèrent.
      final ra = ma.kwh / ma.receivedHours;
      final rb = mb.kwh / mb.receivedHours;
      final diff = ra - rb;
      final pct = ra > 0 ? (diff.abs() / ra * 100).round() : 0;
      final monthKwh = diff.abs() * 5 * 30;
      final incomplete = ma.receivedHours < ma.expectedHours ||
          mb.receivedHours < mb.expectedHours;
      final txt = diff.abs() < 0.005
          ? t.t('edu.cmp.result.equal')
          : t.tf(diff > 0 ? 'edu.cmp.result.less' : 'edu.cmp.result.more',
              [diff.abs().toStringAsFixed(3), pct]);
      result = Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: (diff >= 0 ? AppTheme.emerald : AppTheme.coral)
              .withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(txt, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(t.tf('edu.cmp.month',
                [monthKwh.toStringAsFixed(1), (monthKwh * 79).round()])),
            if (incomplete) ...[
              const SizedBox(height: 4),
              Text(t.t('edu.cmp.incomplete'),
                  style: const TextStyle(
                      color: AppTheme.amber, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      );
    }

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconPill(
                  icon: Icons.compare_arrows_rounded,
                  color: AppTheme.emerald,
                  size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Text(t.t('edu.cmp.title'),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          if (module.scenarioHint != null) ...[
            const SizedBox(height: 8),
            Text(module.scenarioHint!.of(t.locale),
                style:
                    TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5)),
          ],
          const SizedBox(height: 10),
          _ScenarioRow(
              module: module, kit: kit, label: 'A', window: a, measure: ma),
          const Divider(height: 18),
          _ScenarioRow(
              module: module, kit: kit, label: 'B', window: b, measure: mb),
          if (result != null) ...[const SizedBox(height: 10), result],
        ],
      ),
    );
  }
}

class _ScenarioRow extends ConsumerWidget {
  const _ScenarioRow({
    required this.module,
    required this.kit,
    required this.label,
    required this.window,
    required this.measure,
  });
  final EduModule module;
  final KitModel kit;
  final String label;
  final ScenarioWindow? window;
  final ({double kwh, int expectedHours, int receivedHours})? measure;

  Future<DateTime?> _pick(BuildContext context, DateTime initial) async {
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 60)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (d == null || !context.mounted) return null;
    final tm = await showTimePicker(
        context: context, initialTime: TimeOfDay(hour: initial.hour, minute: 0));
    if (tm == null) return null;
    return DateTime(d.year, d.month, d.day, tm.hour);
  }

  Future<void> _adjust(BuildContext context, WidgetRef ref) async {
    final t = ref.read(tProvider);
    final edu = ref.read(educationProvider);
    final now = EducationViewModel.roundHour(DateTime.now());
    final w = window;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(t.t('edu.cmp.pickStart')),
        duration: const Duration(seconds: 1)));
    final s = await _pick(context, w?.startAt ?? now.subtract(const Duration(hours: 1)));
    if (s == null || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(t.t('edu.cmp.pickEnd')),
        duration: const Duration(seconds: 1)));
    var e = await _pick(context, w?.endAt ?? s.add(const Duration(hours: 1)));
    if (e == null) return;
    if (!e.isAfter(s)) e = s.add(const Duration(hours: 1));
    await edu.saveScenario(ScenarioWindow(
      tpCode: module.code,
      label: label,
      kitNumber: kit.kitNumber,
      startAt: s,
      endAt: e,
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    final edu = ref.read(educationProvider);
    final scheme = Theme.of(context).colorScheme;
    final w = window;
    final m = measure;
    final color = label == 'A' ? AppTheme.indigo : AppTheme.violet;

    String status;
    if (w == null) {
      status = t.t('edu.cmp.notStarted');
    } else if (w.isRunning) {
      status = t.tf('edu.cmp.running', [_dh(w.startAt)]);
    } else {
      status = t.tf('edu.cmp.window', [_dh(w.startAt), _dh(w.endAt!)]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: color,
              child: Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.tf('edu.cmp.scenario', [label]),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(status,
                      style: TextStyle(
                          color: scheme.onSurfaceVariant, fontSize: 12.5)),
                  if (m != null)
                    Text(
                      m.receivedHours == 0
                          ? t.t('edu.cmp.waiting')
                          : t.tf('edu.cmp.energy', [
                              m.kwh.toStringAsFixed(2),
                              m.receivedHours,
                              m.expectedHours
                            ]),
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            if (w == null || !w.isRunning)
              FilledButton.tonalIcon(
                onPressed: () =>
                    edu.startScenario(module.code, label, kit.kitNumber),
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: Text(t.t('edu.cmp.start')),
              )
            else
              FilledButton.tonalIcon(
                onPressed: () => edu.stopScenario(module.code, label),
                icon: const Icon(Icons.stop_rounded, size: 18),
                label: Text(t.t('edu.cmp.stop')),
              ),
            OutlinedButton(
              onPressed: () => _adjust(context, ref),
              child: Text(t.t('edu.cmp.edit')),
            ),
            if (w != null)
              TextButton(
                onPressed: () => edu.clearScenario(module.code, label),
                child: Text(t.t('edu.cmp.clear')),
              ),
          ],
        ),
      ],
    );
  }
}
