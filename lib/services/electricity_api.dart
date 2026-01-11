import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/price_data.dart';

class ElectricityApiService {
  static const String _baseUrl = 'https://www.elprisetjustnu.se/api/v1/prices';

  List<PricePoint>? _cachedPrices;
  DateTime? _cacheDate;
  String? _cacheRegion;

  Future<List<PricePoint>> fetchPrices(DateTime date, String region) async {
    // Check cache
    if (_cachedPrices != null &&
        _cacheDate != null &&
        _cacheRegion == region &&
        _cacheDate!.year == date.year &&
        _cacheDate!.month == date.month &&
        _cacheDate!.day == date.day) {
      return _cachedPrices!;
    }

    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    final url = '$_baseUrl/$year/$month-$day\_$region.json';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        final prices = jsonData.map((json) => PricePoint.fromJson(json)).toList();

        // Cache the result
        _cachedPrices = prices;
        _cacheDate = date;
        _cacheRegion = region;

        return prices;
      } else if (response.statusCode == 404) {
        throw Exception('Inga prisdata tillgängliga för det valda datumet');
      } else {
        throw Exception('Kunde inte hämta prisdata: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Nätverksfel: Kontrollera din internetanslutning');
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
