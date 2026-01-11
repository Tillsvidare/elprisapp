import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  static const String _regionKey = 'selected_region';
  static const String _defaultRegion = 'SE3';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> saveRegion(String region) async {
    await _prefs?.setString(_regionKey, region);
  }

  Future<String> getRegion() async {
    if (_prefs == null) {
      await init();
    }
    return _prefs?.getString(_regionKey) ?? _defaultRegion;
  }
}
