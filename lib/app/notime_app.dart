import 'package:brick_bootstrap5_plus/brick_bootstrap5_plus.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/theme/notime_theme.dart';
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
    _appState.setupPushHandlers();
  }

  @override
  void dispose() {
    _router.dispose();
    _appState.dispose();
    super.dispose();
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
