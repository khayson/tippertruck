import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/order.dart';

class DriverOrdersProvider extends ChangeNotifier {
  final ApiClient _api;

  List<OrderSummary> _orders = [];
  OrderSummary? _selected;
  bool _loading = false;
  bool _actionLoading = false;
  String? _error;

  DriverOrdersProvider(this._api);

  List<OrderSummary> get orders => _orders;
  OrderSummary? get selected => _selected;
  bool get loading => _loading;
  bool get actionLoading => _actionLoading;
  String? get error => _error;

  Future<void> loadOrders({String? status}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final query = status != null ? '?status=$status' : '';
      final data = await _api.get('/operator/orders$query');
      final list = data['orders'] as List<dynamic>;
      _orders = list
          .map((e) => OrderSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Could not load assigned orders.';
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> loadOrder(int id) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.get('/operator/orders/$id');
      _selected = OrderSummary.fromJson(data['order'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      _error = e.message;
      _selected = null;
    } catch (_) {
      _error = 'Could not load order.';
      _selected = null;
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> dispatch(int id) async {
    await _transition(id, '/operator/orders/$id/dispatch');
  }

  Future<void> deliver(int id) async {
    await _transition(id, '/operator/orders/$id/deliver');
  }

  Future<void> _transition(int id, String path) async {
    _actionLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.post(path);
      final updated = OrderSummary.fromJson(
        data['order'] as Map<String, dynamic>,
      );
      _selected = updated;
      final index = _orders.indexWhere((o) => o.id == id);
      if (index >= 0) {
        _orders = [..._orders]..[index] = updated;
      }
    } on ApiException catch (e) {
      _error = e.message;
      rethrow;
    } finally {
      _actionLoading = false;
      notifyListeners();
    }
  }
}
