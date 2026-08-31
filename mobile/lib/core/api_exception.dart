class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final Map<String, List<String>> fieldErrors;

  const ApiException({
    this.statusCode,
    required this.message,
    this.fieldErrors = const {},
  });

  String? fieldError(String field) {
    final errors = fieldErrors[field];
    return errors != null && errors.isNotEmpty ? errors.first : null;
  }

  bool get isValidation => statusCode == 422;
  bool get isUnauthorized => statusCode == 401;
  bool get isThrottled => statusCode == 429;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
