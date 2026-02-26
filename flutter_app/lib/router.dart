import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/containers_screen.dart';
import 'screens/container_detail_screen.dart';
import 'screens/chat_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/evidence',
    redirect: (context, state) {
      final isAuthed = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isAuthed && !isAuthRoute) return '/login';
      if (isAuthed && isAuthRoute) return '/evidence';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/evidence', builder: (_, __) => const ContainersScreen()),
      GoRoute(
        path: '/evidence/:id',
        builder: (_, state) =>
            ContainerDetailScreen(containerId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/chat', builder: (_, __) => const ChatScreen()),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});
