import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config.dart';

const _storage = FlutterSecureStorage();
const _tokenKey = 'jwt_token';

// Shared Dio instance used by all services.
final dio = _buildDio();

Dio _buildDio() {
  final d = Dio(BaseOptions(baseUrl: kBaseUrl));

  d.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await _storage.read(key: _tokenKey);
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (error, handler) async {
      if (error.response?.statusCode == 401) {
        await _storage.delete(key: _tokenKey);
        // Caller catches DioException and redirects; no router ref needed here.
      }
      handler.next(error);
    },
  ));

  return d;
}

Future<void> saveToken(String token) =>
    _storage.write(key: _tokenKey, value: token);

Future<String?> readToken() => _storage.read(key: _tokenKey);

Future<void> deleteToken() => _storage.delete(key: _tokenKey);
