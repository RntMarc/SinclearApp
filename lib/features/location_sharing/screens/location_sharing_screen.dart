import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    return Scaffold(
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.map_rounded), text: 'Karte'),
              Tab(icon: Icon(Icons.list_alt_rounded), text: 'Verwalten'),
            ],
          ),
          Expanded(
            child: IndexedStack(
              index: _currentTab,
              children: const [
                AllLocationsMapScreen(),
                ActiveSharesScreen(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _currentTab == 1
            ? FloatingActionButton.extended(
                key: const ValueKey('extended'),
                onPressed: () => context.go('/standort-teilen/erstellen'),
                icon: const Icon(Icons.share_location_rounded),
                label: const Text('Standort teilen'),
              )
            : FloatingActionButton(
                key: const ValueKey('icon'),
                onPressed: () => context.go('/standort-teilen/erstellen'),
                child: const Icon(Icons.share_location_rounded),
              ),
      ),
    );
  }
}
