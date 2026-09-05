import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/emotion_point.dart';
import '../theme/app_theme.dart';

/// Delivery-confidence graph for a single session: plots each timeline point
/// as emotion valence (0–100) over session time, with per-point dots colored
/// by the dominant emotion. Tap any dot for the exact label + timestamp.
class EmotionGraph extends StatelessWidget {
  final List<EmotionPoint> timeline;

  const EmotionGraph({super.key, required this.timeline});

  String _mmss(double seconds) {
    final total = seconds.round();
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (timeline.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AnubhavColors.cardBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            'No emotion timeline recorded for this session yet.',
            style: AnubhavTextStyles.bodyMedium,
          ),
        ),
      );
    }

    final points = List<EmotionPoint>.of(timeline)
      ..sort((a, b) => a.time.compareTo(b.time));

    final spots = points
        .map((p) => FlSpot(p.time, emotionValence(p.emotion)))
        .toList();
    // fl_chart needs at least 2 spots to draw the line.
    if (spots.length == 1) {
      spots.add(FlSpot(spots.first.x + 1, spots.first.y));
    }

    final endTime = spots.last.x;
    final maxX = endTime <= 0 ? 10.0 : endTime * 1.05 + 1;
    final avgValence = points
            .map((p) => emotionValence(p.emotion))
            .reduce((a, b) => a + b) /
        points.length;

    // Emotions actually present, in order of first appearance.
    final seen = <String>{};
    final present = <String>[];
    for (final p in points) {
      final key = p.emotion.toLowerCase();
      if (seen.add(key)) present.add(key);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AnubhavColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x147A1F1F),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivery Confidence',
                    style: AnubhavTextStyles.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Emotion valence across the session',
                    style: AnubhavTextStyles.bodySmall,
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AnubhavColors.tealSurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Avg ${avgValence.round()}',
                  style: AnubhavTextStyles.labelMedium.copyWith(
                    color: AnubhavColors.teal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: maxX,
                minY: 0,
                maxY: 100,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AnubhavColors.teal.withValues(alpha: 0.12),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 50,
                      reservedSize: 28,
                      getTitlesWidget: (v, _) => Text(
                        '${v.toInt()}',
                        style: AnubhavTextStyles.bodySmall.copyWith(fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: maxX / 4,
                      getTitlesWidget: (v, _) => Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _mmss(v),
                          style: AnubhavTextStyles.bodySmall.copyWith(fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AnubhavColors.headingDeep,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((t) {
                        final idx = t.spotIndex.clamp(0, points.length - 1);
                        final p = points[idx];
                        final meta = getEmotionMeta(p.emotion);
                        return LineTooltipItem(
                          '${meta.label} · ${_mmss(p.time)}\n',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                          children: [
                            TextSpan(
                              text: 'Intensity ${(p.intensity * 100).round()}%',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontWeight: FontWeight.w400,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.25,
                    color: AnubhavColors.teal,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, index) {
                        final idx = index.clamp(0, points.length - 1);
                        final dotColor =
                            getEmotionMeta(points[idx].emotion).color;
                        return FlDotCirclePainter(
                          radius: 4,
                          color: dotColor,
                          strokeColor: AnubhavColors.cardBg,
                          strokeWidth: 2,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AnubhavColors.teal.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: present.map((key) {
              final meta = getEmotionMeta(key);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: meta.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    meta.label,
                    style: AnubhavTextStyles.bodySmall.copyWith(
                      color: meta.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
