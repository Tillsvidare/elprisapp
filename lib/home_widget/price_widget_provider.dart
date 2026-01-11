import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import '../models/price_data.dart';

class PriceWidgetProvider {
  Future<void> updateWidget(List<PricePoint> prices, String region) async {
    if (prices.isEmpty) return;

    try {
      // Current price (first in list)
      final currentPrice = prices.first;

      // Store current price data
      await HomeWidget.saveWidgetData('current_price', currentPrice.sekPerKwh.toStringAsFixed(2));
      await HomeWidget.saveWidgetData('current_time', currentPrice.getTimeRange());
      await HomeWidget.saveWidgetData('region', region);

      // Store upcoming prices (next 6)
      final upcomingPrices = prices.skip(1).take(6).toList();

      // Create JSON array of upcoming prices
      final upcomingData = upcomingPrices.map((price) {
        return {
          'time': '${price.timeStart.hour.toString().padLeft(2, '0')}:${price.timeStart.minute.toString().padLeft(2, '0')}',
          'price': price.sekPerKwh.toStringAsFixed(2),
        };
      }).toList();

      await HomeWidget.saveWidgetData('upcoming_prices', jsonEncode(upcomingData));
      await HomeWidget.saveWidgetData('upcoming_count', upcomingPrices.length.toString());

      // Store individual upcoming prices for easier access in Android
      for (int i = 0; i < upcomingPrices.length && i < 6; i++) {
        final price = upcomingPrices[i];
        await HomeWidget.saveWidgetData(
          'upcoming_time_$i',
          '${price.timeStart.hour.toString().padLeft(2, '0')}:${price.timeStart.minute.toString().padLeft(2, '0')}',
        );
        await HomeWidget.saveWidgetData(
          'upcoming_price_$i',
          price.sekPerKwh.toStringAsFixed(2),
        );
      }

      // Generate and save chart image
      await _generateChartImage(prices);

      // Update widget
      await HomeWidget.updateWidget(
        name: 'HomeScreenWidgetProvider',
        androidName: 'HomeScreenWidgetProvider',
      );
    } catch (e) {
      print('Error updating widget: $e');
    }
  }

  Future<void> _generateChartImage(List<PricePoint> prices) async {
    try {
      if (prices.isEmpty) {
        print('Warning: No prices to generate chart');
        return;
      }

      // Generate chart data for ALL prices (not just 7)
      final chartData = prices.map((p) => {
        'time': p.timeStart.toIso8601String(),
        'price': p.sekPerKwh,
      }).toList();

      final chartDataJson = jsonEncode(chartData);
      print('Saving chart data: ${prices.length} prices, ${chartDataJson.length} bytes');

      await HomeWidget.saveWidgetData('chart_data', chartDataJson);

      final minPrice = prices.map((p) => p.sekPerKwh).reduce((a, b) => a < b ? a : b);
      final maxPrice = prices.map((p) => p.sekPerKwh).reduce((a, b) => a > b ? a : b);

      await HomeWidget.saveWidgetData('chart_min', minPrice.toString());
      await HomeWidget.saveWidgetData('chart_max', maxPrice.toString());
      await HomeWidget.saveWidgetData('chart_count', prices.length.toString());

      print('Chart data saved successfully: min=$minPrice, max=$maxPrice, count=${prices.length}');
    } catch (e) {
      print('Error generating chart data: $e');
    }
  }

  Future<void> clearWidget() async {
    try {
      await HomeWidget.saveWidgetData('current_price', null);
      await HomeWidget.saveWidgetData('current_time', null);
      await HomeWidget.saveWidgetData('region', null);
      await HomeWidget.saveWidgetData('upcoming_prices', null);

      for (int i = 0; i < 6; i++) {
        await HomeWidget.saveWidgetData('upcoming_time_$i', null);
        await HomeWidget.saveWidgetData('upcoming_price_$i', null);
      }

      await HomeWidget.updateWidget(
        name: 'HomeScreenWidgetProvider',
        androidName: 'HomeScreenWidgetProvider',
      );
    } catch (e) {
      print('Error clearing widget: $e');
    }
  }
}
