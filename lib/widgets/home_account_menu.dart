import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/theme/notime_theme.dart';
import '../models/connected_app.dart';
import '../services/app_state.dart';
import 'help_sheet.dart';

/// Top-right account menu after login (matches Scratchify / heynotime preview).
class HomeAccountMenuButton extends StatelessWidget {
  const HomeAccountMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final initial = _userInitial(state.session?.displayName ?? 'User');

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => _showMenu(context),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: NotiMeColors.textPrimary,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.arrow_drop_down,
                color: NotiMeColors.textPrimary,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _userInitial(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'U';
    return trimmed[0].toUpperCase();
  }

  void _showMenu(BuildContext rootContext) {
    final router = GoRouter.of(rootContext);
    final state = rootContext.read<AppState>();
    final selectedAppId =
        GoRouterState.of(rootContext).pathParameters['appId'] ??
            state.selectedApp?.id;

    final box = rootContext.findRenderObject() as RenderBox?;
    final offset = box?.localToGlobal(Offset.zero) ?? Offset.zero;
    final size = box?.size ?? Size.zero;
    final screenWidth = MediaQuery.sizeOf(rootContext).width;

    showDialog<void>(
      context: rootContext,
      barrierColor: Colors.black26,
      builder: (dialogContext) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(dialogContext),
                behavior: HitTestBehavior.opaque,
              ),
            ),
            Positioned(
              right: 12,
              top: offset.dy + size.height + 4,
              width: screenWidth * 0.72,
              child: Material(
                elevation: 8,
                shadowColor: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                color: NotiMeColors.surface,
                child: _AccountMenuPanel(
                  selectedAppId: selectedAppId,
                  onClose: () => Navigator.pop(dialogContext),
                  onSelectApp: (appId) {
                    Navigator.pop(dialogContext);
                    router.go('/home/$appId');
                  },
                  onAddApp: () {
                    Navigator.pop(dialogContext);
                    router.push('/add-app');
                  },
                  onHelp: () {
                    Navigator.pop(dialogContext);
                    showHelpSheet(rootContext);
                  },
                  onLogout: () {
                    Navigator.pop(dialogContext);
                    state.logout();
                    router.go('/');
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AccountMenuPanel extends StatelessWidget {
  const _AccountMenuPanel({
    required this.selectedAppId,
    required this.onClose,
    required this.onSelectApp,
    required this.onAddApp,
    required this.onHelp,
    required this.onLogout,
  });

  final String? selectedAppId;
  final VoidCallback onClose;
  final ValueChanged<String> onSelectApp;
  final VoidCallback onAddApp;
  final VoidCallback onHelp;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final apps = state.connectedApps;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onAddApp,
              style: FilledButton.styleFrom(
                backgroundColor: NotiMeColors.menuPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'Scan New QR to Add App',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...apps.map(
            (app) => _AppListTile(
              app: app,
              selected: app.id == selectedAppId,
              onTap: () => onSelectApp(app.id),
            ),
          ),
          if (apps.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No applications connected yet.',
                style: TextStyle(color: NotiMeColors.textSecondary),
              ),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: NotiMeColors.border),
          ),
          const Text(
            'Choose which application notifications you want to view.',
            style: TextStyle(
              fontSize: 13,
              color: NotiMeColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          _MenuLink(
            label: 'Help',
            onTap: onHelp,
          ),
          _MenuLink(
            label: 'Log out',
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

class _AppListTile extends StatelessWidget {
  const _AppListTile({
    required this.app,
    required this.selected,
    required this.onTap,
  });

  final ConnectedApp app;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Text(
          app.displayName,
          style: TextStyle(
            fontSize: 16,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            color: selected
                ? NotiMeColors.textPrimary
                : NotiMeColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _MenuLink extends StatelessWidget {
  const _MenuLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: NotiMeColors.primary,
          ),
        ),
      ),
    );
  }
}
