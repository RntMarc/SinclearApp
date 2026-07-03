import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/app_scope.dart';
import 'all_locations_map_screen.dart';
import 'active_shares_screen.dart';

class LocationSharingScreen extends StatefulWidget {
  const LocationSharingScreen({super.key});

  @override
  State<LocationSharingScreen> createState() => _LocationSharingScreenState();
}

class _LocationSharingScreenState extends State<LocationSharingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentTab = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        titleTextStyle: theme.textTheme.titleMedium,
        title: const Text('Standort teilen'),
        actions: [
          if (_currentTab == 1)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {
                AppScope.of(context).locationSharingManager.loadMySessions();
                if (mounted) setState(() {});
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.map_rounded), text: 'Karte'),
            Tab(icon: Icon(Icons.list_alt_rounded), text: 'Verwalten'),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentTab,
        children: const [
          AllLocationsMapScreen(),
          ActiveSharesScreen(),
        ],
      ),
      floatingActionButton: _currentTab == 1
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/standort-teilen/erstellen'),
              icon: const Icon(Icons.share_location_rounded),
              label: const Text('Standort teilen'),
            )
          : null,
    );
  }
}
