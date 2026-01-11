import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

class RegionSelector extends StatefulWidget {
  final String currentRegion;
  final Function(String) onRegionChanged;

  const RegionSelector({
    super.key,
    required this.currentRegion,
    required this.onRegionChanged,
  });

  @override
  State<RegionSelector> createState() => _RegionSelectorState();
}

class _RegionSelectorState extends State<RegionSelector> {
  final PreferencesService _prefs = PreferencesService();

  static const Map<String, String> regions = {
    'SE1': 'SE1 (Luleå)',
    'SE2': 'SE2 (Sundsvall)',
    'SE3': 'SE3 (Stockholm)',
    'SE4': 'SE4 (Malmö)',
  };

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: widget.currentRegion,
      items: regions.entries.map((entry) {
        return DropdownMenuItem<String>(
          value: entry.key,
          child: Text(entry.value),
        );
      }).toList(),
      onChanged: (String? newRegion) async {
        if (newRegion != null && newRegion != widget.currentRegion) {
          await _prefs.saveRegion(newRegion);
          widget.onRegionChanged(newRegion);
        }
      },
      underline: Container(),
      dropdownColor: Theme.of(context).colorScheme.surface,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onPrimary,
        fontSize: 16,
      ),
    );
  }
}
