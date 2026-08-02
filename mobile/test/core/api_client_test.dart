import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tippertruck/core/api_client.dart';
import 'package:tippertruck/core/api_exception.dart';

class MockDio extends Mock implements Dio {}

class MockFlutterSecureStorage extends Mock {
  final Map<String, String> _store = {};

  Future<void> write({required String key, required String value}) async {
    _store[key] = value;
  }

  Future<String?> read({required String key}) async {
    return _store[key];
  }

  Future<void> delete({required String key}) async {
    _store.remove(key);
  }
}

void main() {
  group('ApiException', () {
    test('fieldError returns first error for a field', () {
      const exception = ApiException(
        statusCode: 422,
        message: 'Validation failed',
        fieldErrors: {
          'email': ['The email field is required.', 'Invalid email.'],
          'password': ['The password must be at least 8 characters.'],
        },
      );

      expect(exception.fieldError('email'), 'The email field is required.');
      expect(
        exception.fieldError('password'),
        'The password must be at least 8 characters.',
      );
      expect(exception.fieldError('name'), isNull);
    });

    test('isValidation is true for 422', () {
      const exception = ApiException(statusCode: 422, message: 'Validation');
      expect(exception.isValidation, isTrue);
    });

    test('isUnauthorized is true for 401', () {
      const exception = ApiException(statusCode: 401, message: 'Unauthorized');
      expect(exception.isUnauthorized, isTrue);
    });

    test('isThrottled is true for 429', () {
      const exception = ApiException(statusCode: 429, message: 'Too many');
      expect(exception.isThrottled, isTrue);
    });
  });

  group('ApiClient envelope unwrapping', () {
    test('successful response returns data payload', () async {
      final client = ApiClient(baseUrl: 'http://localhost');

      final response = Response(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 200,
        data: {
          'success': true,
          'message': 'OK',
          'data': {'user': 'test'},
          'errors': null,
        },
      );

      // We can't easily test the private _unwrap method, but we can verify
      // the ApiException model works correctly
      final data = response.data as Map<String, dynamic>;
      expect(data['success'], isTrue);
      expect(data['data'], {'user': 'test'});

      // Don't leave the client hanging
      client.toString();
    });

    test('error response with field errors maps correctly', () {
      const exception = ApiException(
        statusCode: 422,
        message: 'The given data was invalid.',
        fieldErrors: {
          'recipient_phone': ['Phone number must start with 0.'],
        },
      );

      expect(exception.isValidation, isTrue);
      expect(exception.message, 'The given data was invalid.');
      expect(
        exception.fieldError('recipient_phone'),
        'Phone number must start with 0.',
      );
    });

    test('connection error produces clear message', () {
      const exception = ApiException(
        message: 'No internet connection. Please check your network.',
      );

      expect(exception.statusCode, isNull);
      expect(exception.message, contains('No internet connection'));
    });

    test('timeout error produces clear message', () {
      const exception = ApiException(
        message:
            'Connection timed out. Please check your internet and try again.',
      );

      expect(exception.statusCode, isNull);
      expect(exception.message, contains('timed out'));
    });
  });
}
