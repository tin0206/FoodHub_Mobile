import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// One point on a [TrendLineChart] or [ColumnBarChart]: an x-axis [label],
/// a plotted [value], and optional pre-formatted [tooltip] text shown on
/// touch (falls back to the raw value when omitted).
class ChartPoint {
  const ChartPoint({required this.label, required this.value, this.tooltip});

  final String label;
  final double value;
  final String? tooltip;
}

/// Smooth line chart with a real touch tooltip (fixes hovering over the old
/// CustomPainter trend line giving no feedback). Used for Daily Active Users
/// and the Response Time trend.
class TrendLineChart extends StatelessWidget {
  const TrendLineChart({
    super.key,
    required this.points,
    required this.color,
    required this.textSub,
    this.height = 120,
  });

  final List<ChartPoint> points;
  final Color color;
  final Color textSub;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return SizedBox(height: height);
    }
    final maxVal = points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final safeMax = maxVal <= 0 ? 1.0 : maxVal;
    final midIdx = (points.length - 1) ~/ 2;

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: safeMax * 1.2,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 18,
                getTitlesWidget: (value, meta) {
                  final i = value.round();
                  if (i < 0 || i >= points.length)
                    return const SizedBox.shrink();
                  final show = i == 0 || i == points.length - 1 || i == midIdx;
                  if (!show) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      points[i].label,
                      style: TextStyle(fontSize: 9, color: textSub),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => color.withValues(alpha: 0.95),
              tooltipBorderRadius: BorderRadius.circular(8),
              getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                final i = spot.x.toInt();
                final text = (i >= 0 && i < points.length)
                    ? (points[i].tooltip ?? points[i].value.toStringAsFixed(0))
                    : '';
                return LineTooltipItem(
                  text,
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < points.length; i++)
                  FlSpot(i.toDouble(), points[i].value),
              ],
              isCurved: true,
              curveSmoothness: 0.25,
              color: color,
              barWidth: 2.2,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                      radius: index == points.length - 1 ? 3.2 : 2.0,
                      color: color,
                      strokeWidth: 0,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vertical bar chart with a real touch tooltip and a solid-filled bar color
/// (fixes the old alpha-20% bars that looked faded against the gray track).
/// Used for New Signups (and reusable for any per-day/per-week count).
class ColumnBarChart extends StatelessWidget {
  const ColumnBarChart({
    super.key,
    required this.points,
    required this.color,
    required this.textSub,
    this.height = 120,
  });

  final List<ChartPoint> points;
  final Color color;
  final Color textSub;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return SizedBox(height: height);
    }
    final maxVal = points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final safeMax = maxVal <= 0 ? 1.0 : maxVal;

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: safeMax * 1.25,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 18,
                getTitlesWidget: (value, meta) {
                  final i = value.round();
                  if (i < 0 || i >= points.length)
                    return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      points[i].label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        color: textSub,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => color.withValues(alpha: 0.95),
              tooltipBorderRadius: BorderRadius.circular(8),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final p = points[group.x.toInt()];
                return BarTooltipItem(
                  p.tooltip ?? p.value.toStringAsFixed(0),
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                );
              },
            ),
          ),
          barGroups: [
            for (var i = 0; i < points.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: points[i].value,
                    color: color,
                    width: 14,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal ranked list (label + solid bar + count) for "Popular Labels"
/// and "Dietary Distribution". fl_chart's BarChart doesn't have a clean
/// horizontal-orientation mode, and a label-left/bar-right row reads better
/// on a narrow phone screen than a rotated chart would, so this stays a
/// plain row layout — but now with a solid bar fill (was alpha 25%, which
/// read as washed-out light blue) and a native [Tooltip] so long-press/hover
/// surfaces the exact count, matching the "real tooltip" fix applied to the
/// other two charts.
class RankedBarChart extends StatelessWidget {
  const RankedBarChart({
    super.key,
    required this.items,
    required this.color,
    required this.textSub,
    required this.subtle,
  });

  final List<({String label, int count})> items;
  final Color color;
  final Color textSub;
  final Color subtle;

  @override
  Widget build(BuildContext context) {
    final maxCount = items.isEmpty
        ? 1
        : items.map((e) => e.count).reduce((a, b) => a > b ? a : b);
    return Column(
      children: items.map((item) {
        final frac = maxCount == 0 ? 0.0 : item.count / maxCount;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: textSub,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: Tooltip(
                  message: '${item.count}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Stack(
                      children: [
                        Container(height: 18, color: subtle),
                        FractionallySizedBox(
                          widthFactor: frac.clamp(
                            item.count > 0 ? 0.03 : 0.0,
                            1.0,
                          ),
                          child: Container(height: 18, color: color),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 30,
                child: Text(
                  '${item.count}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
