import '../models/user.dart';
import 'api_client.dart';

class AuthService {
  Future<({String token, User user})> login(
      String email, String password) async {
    final res = await dio.post('/auth/login',
        data: {'email': email, 'password': password});
    final token = res.data['token'] as String;
    final user = User.fromJson(res.data['user'] as Map<String, dynamic>);
    await saveToken(token);
    return (token: token, user: user);
  }

  Future<({String token, User user})> register(
      String username, String email, String password) async {
    final res = await dio.post('/auth/register',
        data: {'username': username, 'email': email, 'password': password});
    final token = res.data['token'] as String;
    final user = User.fromJson(res.data['user'] as Map<String, dynamic>);
    await saveToken(token);
    return (token: token, user: user);
  }

  Future<void> logout() => deleteToken();
}
