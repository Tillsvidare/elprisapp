import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/price_data.dart';

/// Compact price chart designed for widgets and small spaces
class CompactPriceChart extends StatelessWidget {
  final List<PricePoint> prices;
  final double height;
  final bool showLabels;

  const CompactPriceChart({
    super.key,
    required this.prices,
    this.height = 120,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    if (prices.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text('Ingen data'),
        ),
      );
    }

    final spots = prices.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.sekPerKwh);
    }).toList();

    final minPrice = prices.map((p) => p.sekPerKwh).reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.map((p) => p.sekPerKwh).reduce((a, b) => a > b ? a : b);
    final currentIndex = prices.indexWhere((p) => p.isCurrent());

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxPrice - minPrice) / 3,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.white.withValues(alpha: 0.1),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: showLabels,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: showLabels,
                reservedSize: 20,
                interval: prices.length > 48 ? 32 : 16, // Adjust based on data points
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= prices.length) {
                    return const SizedBox();
                  }
                  final index = value.toInt();
                  final hour = prices[index].timeStart.hour;

                  // Only show labels at key hours
                  if (hour % 6 == 0) {
                    return Text(
                      hour.toString().padLeft(2, '0'),
                      style: const TextStyle(
                        fontSize: 8,
                        color: Colors.white70,
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: showLabels,
                reservedSize: 28,
                interval: (maxPrice - minPrice) / 2,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 8,
                      color: Colors.white70,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          minX: 0,
          maxX: (prices.length - 1).toDouble(),
          minY: minPrice - (maxPrice - minPrice) * 0.1,
          maxY: maxPrice + (maxPrice - minPrice) * 0.1,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.lightBlueAccent,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  // Highlight current price point
                  if (index == currentIndex) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: Colors.orange,
                      strokeWidth: 1.5,
                      strokeColor: Colors.white,
                    );
                  }
                  return FlDotCirclePainter(
                    radius: 1,
                    color: Colors.lightBlueAccent,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.lightBlueAccent.withValues(alpha: 0.4),
                    Colors.lightBlueAccent.withValues(alpha: 0.05),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: const LineTouchData(
            enabled: false, // Disable touch for compact view
          ),
        ),
      ),
    );
  }
}
