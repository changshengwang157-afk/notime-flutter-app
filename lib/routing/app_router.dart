import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/account_not_found_screen.dart';
import '../screens/add_app_screen.dart';
import '../screens/home_screen.dart';
import '../screens/notification_detail_screen.dart';
import '../screens/starter_screen.dart';
import '../services/app_state.dart';

GoRouter createRouter(AppState appState) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: appState,
    redirect: (context, state) {
      final loggedIn = appState.isLoggedIn;
      final onStarter = state.matchedLocation == '/';
      final onAccountNotFound = state.matchedLocation == '/account-not-found';

      if (loggedIn && (onStarter || onAccountNotFound)) {
        final appId = appState.selectedApp?.id ?? 'thescratchify';
        return '/home/$appId';
      }
      if (!loggedIn &&
          (state.matchedLocation.startsWith('/home') ||
              state.matchedLocation.startsWith('/notification') ||
              state.matchedLocation == '/add-app')) {
        return '/';
      }
      if (loggedIn && state.matchedLocation == '/home') {
        final appId = appState.selectedApp?.id ?? 'thescratchify';
        return '/home/$appId';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const StarterScreen(),
      ),
      GoRoute(
        path: '/account-not-found',
        builder: (_, __) => const AccountNotFoundScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => const HomeScreen(appId: 'thescratchify'),
      ),
      GoRoute(
        path: '/home/:appId',
        builder: (_, state) => HomeScreen(
          appId: state.pathParameters['appId']!,
        ),
      ),
      GoRoute(
        path: '/notification/:id',
        builder: (_, state) => NotificationDetailScreen(
          notificationId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/add-app',
        builder: (_, __) => const AddAppScreen(),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
  );
}
