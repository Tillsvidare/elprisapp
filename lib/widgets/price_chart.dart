import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/price_data.dart';

class PriceChart extends StatelessWidget {
  final List<PricePoint> prices;

  const PriceChart({
    super.key,
    required this.prices,
  });

  @override
  Widget build(BuildContext context) {
    if (prices.isEmpty) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: Text('Ingen prisdata att visa'),
        ),
      );
    }

    final spots = prices.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.sekPerKwh);
    }).toList();

    final minPrice = prices.map((p) => p.sekPerKwh).reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.map((p) => p.sekPerKwh).reduce((a, b) => a > b ? a : b);
    final currentIndex = prices.indexWhere((p) => p.isCurrent());

    // Check if data spans multiple days
    final firstDay = prices.first.timeStart.day;
    final lastDay = prices.last.timeStart.day;
    final spansTwoDays = firstDay != lastDay;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              spansTwoDays ? 'Elpris kommande 24h' : 'Elpris idag',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatChip(
                  context,
                  'Min',
                  '${minPrice.toStringAsFixed(2)} kr',
                  Colors.green,
                ),
                _buildStatChip(
                  context,
                  'Max',
                  '${maxPrice.toStringAsFixed(2)} kr',
                  Colors.red,
                ),
                _buildStatChip(
                  context,
                  'Snitt',
                  '${(prices.fold(0.0, (sum, p) => sum + p.sekPerKwh) / prices.length).toStringAsFixed(2)} kr',
                  Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: (maxPrice - minPrice) / 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withValues(alpha: 0.2),
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withValues(alpha: 0.1),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 35,
                        interval: 16, // Show every 4 hours (16 * 15min = 4h)
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= prices.length) {
                            return const SizedBox();
                          }
                          final index = value.toInt();
                          if (index % 16 == 0) {
                            final pricePoint = prices[index];
                            final hour = pricePoint.timeStart.hour;
                            final day = pricePoint.timeStart.day;

                            // Show date marker if it's a new day
                            final isNewDay = index > 0 && prices[index - 1].timeStart.day != day;

                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    hour.toString().padLeft(2, '0'),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (isNewDay || (index == 0 && spansTwoDays))
                                    Text(
                                      '${day}/${pricePoint.timeStart.month}',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        interval: (maxPrice - minPrice) / 4,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(2),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.3),
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
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          // Highlight current price point
                          if (index == currentIndex) {
                            return FlDotCirclePainter(
                              radius: 6,
                              color: Colors.orange,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          }
                          return FlDotCirclePainter(
                            radius: 2,
                            color: Theme.of(context).colorScheme.primary,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                            Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                          ],
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final index = spot.x.toInt();
                          if (index >= prices.length) return null;
                          final pricePoint = prices[index];
                          return LineTooltipItem(
                            '${pricePoint.getTimeRange()}\n${pricePoint.sekPerKwh.toStringAsFixed(2)} kr/kWh',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(BuildContext context, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
