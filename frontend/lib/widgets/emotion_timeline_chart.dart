import 'package:flutter/material.dart';
import '../models/emotion_point.dart';
import '../theme/app_theme.dart';

/// Interactive scrubbable emotion timeline ribbon with active tooltip and emoji row
class EmotionTimelineChart extends StatefulWidget {
  final List<EmotionPoint> timeline;

  const EmotionTimelineChart({super.key, required this.timeline});

  @override
  State<EmotionTimelineChart> createState() => _EmotionTimelineChartState();
}

class _EmotionTimelineChartState extends State<EmotionTimelineChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.timeline.isEmpty) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AnubhavColors.cardBorder),
        ),
        child: Text(
          'No emotion timeline recorded.',
          style: AnubhavTextStyles.bodyMedium,
        ),
      );
    }

    final points = widget.timeline;
    final selectedPoint = _selectedIndex != null && _selectedIndex! < points.length
        ? points[_selectedIndex!]
        : null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AnubhavColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x081F5B5B),
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
              Text(
                'Live Delivery Valence',
                style: AnubhavTextStyles.titleMedium,
              ),
              if (selectedPoint != null) ...[
                Builder(builder: (_) {
                  final meta = getEmotionMeta(selectedPoint.emotion);
                  final minutes = (selectedPoint.time ~/ 60).toString().padLeft(2, '0');
                  final seconds = (selectedPoint.time % 60).toInt().toString().padLeft(2, '0');
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: meta.softBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${meta.emoji} ${meta.label} ($minutes:$seconds)',
                      style: AnubhavTextStyles.labelMedium.copyWith(
                        color: meta.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }),
              ] else ...[
                Text(
                  'Tap segment to inspect',
                  style: AnubhavTextStyles.bodySmall,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Horizontal segmented scrubbable ribbon
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 48,
              child: Row(
                children: points.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final pt = entry.value;
                  final meta = getEmotionMeta(pt.emotion);
                  final isSelected = _selectedIndex == idx;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIndex = idx;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: isSelected ? meta.color : meta.color.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(6),
                          border: isSelected
                              ? Border.all(color: AnubhavColors.textPrimary, width: 2)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            meta.emoji,
                            style: TextStyle(
                              fontSize: isSelected ? 18 : 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Emoji reference key row mapped to the 6 fixed labels
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildLegendItem('Confident', '🙂', const Color(0xFF10B981)),
                _buildLegendItem('Nervous', '😰', const Color(0xFFF59E0B)),
                _buildLegendItem('Bored', '😴', const Color(0xFF64748B)),
                _buildLegendItem('Excited', '🤩', const Color(0xFFEA580C)),
                _buildLegendItem('Monotone', '😐', const Color(0xFF8B5CF6)),
                _buildLegendItem('Calm', '😌', const Color(0xFF0284C7)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, String emoji, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(
            label,
            style: AnubhavTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
