import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/order.dart';

class OrdersProvider extends ChangeNotifier {
  final ApiClient _api;
  static const _cacheKey = 'cached_orders_page';

  List<OrderSummary> _orders = [];
  OrderSummary? _tracked;
  bool _loading = false;
  bool _fromCache = false;
  String? _error;

  OrdersProvider(this._api);

  List<OrderSummary> get orders => _orders;
  OrderSummary? get tracked => _tracked;
  bool get loading => _loading;
  bool get fromCache => _fromCache;
  String? get error => _error;

  Future<void> loadHistory() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.get('/orders');
      final list = data['orders'] as List<dynamic>;
      _orders = list
          .map((e) => OrderSummary.fromJson(e as Map<String, dynamic>))
          .toList();
      _fromCache = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(data['orders']));
    } on ApiException catch (e) {
      await _loadCache();
      if (_orders.isEmpty) _error = e.message;
    } catch (_) {
      await _loadCache();
      if (_orders.isEmpty) _error = 'Could not load orders.';
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return;
    final list = jsonDecode(raw) as List<dynamic>;
    _orders = list
        .map((e) => OrderSummary.fromJson(e as Map<String, dynamic>))
        .toList();
    _fromCache = true;
  }

  Future<OrderSummary> placeOrder(Map<String, dynamic> payload) async {
    final data = await _api.post('/orders', data: payload);
    final order = OrderSummary.fromJson(data['order'] as Map<String, dynamic>);
    _tracked = order;
    notifyListeners();
    return order;
  }

  Future<void> loadTracked(int id) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.get('/orders/$id');
      _tracked = OrderSummary.fromJson(data['order'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      _error = e.message;
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> pollTracked(int id) async {
    try {
      final data = await _api.get('/orders/$id');
      _tracked = OrderSummary.fromJson(data['order'] as Map<String, dynamic>);
      notifyListeners();
    } on ApiException {
      // keep last known state while polling
    }
  }

  Future<void> cancelTracked(int id) async {
    final data = await _api.post('/orders/$id/cancel');
    _tracked = OrderSummary.fromJson(data['order'] as Map<String, dynamic>);
    notifyListeners();
  }
}
