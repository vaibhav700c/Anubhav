import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/digital_twin.dart';
import '../theme/app_theme.dart';

/// Digital Twin Line Chart showing historical trend + dashed projection to next session
class TwinTrendChart extends StatefulWidget {
  final DigitalTwin twin;

  const TwinTrendChart({super.key, required this.twin});

  @override
  State<TwinTrendChart> createState() => _TwinTrendChartState();
}

class _TwinTrendChartState extends State<TwinTrendChart> {
  int _activeMetricIndex = 0; // 0: Fluency, 1: Filler Rate, 2: Confidence

  @override
  Widget build(BuildContext context) {
    final history = widget.twin.historySummary;
    final projection = widget.twin.nextSessionProjection;

    // Transform points for chart
    final List<FlSpot> historicalSpots = history.map((item) {
      return FlSpot(item.sessionIndex.toDouble(), item.score.toDouble());
    }).toList();

    // If no history, add placeholder
    if (historicalSpots.isEmpty) {
      historicalSpots.addAll([
        const FlSpot(1, 68),
        const FlSpot(2, 74),
        const FlSpot(3, 79),
      ]);
    }

    final lastSessionIndex = historicalSpots.last.x;
    final lastScore = historicalSpots.last.y;
    final projectedSpot = FlSpot(lastSessionIndex + 1, projection.toDouble());

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AnubhavColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x081F5B5B),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metric selection tabs: Fluency | Filler Rate | Confidence Trend
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AnubhavColors.bgWarmPeach,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _buildMetricTab(0, 'Fluency'),
                _buildMetricTab(1, 'Filler Rate'),
                _buildMetricTab(2, 'Confidence'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Header with next session projection tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Score Trajectory',
                    style: AnubhavTextStyles.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Consistent growth across sessions',
                    style: AnubhavTextStyles.bodySmall,
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AnubhavColors.tealSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AnubhavColors.teal.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AnubhavColors.teal,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Next: ${projection.round()} pts',
                      style: AnubhavTextStyles.labelMedium.copyWith(
                        color: AnubhavColors.teal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Chart canvas
          SizedBox(
            height: 190,
            child: LineChart(
              LineChartData(
                minX: 1,
                maxX: lastSessionIndex + 1.2,
                minY: 50,
                maxY: 100,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 15,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: AnubhavColors.divider,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 15,
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
                      interval: 1,
                      getTitlesWidget: (val, _) {
                        if (val == lastSessionIndex + 1) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              'Next',
                              style: AnubhavTextStyles.bodySmall.copyWith(
                                color: AnubhavColors.teal,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'S${val.toInt()}',
                            style: AnubhavTextStyles.bodySmall,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // 1. Solid history line
                  LineChartBarData(
                    spots: historicalSpots,
                    isCurved: true,
                    curveSmoothness: 0.25,
                    color: AnubhavColors.teal,
                    barWidth: 3.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                        radius: 5,
                        color: Colors.white,
                        strokeColor: AnubhavColors.teal,
                        strokeWidth: 2.5,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AnubhavColors.teal.withValues(alpha: 0.08),
                    ),
                  ),
                  // 2. Dashed projected extension
                  LineChartBarData(
                    spots: [
                      FlSpot(lastSessionIndex, lastScore),
                      projectedSpot,
                    ],
                    isCurved: false,
                    color: AnubhavColors.orange,
                    barWidth: 2.5,
                    dashArray: [6, 4],
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                        radius: 6,
                        color: AnubhavColors.orange,
                        strokeColor: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Legend at bottom
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendBullet(AnubhavColors.teal, 'Recorded Sessions', isDashed: false),
              const SizedBox(width: 20),
              _buildLegendBullet(AnubhavColors.orange, 'Digital Twin Projection', isDashed: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTab(int index, String title) {
    final isSelected = _activeMetricIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeMetricIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: AnubhavTextStyles.labelMedium.copyWith(
              color: isSelected ? AnubhavColors.teal : AnubhavColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendBullet(Color color, String label, {required bool isDashed}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AnubhavTextStyles.bodySmall.copyWith(fontSize: 11),
        ),
      ],
    );
  }
}
