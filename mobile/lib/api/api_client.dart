import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/token_store.dart';
import '../config.dart';
import '../prefs.dart';
import 'api_exception.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await ref.read(tokenStoreProvider).readToken();
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        options.headers['Accept-Language'] =
            ref.read(prefsProvider).locale.languageCode;
        handler.next(options);
      },
    ),
  );
  if (!kReleaseMode) dio.interceptors.add(_networkLog);
  return dio;
});

const _secretKeys = {
  'password',
  'token',
  'access_token',
  'refresh_token',
  'authorization',
};

final _networkLog = InterceptorsWrapper(
  onRequest: (options, handler) {
    final hasAuth = options.headers['Authorization'] != null;
    _log('→ ${options.method} ${options.uri} auth=$hasAuth');
    final body = _redacted(options.data);
    if (body != null) _log('  $body');
    handler.next(options);
  },
  onResponse: (response, handler) {
    final options = response.requestOptions;
    _log('← ${response.statusCode} ${options.method} ${options.uri}');
    _log('  ${_redacted(response.data)}');
    handler.next(response);
  },
  onError: (error, handler) {
    final options = error.requestOptions;
    final response = error.response;
    _log('✖ ${options.method} ${options.uri}');
    _log('  type: ${error.type.name}');
    _log('  message: ${error.message}');
    _log('  status: ${response?.statusCode} ${response?.statusMessage ?? ''}');
    final cause = error.error;
    _log('  cause: ${cause?.runtimeType} $cause');
    final body = response?.data;
    if (body != null) _log('  body: ${_redacted(body)}');
    final stack = error.stackTrace
        .toString()
        .trim()
        .split('\n')
        .take(8)
        .join('\n');
    if (stack.isNotEmpty) _log('  stack:\n$stack');
    handler.next(error);
  },
);

void _log(String message) => debugPrint('[api] $message');

Object? _redacted(Object? data) {
  if (data is Map) {
    return data.map((key, value) {
      final name = key.toString().toLowerCase();
      return MapEntry(
        key,
        _secretKeys.contains(name) ? '***' : _redacted(value),
      );
    });
  }
  if (data is List) return data.map(_redacted).toList();
  return data;
}

ApiException apiException(DioException error, String fallback) {
  final data = error.response?.data;
  if (data is Map && data['error'] is String) {
    return ApiException(
      data['error'] as String,
      status: error.response?.statusCode,
      code: data['code'] as String?,
    );
  }
  if (error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.connectionTimeout) {
    return ApiException(fallback);
  }
  return ApiException(fallback, status: error.response?.statusCode);
}
