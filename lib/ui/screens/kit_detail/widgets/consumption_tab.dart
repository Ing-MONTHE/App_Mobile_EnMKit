import 'package:enmkit/models/consumption_model.dart';
import 'package:enmkit/providers.dart';
import 'package:enmkit/viewmodels/sms_viewmodel.dart';
import 'package:enmkit/ui/theme/app_theme.dart';
import 'package:enmkit/ui/widgets/common/premium.dart';
import 'package:enmkit/ui/widgets/common/soft_card.dart';
import 'package:enmkit/ui/widgets/common/state_views.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

/// Onglet Consommation : carte héro avec mesure + bouton actualiser intégré,
/// puis historique (scopé sur [kitNumber]).
class ConsumptionTab extends ConsumerWidget {
  const ConsumptionTab({super.key, required this.kitNumber});
  final String? kitNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(kitConsumptionProvider(kitNumber));
    final listener = ref.watch(kitSmsListenerProvider(kitNumber));
    final t = ref.watch(tProvider);

    final history = [...vm.consumptions]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final last = history.isNotEmpty ? history.first : null;

    return RefreshIndicator(
      onRefresh: () => vm.fetchConsumptions(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          _CurrentCard(
            last: last,
            status: listener.consumptionStatus,
            onRefresh: () => _refresh(context, ref),
          ),
          if (history.length >= 2) ...[
            const SizedBox(height: 26),
            _TrendChart(history: history, title: t.t('cons.trend')),
          ],
          const SizedBox(height: 26),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              t.t('cons.history'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (history.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: EmptyStateView(
                icon: Icons.insights_rounded,
                title: t.t('cons.empty.title'),
                message: t.t('cons.empty.msg'),
              ),
            )
          else
            ...history.take(20).map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _HistoryRow(item: c),
                )),
        ],
      ),
    );
  }

  void _refresh(BuildContext context, WidgetRef ref) {
    final listener = ref.read(kitSmsListenerProvider(kitNumber));
    final sms = ref.read(kitSmsServiceProvider(kitNumber));
    final t = ref.read(tProvider);
    // La donnée reste acceptée 5 min ; l'UI bascule en « timeout » après 60 s.
    listener.armConsumptionWindow(
      window: const Duration(minutes: 5),
      uiTimeout: const Duration(seconds: 60),
    );
    sms.requestConsumption();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.t('cons.requestSent'))),
    );
  }
}

/// Carte héro de la consommation : mesure courante + bouton actualiser intégré.
class _CurrentCard extends ConsumerWidget {
  const _CurrentCard({
    required this.last,
    required this.status,
    required this.onRefresh,
  });
  final ConsumptionModel? last;
  final ConsumptionStatus status;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    return GradientHeroCard(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child:
                    const Icon(Icons.bolt_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (last != null)
                      AnimatedCount(
                        value: last!.kwh,
                        suffix: ' kWh',
                        fractionDigits: last!.kwh % 1 == 0 ? 0 : 1,
                        style: GoogleFonts.chakraPetch(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.8,
                          height: 1,
                        ),
                      )
                    else
                      Text('—',
                          style: GoogleFonts.chakraPetch(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(
                      last != null
                          ? t.t('cons.lastMeasure')
                          : t.t('cons.noMeasure'),
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Bouton "Actualiser" intégré DANS la carte (sur fond translucide).
          // En attente, il se transforme en indicateur de chargement et se désactive.
          Material(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: status == ConsumptionStatus.waiting ? null : onRefresh,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: status == ConsumptionStatus.waiting
                      ? [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            t.t('cons.waiting'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                            ),
                          ),
                        ]
                      : [
                          const Icon(Icons.refresh_rounded,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            t.t('cons.refresh'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                            ),
                          ),
                        ],
                ),
              ),
            ),
          ),
          // Bannière de statut : timeout (aucune réponse) ou mesure reçue.
          if (status == ConsumptionStatus.timeout) ...[
            const SizedBox(height: 12),
            _StatusBanner(
                icon: Icons.schedule_rounded, text: t.t('cons.timeout')),
          ] else if (status == ConsumptionStatus.received) ...[
            const SizedBox(height: 12),
            _StatusBanner(
                icon: Icons.check_circle_rounded, text: t.t('cons.received')),
          ],
        ],
      ),
    );
  }
}

/// Petite bannière de statut affichée dans la carte héro (texte blanc sur fond
/// translucide), pour le retour visuel « aucune réponse » ou « mesure reçue ».
class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.item});
  final ConsumptionModel item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final d = item.timestamp;
    final date =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const IconPill(
              icon: Icons.flash_on_rounded, color: AppTheme.emerald, size: 42),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${item.kwh} kWh',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15.5)),
                const SizedBox(height: 2),
                Text(date,
                    style: TextStyle(
                        color: scheme.onSurfaceVariant, fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Graphe d'évolution de la consommation — version « premium ».
///
/// • Ligne courbe en dégradé tri-tons (indigo → violet → cyan).
/// • Aire dégradée en couches sous la courbe.
/// • Ligne de moyenne en pointillés (annotée).
/// • Dernier point mis en valeur (pastille pleine).
/// • Infobulle tactile : valeur + date du point touché.
/// • En-tête intégré : dernière mesure + badge de variation (▲/▼ %).
///
/// [history] est trié du plus récent au plus ancien ; on le réordonne
/// chronologiquement et on garde les 12 derniers points pour rester lisible.
class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.history, required this.title});
  final List<ConsumptionModel> history;
  final String title;

  static String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final points = history.reversed.toList();
    final shown =
        points.length > 12 ? points.sublist(points.length - 12) : points;

    final spots = <FlSpot>[
      for (var i = 0; i < shown.length; i++) FlSpot(i.toDouble(), shown[i].kwh),
    ];
    final values = shown.map((c) => c.kwh).toList();
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final avg = values.reduce((a, b) => a + b) / values.length;
    final pad = ((maxY - minY).abs() < 0.001) ? 1.0 : (maxY - minY) * 0.22;
    final loY = (minY - pad).clamp(0, double.infinity).toDouble();
    final hiY = maxY + pad;
    final step = (hiY - loY) / 3;
    final midIdx = (shown.length - 1) ~/ 2;

    // Variation entre les deux dernières mesures.
    final last = shown.last.kwh;
    final prev = shown.length >= 2 ? shown[shown.length - 2].kwh : last;
    final diff = last - prev;
    final pct = prev.abs() < 0.001 ? 0.0 : (diff / prev) * 100;
    final up = diff >= 0;
    // Hausse de conso = ambre/corail, baisse = émeraude (économie).
    final deltaColor = up ? AppTheme.coral : AppTheme.emerald;

    const lineGrad = LinearGradient(
      colors: [AppTheme.indigo, AppTheme.violet, AppTheme.cyan],
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 16, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.surface,
            Color.alphaBlend(
                AppTheme.indigo.withValues(alpha: 0.05), scheme.surface),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.indigo.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- En-tête : titre + dernière valeur + variation ----
          Padding(
            padding: const EdgeInsets.only(left: 6, right: 2, bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.toUpperCase(),
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            last % 1 == 0
                                ? last.toStringAsFixed(0)
                                : last.toStringAsFixed(1),
                            style: GoogleFonts.chakraPetch(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.6,
                              color: scheme.onSurface,
                              height: 1,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              'kWh',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (shown.length >= 2)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: deltaColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          up
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          size: 14,
                          color: deltaColor,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${up ? '+' : ''}${pct.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: deltaColor,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // ---- Le graphe ----
          SizedBox(
            height: 196,
            child: LineChart(
              LineChartData(
                minY: loY,
                maxY: hiY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: step <= 0 ? 1 : step,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.10),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                // Ligne de moyenne en pointillés, annotée « moy. X ».
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: avg,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.45),
                      strokeWidth: 1,
                      dashArray: [6, 5],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(right: 2, bottom: 2),
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                        labelResolver: (_) => 'moy. ${avg.toStringAsFixed(1)}',
                      ),
                    ),
                  ],
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  // Dates aux extrémités + milieu seulement (lisibilité).
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final i = value.round();
                        if (i != 0 && i != midIdx && i != shown.length - 1) {
                          return const SizedBox.shrink();
                        }
                        if (i < 0 || i >= shown.length) {
                          return const SizedBox.shrink();
                        }
                        final d = shown[i].timestamp;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${_two(d.day)}/${_two(d.month)}',
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontSize: 9.5,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      interval: step <= 0 ? 1 : step,
                      getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(0),
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),
                // Infobulle tactile : valeur + date du point touché.
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  getTouchedSpotIndicator: (bar, indexes) => indexes
                      .map(
                        (i) => TouchedSpotIndicatorData(
                          FlLine(
                            color: AppTheme.indigo.withValues(alpha: 0.35),
                            strokeWidth: 1.5,
                            dashArray: const [4, 3],
                          ),
                          FlDotData(
                            getDotPainter: (s, p, b, idx) => FlDotCirclePainter(
                              radius: 5,
                              color: scheme.surface,
                              strokeWidth: 3,
                              strokeColor: AppTheme.violet,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => scheme.inverseSurface,
                    tooltipBorderRadius: BorderRadius.circular(12),
                    tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    getTooltipItems: (spots) => spots.map((s) {
                      final i = s.x.round().clamp(0, shown.length - 1);
                      final c = shown[i];
                      final d = c.timestamp;
                      return LineTooltipItem(
                        '${c.kwh} kWh\n',
                        TextStyle(
                          color: scheme.onInverseSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                        children: [
                          TextSpan(
                            text:
                                '${_two(d.day)}/${_two(d.month)} ${_two(d.hour)}:${_two(d.minute)}',
                            style: TextStyle(
                              color: scheme.onInverseSurface
                                  .withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.36,
                    gradient: lineGrad,
                    barWidth: 3.4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) {
                        final isLast = index == spots.length - 1;
                        return FlDotCirclePainter(
                          radius: isLast ? 5 : 2.6,
                          color: isLast ? AppTheme.violet : scheme.surface,
                          strokeWidth: isLast ? 3 : 2,
                          strokeColor:
                              isLast ? scheme.surface : AppTheme.indigo,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.indigo.withValues(alpha: 0.28),
                          AppTheme.violet.withValues(alpha: 0.10),
                          AppTheme.indigo.withValues(alpha: 0.0),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(
          begin: 0.06,
          end: 0,
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
