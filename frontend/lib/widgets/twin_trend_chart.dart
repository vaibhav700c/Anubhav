import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/digital_twin.dart';
import '../theme/app_theme.dart';

/// Line chart showing score trend across sessions, with a dashed ghost point
/// for [DigitalTwin.nextSessionProjection].
class TwinTrendChart extends StatelessWidget {
  final DigitalTwin twin;

  const TwinTrendChart({super.key, required this.twin});

  @override
  Widget build(BuildContext context) {
    final history = twin.historySummary;
    if (history.isEmpty) {
      return const SizedBox(
          height: 180,
          child: Center(child: Text('No history data yet.')));
    }

    final spots = history
        .map((p) => FlSpot(p.sessionIndex.toDouble(), p.score))
        .toList();

    // Ghost projection point — one index past last real
    final projIndex = history.last.sessionIndex.toDouble() + 1;
    final projSpot = FlSpot(projIndex, twin.nextSessionProjection);

    return SizedBox(
      height: 220,
      child: Stack(
        children: [
          LineChart(
            LineChartData(
              backgroundColor: Colors.transparent,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 20,
                getDrawingHorizontalLine: (_) => const FlLine(
                    color: AnubhavColors.chartGrid, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              minX: history.first.sessionIndex.toDouble() - 0.2,
              maxX: projIndex + 0.2,
              minY: 0,
              maxY: 100,
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    interval: 20,
                    getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                        style: AnubhavTextStyles.bodySmall),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (v, _) {
                      final isProj = v == projIndex;
                      return Text(
                        isProj ? 'Next' : 'S${v.toInt()}',
                        style: AnubhavTextStyles.bodySmall.copyWith(
                          color: isProj
                              ? AnubhavColors.accentLight
                              : AnubhavColors.textTertiary,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              lineBarsData: [
                // Real history — solid
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: AnubhavColors.accent,
                  barWidth: 3,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                      radius: 5,
                      color: AnubhavColors.accent,
                      strokeWidth: 2,
                      strokeColor: AnubhavColors.surface,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AnubhavColors.accent.withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                // Projection — dashed
                LineChartBarData(
                  spots: [spots.last, projSpot],
                  isCurved: false,
                  color: AnubhavColors.accentLight.withOpacity(0.6),
                  barWidth: 2,
                  dashArray: [6, 5],
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (_, __, ___, index) {
                      if (index == 0) {
                        return FlDotCirclePainter(
                            radius: 0,
                            color: Colors.transparent,
                            strokeWidth: 0,
                            strokeColor: Colors.transparent);
                      }
                      return FlDotCirclePainter(
                        radius: 7,
                        color: AnubhavColors.accentDim,
                        strokeWidth: 2,
                        strokeColor: AnubhavColors.accentLight,
                      );
                    },
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => AnubhavColors.surfaceVariant,
                  getTooltipItems: (spots) => spots.map((s) {
                    final isProj = s.x == projIndex;
                    return LineTooltipItem(
                      isProj ? '📍 Projection\n' : 'Session ${s.x.toInt()}\n',
                      TextStyle(
                        color: isProj
                            ? AnubhavColors.accentLight
                            : AnubhavColors.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      children: [
                        TextSpan(
                          text: s.y.toStringAsFixed(0),
                          style: AnubhavTextStyles.bodySmall
                              .copyWith(color: AnubhavColors.textPrimary),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          // Projection label overlay
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AnubhavColors.accentDim,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AnubhavColors.accentLight.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_graph,
                      size: 12, color: AnubhavColors.accentLight),
                  const SizedBox(width: 4),
                  Text(
                    'Projection: ${twin.nextSessionProjection.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AnubhavColors.accentLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
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
