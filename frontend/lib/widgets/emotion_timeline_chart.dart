import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/emotion_point.dart';
import '../theme/app_theme.dart';

/// Area/line chart of emotion over session time.
///
/// Y-axis = intensity (0.0–1.0). Each data point's dot is colored by
/// its emotion category using the shared [emotionColors] map.
class EmotionTimelineChart extends StatelessWidget {
  final List<EmotionPoint> points;

  const EmotionTimelineChart({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const _EmptyChart();
    }

    final spots =
        points.map((p) => FlSpot(p.time, p.intensity)).toList();

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          backgroundColor: Colors.transparent,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 0.25,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: AnubhavColors.chartGrid,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 0.5,
                reservedSize: 36,
                getTitlesWidget: (v, _) => Text(
                  '${(v * 100).toInt()}%',
                  style: AnubhavTextStyles.bodySmall,
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 30,
                getTitlesWidget: (v, _) {
                  final mins = (v / 60).floor();
                  final secs = (v % 60).toInt();
                  return Text(
                    mins > 0 ? '${mins}m${secs}s' : '${secs}s',
                    style: AnubhavTextStyles.bodySmall,
                  );
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          minX: 0,
          maxX: points.last.time,
          minY: 0,
          maxY: 1,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: AnubhavColors.accent.withOpacity(0.8),
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, index) {
                  final color = emotionColor(points[index].emotion);
                  return FlDotCirclePainter(
                    radius: 5,
                    color: color,
                    strokeWidth: 2,
                    strokeColor: AnubhavColors.surface,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AnubhavColors.accent.withOpacity(0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AnubhavColors.surfaceVariant,
              getTooltipItems: (spots) => spots.map((s) {
                final p = points[s.spotIndex];
                return LineTooltipItem(
                  '${p.emotion[0].toUpperCase()}${p.emotion.substring(1)}\n',
                  TextStyle(
                    color: emotionColor(p.emotion),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  children: [
                    TextSpan(
                      text: '${(p.intensity * 100).toInt()}% intensity',
                      style: AnubhavTextStyles.bodySmall,
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Text('No timeline data', style: AnubhavTextStyles.bodyMedium),
    );
  }
}
