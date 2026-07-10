import 'package:brick_bootstrap5_plus/brick_bootstrap5_plus.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/theme/notime_theme.dart';
import '../config/api_config.dart';
import '../core/app_messenger.dart';
import '../routing/app_router.dart';
import '../services/app_state.dart';

class NotiMeApp extends StatefulWidget {
  const NotiMeApp({super.key});

  @override
  State<NotiMeApp> createState() => _NotiMeAppState();
}

class _NotiMeAppState extends State<NotiMeApp> {
  late final AppState _appState;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _appState = AppState();
    _router = createRouter(_appState);
    _appState.setupPushHandlers(
      onNavigate: (location, {bool usePush = false}) {
        _navigateFromPushTap(location, usePush: usePush);
      },
    );
    _appState.setupDeepLinks(
      onPairingUrl: (payload) async {
        if (_appState.isLoggedIn) {
          final result = await _appState.connectAppFromQr(payload);
          if (result == ConnectAppResult.success && mounted) {
            final slug =
                _appState.selectedApp?.id ?? ApiConfig.fallbackConnectSlug;
            _router.go('/home/$slug');
          }
          return;
        }
        final result = await _appState.loginFromQrPayload(payload);
        if (result == LoginResult.success && mounted) {
          final slug =
              _appState.selectedApp?.id ?? ApiConfig.fallbackConnectSlug;
          _router.go('/home/$slug');
        }
      },
      onConnectSlug: (slug) async {
        if (_appState.isLoggedIn) {
          _router.go('/home/$slug');
          return;
        }
        final result = await _appState.loginFallbackConnect(slug);
        if (result == LoginResult.success && mounted) {
          _router.go('/home/$slug');
        }
      },
    );
  }

  @override
  void dispose() {
    _router.dispose();
    _appState.dispose();
    super.dispose();
  }

  /// Opens notification detail from a push tap (Android + iOS).
  ///
  /// Important: do **not** bounce through `/home` first. That race with
  /// GoRouter's `refreshListenable` left users stuck on the main screen.
  Future<void> _navigateFromPushTap(
    String location, {
    bool usePush = false,
  }) async {
    await _appState.ready;

    if (!location.startsWith('/notification/')) {
      _router.go(location);
      return;
    }

    if (!_appState.isLoggedIn) {
      _router.go('/');
      return;
    }

    if (_router.state.matchedLocation == location) {
      return;
    }

    // Direct go is reliable on cold start and background resume.
    // Detail screen handles "back" → home when the stack is empty.
    // [usePush] is kept for API compatibility with AppState callbacks.
    _router.go(location);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppState>.value(
      value: _appState,
      child: LayoutBuilder(
        builder: (context, _) {
          final screenData = ScreenData.fallBack(context);
          return BootstrapTheme(
            data: screenData,
            builder: (ctx) {
              final theme =
                  BootstrapTheme.of(ctx).toTheme(theme: buildNotiMeTheme());
              return MaterialApp.router(
                title: 'NotiMe',
                debugShowCheckedModeBanner: false,
                theme: theme,
                scaffoldMessengerKey: appMessengerKey,
                routerConfig: _router,
                builder: (context, child) {
                  // No DEBUG/Demo ribbon on debug builds.
                  return child ?? const SizedBox.shrink();
                },
              );
            },
          );
        },
      ),
    );
  }
}
