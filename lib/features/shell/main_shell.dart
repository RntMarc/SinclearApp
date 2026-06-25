import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../notifications/widgets/notification_sheet.dart';
import '../../core/di/app_scope.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 600;

    if (isDesktop) {
      return _DesktopShell(child: child);
    }
    return _MobileShell(child: child);
  }
}

class _DesktopShell extends StatelessWidget {
  final Widget child;
  const _DesktopShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(_titleForLocation(location)),
        actions: [_NotificationBell()],
      ),
      body: Row(
        children: [
          SizedBox(
            width: 288,
            child: _NavContent(
              currentLocation: location,
              onNavigate: (route) => context.go(route),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _MobileShell extends StatelessWidget {
  final Widget child;
  const _MobileShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final title = _titleForLocation(location);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [_NotificationBell()],
      ),
      drawer: Drawer(
        child: _NavContent(
          currentLocation: location,
          onNavigate: (route) {
            Navigator.pop(context);
            context.go(route);
          },
        ),
      ),
      body: child,
    );
  }
}

String _titleForLocation(String location) {
  if (location.startsWith('/entdecken')) return 'Entdecken';
  if (location.startsWith('/reisen')) return 'Reisen & Events';
  if (location.startsWith('/kontakte')) return 'Kontakte';
  if (location.startsWith('/einstellungen')) return 'Einstellungen';
  return 'Home';
}

class _NotificationBell extends StatefulWidget {
  @override
  State<_NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<_NotificationBell> {
  bool _listenerAdded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_listenerAdded) {
      _listenerAdded = true;
      AppScope.of(context).notification.addListener(_onChange);
    }
  }

  @override
  void dispose() {
    AppScope.of(context).notification.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final notif = AppScope.of(context).notification;
    return IconButton(
      icon: notif.unreadCount > 0
          ? Badge(
              label: Text(
                notif.unreadCount > 99 ? '99+' : notif.unreadCount.toString(),
              ),
              child: const Icon(Icons.notifications_rounded),
            )
          : const Icon(Icons.notifications_outlined),
      onPressed: () => _showSheet(context),
    );
  }

  void _showSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => const NotificationSheet(),
    );
  }
}

class _NavContent extends StatelessWidget {
  final String currentLocation;
  final void Function(String route) onNavigate;

  const _NavContent({required this.currentLocation, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedIndex = _selectedIndex(currentLocation);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Row(
              children: [
                Image.asset('assets/logo.png', width: 32, height: 32),
                const SizedBox(width: 12),
                Text(
                  'Beyond',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Navigation',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_rounded),
            title: const Text('Home'),
            selected: selectedIndex == 0,
            onTap: () => onNavigate('/home'),
          ),
          ListTile(
            leading: const Icon(Icons.explore_rounded),
            title: const Text('Entdecken'),
            selected: selectedIndex == 1,
            onTap: () => onNavigate('/entdecken'),
          ),
          ListTile(
            leading: const Icon(Icons.flight_rounded),
            title: const Text('Reisen & Events'),
            selected: selectedIndex == 2,
            onTap: () => onNavigate('/reisen'),
          ),
           ListTile(
            leading: const Icon(Icons.people_rounded),
            title: const Text('Kontakte'),
            selected: selectedIndex == 3,
            onTap: () => onNavigate('/kontakte'),
          ),
           ListTile(
            leading: const Icon(Icons.settings_rounded),
            title: const Text('Einstellungen'),
            selected: selectedIndex == 4,
            onTap: () => onNavigate('/einstellungen'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  int _selectedIndex(String location) {
    if (location.startsWith('/entdecken')) return 1;
    if (location.startsWith('/reisen')) return 2;
    if (location.startsWith('/kontakte')) return 3;
    if (location.startsWith('/einstellungen')) return 4;
    return 0;
  }
}
