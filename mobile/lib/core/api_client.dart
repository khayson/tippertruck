import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_exception.dart';

class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage;
  VoidCallback? onUnauthorized;

  static const _tokenKey = 'auth_token';

  ApiClient({required String baseUrl, FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: _tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await clearToken();
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _request(() => _dio.get(path, queryParameters: queryParameters));
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    return _request(() => _dio.post(path, data: data));
  }

  Future<Map<String, dynamic>> _request(
    Future<Response<dynamic>> Function() call,
  ) async {
    try {
      final response = await call();
      return _unwrap(response);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw const ApiException(
          message:
              'Connection timed out. Please check your internet and try again.',
        );
      }

      if (e.type == DioExceptionType.connectionError ||
          e.error is SocketException) {
        throw const ApiException(
          message: 'No internet connection. Please check your network.',
        );
      }

      if (e.response != null) {
        final data = e.response!.data;
        final statusCode = e.response!.statusCode;

        if (data is Map<String, dynamic>) {
          final message = data['message'] as String? ?? 'Something went wrong.';
          final rawErrors = data['errors'] as Map<String, dynamic>?;
          final fieldErrors = <String, List<String>>{};
          if (rawErrors != null) {
            for (final entry in rawErrors.entries) {
              fieldErrors[entry.key] = (entry.value as List<dynamic>)
                  .map((e) => e.toString())
                  .toList();
            }
          }
          throw ApiException(
            statusCode: statusCode,
            message: message,
            fieldErrors: fieldErrors,
          );
        }

        throw ApiException(
          statusCode: statusCode,
          message: 'Something went wrong.',
        );
      }

      throw const ApiException(message: 'An unexpected error occurred.');
    }
  }

  Map<String, dynamic> _unwrap(Response<dynamic> response) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final success = data['success'] as bool? ?? false;
      if (!success) {
        final rawErrors = data['errors'] as Map<String, dynamic>?;
        final fieldErrors = <String, List<String>>{};
        if (rawErrors != null) {
          for (final entry in rawErrors.entries) {
            fieldErrors[entry.key] = (entry.value as List<dynamic>)
                .map((e) => e.toString())
                .toList();
          }
        }
        throw ApiException(
          statusCode: response.statusCode,
          message: data['message'] as String? ?? 'Request failed.',
          fieldErrors: fieldErrors,
        );
      }
      return data['data'] as Map<String, dynamic>? ?? {};
    }
    throw const ApiException(message: 'Invalid response format.');
  }
}
