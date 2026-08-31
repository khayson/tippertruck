import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/issue.dart';

class IssuesProvider extends ChangeNotifier {
  final ApiClient _api;

  List<IssueItem> _issues = [];
  bool _loading = false;
  bool _submitting = false;
  String? _error;

  IssuesProvider(this._api);

  List<IssueItem> get issues => _issues;
  bool get loading => _loading;
  bool get submitting => _submitting;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.get('/issues');
      final raw = data['issues'] as List<dynamic>? ?? [];
      _issues = raw
          .map((e) => IssueItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Could not load issues.';
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> submit({
    required String issueType,
    required String description,
    int? orderId,
  }) async {
    _submitting = true;
    notifyListeners();
    try {
      final body = <String, dynamic>{
        'issue_type': issueType,
        'description': description,
      };
      if (orderId != null) body['order_id'] = orderId;
      await _api.post('/issues', data: body);
      await load();
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }
}
