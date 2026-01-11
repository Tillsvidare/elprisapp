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

      // Update widget
      await HomeWidget.updateWidget(
        name: 'HomeScreenWidgetProvider',
        androidName: 'HomeScreenWidgetProvider',
      );
    } catch (e) {
      print('Error updating widget: $e');
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
