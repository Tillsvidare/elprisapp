import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/price_data.dart';

class ElectricityApiService {
  static const String _baseUrl = 'https://www.elprisetjustnu.se/api/v1/prices';

  List<PricePoint>? _cachedPrices;
  DateTime? _cacheTime;
  String? _cacheRegion;

  /// Fetches prices for today and tomorrow, combining them into a single list
  /// Returns the full 24-hour period from now
  Future<List<PricePoint>> fetchPrices(DateTime date, String region) async {
    // Check cache (valid for 15 minutes)
    if (_cachedPrices != null &&
        _cacheTime != null &&
        _cacheRegion == region &&
        DateTime.now().difference(_cacheTime!).inMinutes < 15) {
      return _cachedPrices!;
    }

    try {
      final today = DateTime.now();
      final tomorrow = today.add(const Duration(days: 1));

      // Fetch both today and tomorrow
      final todayPrices = await _fetchPricesForDate(today, region);
      List<PricePoint> tomorrowPrices = [];

      try {
        tomorrowPrices = await _fetchPricesForDate(tomorrow, region);
      } catch (e) {
        // Tomorrow's prices might not be available yet (published around 13:00)
        // This is okay, we'll just use today's prices
      }

      // Combine and filter to only future prices + current
      final now = DateTime.now();
      final allPrices = [...todayPrices, ...tomorrowPrices];

      // Get current and all future prices
      final relevantPrices = allPrices
          .where((price) => price.timeEnd.isAfter(now))
          .toList();

      // Sort by time
      relevantPrices.sort((a, b) => a.timeStart.compareTo(b.timeStart));

      // Cache the result
      _cachedPrices = relevantPrices;
      _cacheTime = DateTime.now();
      _cacheRegion = region;

      return relevantPrices;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Nätverksfel: Kontrollera din internetanslutning');
    }
  }

  Future<List<PricePoint>> _fetchPricesForDate(DateTime date, String region) async {
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    final url = '$_baseUrl/$year/$month-$day\_$region.json';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((json) => PricePoint.fromJson(json)).toList();
    } else if (response.statusCode == 404) {
      throw Exception('Inga prisdata tillgängliga för det valda datumet');
    } else {
      throw Exception('Kunde inte hämta prisdata: ${response.statusCode}');
    }
  }

  PricePoint? getCurrentPrice(List<PricePoint> prices) {
    try {
      return prices.firstWhere((price) => price.isCurrent());
    } catch (e) {
      return null;
    }
  }

  List<PricePoint> getUpcomingPrices(List<PricePoint> prices, int count) {
    final now = DateTime.now();
    final upcoming = prices
        .where((price) => price.timeStart.isAfter(now))
        .take(count)
        .toList();
    return upcoming;
  }

  double getAveragePrice(List<PricePoint> prices) {
    if (prices.isEmpty) return 0.0;
    final sum = prices.fold(0.0, (sum, price) => sum + price.sekPerKwh);
    return sum / prices.length;
  }

  double getMinPrice(List<PricePoint> prices) {
    if (prices.isEmpty) return 0.0;
    return prices.map((p) => p.sekPerKwh).reduce((a, b) => a < b ? a : b);
  }

  double getMaxPrice(List<PricePoint> prices) {
    if (prices.isEmpty) return 0.0;
    return prices.map((p) => p.sekPerKwh).reduce((a, b) => a > b ? a : b);
  }
}
