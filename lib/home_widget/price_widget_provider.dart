import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/price_data.dart';
import '../services/electricity_api.dart';

// Background callback function for WorkManager
@pragma('vm:entry-point')
void widgetUpdateCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      print('Background task started: $task');

      // Get saved region from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final region = prefs.getString('selected_region') ?? 'SE3';

      print('Fetching prices for region: $region');

      // Fetch prices from API
      final apiService = ElectricityApiService();
      final prices = await apiService.fetchPrices(DateTime.now(), region);

      if (prices.isEmpty) {
        print('No prices fetched, skipping widget update');
        return Future.value(true);
      }

      print('Fetched ${prices.length} prices, updating widget');

      // Update widget using the same logic as the main app
      final widgetProvider = PriceWidgetProvider();
      await widgetProvider.updateWidget(prices, region);

      print('Background widget update completed successfully');
      return Future.value(true);
    } catch (e) {
      print('Background task error: $e');
      return Future.value(false);
    }
  });
}

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
