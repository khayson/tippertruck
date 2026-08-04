import 'dart:convert';

import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/config_data.dart';

class ConfigProvider extends ChangeNotifier {
  final ApiClient _api;

  ConfigData? _config;
  bool _loading = false;
  bool _fromCache = false;
  String? _error;

  static const _cacheKey = 'cached_config';

  ConfigProvider(this._api);

  ConfigData? get config => _config;
  bool get loading => _loading;
  bool get fromCache => _fromCache;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.get('/config');
      _config = ConfigData.fromJson(data);
      _fromCache = false;
      _error = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(data));
    } on ApiException catch (e) {
      await _loadFromCache();
      if (_config == null) {
        _error = e.message;
      }
    } catch (e) {
      await _loadFromCache();
      if (_config == null) {
        _error = 'Failed to load configuration.';
      }
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached != null) {
      _config = ConfigData.fromJson(jsonDecode(cached) as Map<String, dynamic>);
      _fromCache = true;
    }
  }
}
