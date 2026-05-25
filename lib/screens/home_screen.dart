import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/theme/notime_theme.dart';
import '../data/mock_data.dart';
import '../models/connected_app.dart';
import '../services/app_state.dart';
import '../widgets/connected_app_header.dart';
import '../widgets/home_account_menu.dart';
import '../widgets/notime_app_bar_title.dart';
import '../widgets/notification_list_tile.dart';
import '../widgets/notime_scaffold.dart';
import 'history_tab.dart';

/// Main shell after login — one notifications page per connected app (`/home/:appId`).
class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.appId, super.key});

  final String appId;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = context.read<AppState>();
    if (state.selectedApp?.id != widget.appId) {
      state.selectApp(widget.appId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final pageApp = state.connectedAppById(widget.appId);

    return NotiMePage(
      appBar: AppBar(
        title: const NotiMeAppBarTitle(),
        centerTitle: true,
        actions: const [
          HomeAccountMenuButton(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
      body: _tabIndex == 0
          ? _AppNotificationsPage(app: pageApp, appId: widget.appId)
          : const HistoryTab(),
    );
  }
}

class _AppNotificationsPage extends StatelessWidget {
  const _AppNotificationsPage({required this.app, required this.appId});

  final ConnectedApp? app;
  final String appId;

  @override
  Widget build(BuildContext context) {
    final pageApp = app;
    if (pageApp == null) {
      return Center(
        child: Text('Application not found: $appId'),
      );
    }

    final items = MockData.notificationsForApp(pageApp.id);

    return RefreshIndicator(
      onRefresh: () async {
        await Future<void>.delayed(const Duration(milliseconds: 600));
      },
      child: ListView(
        key: ValueKey<String>(pageApp.id),
        padding: const EdgeInsets.all(16),
        children: [
          ConnectedAppHeader(app: pageApp),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No notifications yet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: NotiMeColors.textSecondary),
              ),
            )
          else
            ...items.map(
              (item) => NotificationListTile(
                key: ValueKey<String>(item.id),
                item: item,
                onTap: () => context.push('/notification/${item.id}'),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
