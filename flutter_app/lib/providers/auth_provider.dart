import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';

final _authService = AuthService();

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    // Restore session: if a token exists the user is considered logged in.
    // We don't have a /me endpoint, so we just signal "authenticated" with a
    // placeholder until they next log in. Return null to force login screen.
    final token = await readToken();
    return token != null ? _storedUser : null;
  }

  // Stored user across the session (set on login/register).
  User? _storedUser;

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await _authService.login(email, password);
      _storedUser = result.user;
      return result.user;
    });
  }

  Future<void> register(String username, String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await _authService.register(username, email, password);
      _storedUser = result.user;
      return result.user;
    });
  }

  Future<void> logout() async {
    await _authService.logout();
    _storedUser = null;
    state = const AsyncData(null);
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, User?>(AuthNotifier.new);
