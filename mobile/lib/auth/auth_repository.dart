import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../models/user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});

class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  Future<({String token, AppUser user})> login(String email, String password) {
    return _session('/auth/login', {'email': email, 'password': password});
  }

  Future<({String token, AppUser user})> register(
    String name,
    String email,
    String password,
  ) {
    return _session('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
    });
  }

  Future<AppUser> me() async {
    final res = await _dio.get<Map<String, dynamic>>('/auth/me');
    return AppUser.fromJson(res.data!);
  }

  Future<void> deleteAccount(String password) async {
    await _dio.delete('/auth/me', data: {'password': password});
  }

  Future<void> forgotPassword(String email) async {
    await _dio.post('/auth/forgot-password', data: {'email': email});
  }

  Future<void> resendVerification() async {
    await _dio.post('/auth/resend-verification');
  }

  Future<({String token, AppUser user})> _session(
    String path,
    Map<String, dynamic> body,
  ) async {
    final res = await _dio.post<Map<String, dynamic>>(path, data: body);
    final data = res.data!;
    return (
      token: data['token'] as String,
      user: AppUser.fromJson(data['user'] as Map<String, dynamic>),
    );
  }
}

String apiErrorMessage(Object error, String network, String generic) {
  if (error is DioException) return apiException(error, network).message;
  if (error is ApiException) return error.message;
  return generic;
}
