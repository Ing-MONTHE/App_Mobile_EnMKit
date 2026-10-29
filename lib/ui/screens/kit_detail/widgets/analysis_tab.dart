import 'dart:math' as math;

import 'package:enmkit/core/ai/energy_insights.dart';
import 'package:enmkit/core/i18n/strings.dart';
import 'package:enmkit/models/hourly_consumption_model.dart';
import 'package:enmkit/providers.dart';
import 'package:enmkit/ui/screens/assistant/assistant_screen.dart';
import 'package:enmkit/ui/theme/app_theme.dart';
import 'package:enmkit/ui/widgets/common/brand_loader.dart';
import 'package:enmkit/ui/widgets/common/premium.dart';
import 'package:enmkit/ui/widgets/common/soft_card.dart';
import 'package:enmkit/ui/widgets/common/state_views.dart';
import 'package:enmkit/viewmodels/assistant_viewmodel.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

String _two(int n) => n.toString().padLeft(2, '0');
String _dh(DateTime d) => '${_two(d.day)}/${_two(d.month)} ${_two(d.hour)}h';
String _kwh(double v) => v.toStringAsFixed(v >= 100 ? 0 : (v >= 10 ? 1 : 2));
String _fcfa(double v) {
  final s = v.round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return '$b FCFA';
}

Color gradeColor(String grade) => switch (grade) {
      'A' => AppTheme.emerald,
      'B' => const Color(0xFF65B741),
      'C' => AppTheme.amber,
      'D' => const Color(0xFFF97316),
      _ => AppTheme.coral,
    };

/// Onglet « Analyse IA » : analyse HORS-LIGNE des trames horaires du kit
/// (moteur `EnergyInsightsEngine`, contrat §6) — score, prévisions FCFA,
/// courbe 48 h vs profil type, anomalies, qualité des données, conseils.
class AnalysisTab extends ConsumerWidget {
  const AnalysisTab({super.key, required this.kitNumber});
  final String? kitNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(kitHourlyProvider(kitNumber));
    final t = ref.watch(tProvider);

    if (!vm.loadedOnce && vm.isLoading) {
      return BrandLoader(message: t.t('common.loading'));
    }

    if (!vm.hasData) {
      return RefreshIndicator(
        onRefresh: vm.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            EmptyStateView(
              icon: Icons.auto_graph_rounded,
              title: t.t('ai.empty.title'),
              message: t.t('ai.empty.msg'),
            ),
            const _FrameExample(),
            const SizedBox(height: 16),
            _AssistantButton(kitNumber: kitNumber),
          ],
        ),
      );
    }

    final ins = vm.insights(t.locale);
    final latest = vm.latest;
    return RefreshIndicator(
      onRefresh: vm.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          _ScoreHero(insights: ins, latest: latest),
          const SizedBox(height: 14),
          _ForecastRow(insights: ins),
          const SizedBox(height: 14),
          _KeyFigures(insights: ins),
          const SizedBox(height: 22),
          _HourlyChart(
            points: vm.points,
            profile: ins.profile,
            now: vm.now(),
          ),
          const SizedBox(height: 22),
          _SectionTitle(text: t.t('ai.recos')),
          ...ins.recommendations.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RecoCard(reco: r),
              )),
          const SizedBox(height: 10),
          _AnomaliesCard(insights: ins),
          const SizedBox(height: 14),
          _QualityCard(insights: ins),
          const SizedBox(height: 18),
          _AssistantButton(kitNumber: kitNumber),
        ]
            .animate(interval: 40.ms)
            .fadeIn(duration: 300.ms)
            .slideY(begin: 0.04, end: 0, duration: 300.ms),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 12),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );
}

/// Exemple de SMS de trames, pour l'état vide.
class _FrameExample extends StatelessWidget {
  const _FrameExample();
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SoftCard(
      child: Row(
        children: [
          const IconPill(icon: Icons.sms_rounded, color: AppTheme.cyan, size: 42),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              '27/06/26;09;0.00\n27/06/26;10;0.12\n27/06/26;11;0.35',
              style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: scheme.onSurface,
                  height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Carte héro : jauge de score + note
// ---------------------------------------------------------------------------
class _ScoreHero extends ConsumerWidget {
  const _ScoreHero({required this.insights, required this.latest});
  final EnergyInsights insights;
  final HourlyConsumptionModel? latest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    final s = insights.score;
    final white = Colors.white.withValues(alpha: 0.9);
    return GradientHeroCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 112,
                height: 112,
                child: CustomPaint(
                  painter: _GaugePainter(
                    value: s.value / 100,
                    color: gradeColor(s.grade),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedCount(
                          value: s.value,
                          style: GoogleFonts.chakraPetch(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                        Text('/100',
                            style: TextStyle(color: white, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.t('ai.score'),
                        style: TextStyle(color: white, fontSize: 13)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: gradeColor(s.grade),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        t.tf('ai.grade', [s.grade]),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (latest != null)
                      Text(
                        t.tf('ai.lastFrame', [
                          '${_dh(latest!.hourStart)} · ${_kwh(latest!.kwh)} kWh'
                        ]),
                        style: TextStyle(color: white, fontSize: 12),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.offline_bolt_rounded,
                            size: 14, color: white),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(t.t('ai.offline'),
                              style: TextStyle(color: white, fontSize: 11)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            t.tf('ai.penalties', [
              s.standby.round(),
              s.peak.round(),
              s.trend.round(),
              s.anomalies.round(),
            ]),
            style: TextStyle(color: white, fontSize: 11.5),
          ),
          if (insights.dataQuality.receivedHours < 72) ...[
            const SizedBox(height: 8),
            Text(t.t('ai.limited'),
                style: TextStyle(
                    color: white, fontSize: 11.5, fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }
}

/// Jauge circulaire (arc de 240°).
class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.value, required this.color});
  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const start = math.pi * 5 / 6; // 150°
    const sweep = math.pi * 4 / 3; // 240°
    final rect = Offset.zero & size;
    final r = rect.deflate(8);
    final bg = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(r, start, sweep, false, bg);
    canvas.drawArc(r, start, sweep * value.clamp(0.0, 1.0), false, fg);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.value != value || old.color != color;
}

// ---------------------------------------------------------------------------
// Prévisions jour / mois
// ---------------------------------------------------------------------------
class _ForecastRow extends ConsumerWidget {
  const _ForecastRow({required this.insights});
  final EnergyInsights insights;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    final f = insights.forecast;
    // Prix moyen du kWh sur le mois prévu, appliqué à la journée.
    final avgPrice = f.monthKwh > 0 ? f.monthCostFcfa / f.monthKwh : 0.0;
    return Row(
      children: [
        Expanded(
          child: _KpiTile(
            icon: Icons.today_rounded,
            color: AppTheme.indigo,
            label: t.t('ai.today'),
            value: '${_kwh(f.todayKwh)} kWh',
            sub: '≈ ${_fcfa(f.todayKwh * avgPrice)}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiTile(
            icon: Icons.calendar_month_rounded,
            color: AppTheme.violet,
            label: t.t('ai.month'),
            value: '${_kwh(f.monthKwh)} kWh',
            sub: '≈ ${_fcfa(f.monthCostFcfa)}',
          ),
        ),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.sub,
  });
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SoftCard(
      padding: const EdgeInsets.all(14),
      shadowTint: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconPill(icon: icon, color: color, size: 34),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.chakraPetch(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
          ),
          if (sub != null)
            Text(sub!,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w700, fontSize: 12.5)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
        ],
      ),
    );
  }
}

class _KeyFigures extends ConsumerWidget {
  const _KeyFigures({required this.insights});
  final EnergyInsights insights;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    final trend = insights.trendPct;
    final items = <(IconData, Color, String, String)>[
      (
        Icons.data_usage_rounded,
        AppTheme.emerald,
        t.t('ai.avgDaily'),
        '${_kwh(insights.avgDailyKwh)} kWh'
      ),
      (
        Icons.nightlight_round,
        AppTheme.cyan,
        t.t('ai.baseLoad'),
        '${(insights.baseLoadKw * 1000).round()} W · ${(insights.baseLoadShare * 100).round()} %'
      ),
      (
        Icons.wb_twilight_rounded,
        AppTheme.amber,
        t.t('ai.peakHour'),
        insights.peakHour == null
            ? '—'
            : '${_two(insights.peakHour!)}h · ${(insights.peakShare * 100).round()} % 18–23h'
      ),
      (
        trend != null && trend > 0
            ? Icons.trending_up_rounded
            : Icons.trending_down_rounded,
        trend != null && trend > 15 ? AppTheme.coral : AppTheme.indigo,
        t.t('ai.trend'),
        trend == null ? '—' : '${trend > 0 ? '+' : ''}${trend.toStringAsFixed(0)} %'
      ),
    ];
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        children: [
          for (final it in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  IconPill(icon: it.$1, color: it.$2, size: 32),
                  const SizedBox(width: 12),
                  Expanded(child: Text(it.$3)),
                  Text(it.$4,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Courbe 48 h + profil type
// ---------------------------------------------------------------------------
class _HourlyChart extends ConsumerWidget {
  const _HourlyChart({
    required this.points,
    required this.profile,
    required this.now,
  });
  final List<HourlyConsumptionModel> points;
  final EnergyProfile profile;
  final DateTime now;

  static const int span = 48;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    final scheme = Theme.of(context).colorScheme;
    final end = DateTime(now.year, now.month, now.day, now.hour);
    final start = DateTime(end.year, end.month, end.day, end.hour - (span - 1));
    final byHour = {
      for (final p in points)
        if (!p.hourStart.isBefore(start) && !p.hourStart.isAfter(end))
          p.hourStart: p.kwh
    };
    DateTime slot(int i) =>
        DateTime(start.year, start.month, start.day, start.hour + i);

    final actual = <FlSpot>[];
    final typical = <FlSpot>[];
    var maxY = 0.05;
    for (var i = 0; i < span; i++) {
      final h = slot(i);
      final v = byHour[h];
      actual.add(v == null ? FlSpot.nullSpot : FlSpot(i.toDouble(), v));
      final tv = profile.forDate(h)[h.hour].median;
      typical.add(FlSpot(i.toDouble(), tv));
      maxY = math.max(maxY, math.max(v ?? 0, tv));
    }
    maxY *= 1.18;

    Widget legend(Color c, String label, {bool dashed = false}) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 3,
              decoration: BoxDecoration(
                color: dashed ? null : c,
                border: dashed ? Border.all(color: c, width: 1) : null,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 5),
            Text(label,
                style:
                    TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
          ],
        );

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(10, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    t.t('ai.chart.title').toUpperCase(),
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                legend(AppTheme.indigo, t.t('ai.chart.actual')),
                const SizedBox(width: 10),
                legend(AppTheme.amber, t.t('ai.chart.typical'), dashed: true),
              ],
            ),
          ),
          SizedBox(
            height: 190,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (span - 1).toDouble(),
                minY: 0,
                maxY: maxY,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.10),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      interval: maxY / 4,
                      getTitlesWidget: (v, meta) => Text(
                        v.toStringAsFixed(2),
                        style: TextStyle(
                            color: scheme.onSurfaceVariant, fontSize: 9),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (v, meta) {
                        final i = v.round();
                        if (i < 0 || i >= span) return const SizedBox.shrink();
                        final h = slot(i);
                        if (h.hour % 6 != 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            h.hour == 0 ? '${_two(h.day)}/${_two(h.month)}' : '${_two(h.hour)}h',
                            style: TextStyle(
                                color: scheme.onSurfaceVariant, fontSize: 9),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => scheme.inverseSurface,
                    tooltipBorderRadius: BorderRadius.circular(10),
                    getTooltipItems: (spots) => spots.map((s) {
                      final h = slot(s.x.round().clamp(0, span - 1));
                      final isTyp = s.barIndex == 1;
                      return LineTooltipItem(
                        '${isTyp ? '~' : ''}${s.y.toStringAsFixed(2)} kWh'
                        '${isTyp ? '' : '\n${_dh(h)}'}',
                        TextStyle(
                          color: isTyp
                              ? AppTheme.amber
                              : scheme.onInverseSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: actual,
                    isCurved: false,
                    color: AppTheme.indigo,
                    barWidth: 2.6,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.indigo.withValues(alpha: 0.25),
                          AppTheme.indigo.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                  LineChartBarData(
                    spots: typical,
                    isCurved: true,
                    curveSmoothness: 0.25,
                    color: AppTheme.amber,
                    barWidth: 1.8,
                    dashArray: const [5, 4],
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recommandations, anomalies, qualité
// ---------------------------------------------------------------------------
class _RecoCard extends ConsumerWidget {
  const _RecoCard({required this.reco});
  final EnergyRecommendation reco;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    final scheme = Theme.of(context).colorScheme;
    final (color, icon) = switch (reco.severity) {
      RecoSeverity.critical => (AppTheme.coral, Icons.error_rounded),
      RecoSeverity.warning => (AppTheme.amber, Icons.warning_amber_rounded),
      RecoSeverity.info => reco.code == 'GOOD_JOB'
          ? (AppTheme.emerald, Icons.emoji_events_rounded)
          : (AppTheme.indigo, Icons.lightbulb_rounded),
    };
    return SoftCard(
      shadowTint: color,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconPill(icon: icon, color: color, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reco.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14.5)),
                const SizedBox(height: 4),
                Text(reco.body,
                    style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12.8,
                        height: 1.35)),
                if (reco.estimatedSavingKwhMonth != null) ...[
                  const SizedBox(height: 8),
                  StatusBadge(
                    label: t.tf('ai.saving', [
                      reco.estimatedSavingKwhMonth!.toStringAsFixed(1),
                      (reco.estimatedSavingFcfaMonth ?? 0).round(),
                    ]),
                    color: AppTheme.emerald,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnomaliesCard extends ConsumerWidget {
  const _AnomaliesCard({required this.insights});
  final EnergyInsights insights;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    final scheme = Theme.of(context).colorScheme;
    final list = insights.anomalies.take(10).toList();
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconPill(
                  icon: Icons.bolt_rounded, color: AppTheme.coral, size: 32),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(t.t('ai.anomalies'),
                      style: const TextStyle(fontWeight: FontWeight.w700))),
              StatusBadge(
                label: '${insights.anomalies.length}',
                color: insights.anomalies.isEmpty
                    ? AppTheme.emerald
                    : AppTheme.coral,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (list.isEmpty)
            Text(t.t('ai.anomalies.none'),
                style: TextStyle(color: scheme.onSurfaceVariant))
          else
            for (final a in list)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      a.kind == AnomalyKind.spike
                          ? Icons.show_chart_rounded
                          : Icons.nights_stay_rounded,
                      size: 18,
                      color: AppTheme.coral,
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 92,
                      child: Text(_dh(a.hourStart),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 12.5)),
                    ),
                    Expanded(
                      child: Text(
                        t.tf(
                            a.kind == AnomalyKind.spike
                                ? 'ai.anomaly.spike'
                                : 'ai.anomaly.drift',
                            [_kwh(a.kwh), _kwh(a.expectedKwh)]),
                        style: TextStyle(
                            color: scheme.onSurfaceVariant, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _QualityCard extends ConsumerWidget {
  const _QualityCard({required this.insights});
  final EnergyInsights insights;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    final scheme = Theme.of(context).colorScheme;
    final q = insights.dataQuality;
    final pct = (q.completeness * 100).round();
    final color = q.completeness >= 0.8
        ? AppTheme.emerald
        : (q.completeness >= 0.5 ? AppTheme.amber : AppTheme.coral);
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconPill(
                  icon: Icons.fact_check_rounded,
                  color: AppTheme.cyan,
                  size: 32),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(t.t('ai.quality'),
                      style: const TextStyle(fontWeight: FontWeight.w700))),
              Text('$pct %',
                  style: GoogleFonts.chakraPetch(
                      fontWeight: FontWeight.w700, fontSize: 18, color: color)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: q.completeness,
              minHeight: 8,
              color: color,
              backgroundColor: color.withValues(alpha: 0.15),
            ),
          ),
          const SizedBox(height: 8),
          Text(t.tf('ai.quality.received', [q.receivedHours, q.expectedHours]),
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5)),
          Text(
              t.tf('ai.quality.zero', [(q.zeroHoursShare * 100).round()]),
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5)),
          const SizedBox(height: 6),
          if (q.gaps.isEmpty)
            Text(t.t('ai.quality.noGaps'),
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5))
          else
            for (final g in q.gaps.take(5))
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Row(
                  children: [
                    Icon(Icons.remove_circle_outline_rounded,
                        size: 15, color: color),
                    const SizedBox(width: 6),
                    Text(
                      t.tf('ai.quality.gap', [_dh(g.from), _dh(g.to), g.hours]),
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _AssistantButton extends ConsumerWidget {
  const _AssistantButton({required this.kitNumber});
  final String? kitNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings t = ref.watch(tProvider);
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusControl)),
      ),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AssistantScreen(
            kitNumber: kitNumber,
            initialAudience: AssistantAudience.owner,
          ),
        ),
      ),
      icon: const Icon(Icons.forum_rounded),
      label: Text(t.t('ai.assistant')),
    );
  }
}
