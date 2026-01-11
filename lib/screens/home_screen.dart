import 'dart:async';
import 'package:flutter/material.dart';
import '../models/price_data.dart';
import '../services/electricity_api.dart';
import '../services/preferences_service.dart';
import '../widgets/current_price_card.dart';
import '../widgets/price_chart.dart';
import '../widgets/region_selector.dart';
import '../home_widget/price_widget_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ElectricityApiService _apiService = ElectricityApiService();
  final PreferencesService _prefs = PreferencesService();
  final PriceWidgetProvider _widgetProvider = PriceWidgetProvider();

  List<PricePoint>? _prices;
  String _currentRegion = 'SE3';
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startPeriodicUpdates();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicUpdates() {
    // Update widget every 15 minutes
    _updateTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
      _updateWidget();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load saved region
      _currentRegion = await _prefs.getRegion();

      // Fetch prices
      final prices = await _apiService.fetchPrices(DateTime.now(), _currentRegion);

      setState(() {
        _prices = prices;
        _isLoading = false;
      });

      // Update home screen widget
      await _updateWidget();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _updateWidget() async {
    if (_prices == null || _prices!.isEmpty) return;

    // Pass ALL prices to widget (for full chart rendering)
    await _widgetProvider.updateWidget(_prices!, _currentRegion);
  }

  Future<void> _onRegionChanged(String newRegion) async {
    setState(() {
      _currentRegion = newRegion;
    });
    await _loadData();
  }

  Future<void> _onRefresh() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Elpris'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: RegionSelector(
              currentRegion: _currentRegion,
              onRegionChanged: _onRegionChanged,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Hämtar prisdata...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Försök igen'),
              ),
            ],
          ),
        ),
      );
    }

    if (_prices == null || _prices!.isEmpty) {
      return const Center(
        child: Text('Ingen prisdata tillgänglig'),
      );
    }

    final currentPrice = _apiService.getCurrentPrice(_prices!);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          CurrentPriceCard(currentPrice: currentPrice),
          PriceChart(prices: _prices!),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
