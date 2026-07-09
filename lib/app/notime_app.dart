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

  /// Reliable navigation when user taps a push notification.
  Future<void> _navigateFromPushTap(
    String location, {
    bool usePush = false,
  }) async {
    if (!location.startsWith('/notification/')) {
      _router.go(location);
      return;
    }

    final slug = _appState.selectedApp?.id ?? ApiConfig.fallbackConnectSlug;
    final home = '/home/$slug';

    // Let session restore + router redirect settle (cold start from killed state).
    await Future<void>.delayed(const Duration(milliseconds: 200));

    if (_appState.isLoggedIn && _router.state.matchedLocation != home) {
      _router.go(home);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    if (!_appState.isLoggedIn) {
      _router.go('/');
      return;
    }

    if (_router.state.matchedLocation == location) {
      return;
    }

    if (usePush) {
      _router.push(location);
    } else {
      _router.go(location);
    }
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
