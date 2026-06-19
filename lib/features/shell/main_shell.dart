import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
    final title = location.startsWith('/aktuell')
        ? 'Aktuell'
        : location.startsWith('/entdecken')
        ? 'Entdecken'
        : location.startsWith('/reisen')
        ? 'Reisen & Events'
        : 'Home';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
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

class _NavContent extends StatelessWidget {
  final String currentLocation;
  final void Function(String route) onNavigate;

  const _NavContent({
    required this.currentLocation,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = AppScope.of(context).auth;
    final selectedIndex = _selectedIndex(currentLocation);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Row(
              children: [
                Image.asset(
                  'assets/logo.png',
                  width: 32,
                  height: 32,
                ),
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
            leading: const Icon(Icons.article_rounded),
            title: const Text('Aktuell'),
            selected: selectedIndex == 1,
            onTap: () => onNavigate('/aktuell'),
          ),
          ListTile(
            leading: const Icon(Icons.explore_rounded),
            title: const Text('Entdecken'),
            selected: selectedIndex == 2,
            onTap: () => onNavigate('/entdecken'),
          ),
          ListTile(
            leading: const Icon(Icons.flight_rounded),
            title: const Text('Reisen & Events'),
            selected: selectedIndex == 3,
            onTap: () => onNavigate('/reisen'),
          ),
          const Spacer(),
          const Divider(),
          ListenableBuilder(
            listenable: auth,
            builder: (context, _) => ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: Text(auth.isLoggedIn ? 'Abmelden' : 'Anmelden'),
              onTap: () async {
                if (auth.isLoggedIn) {
                  await auth.logout();
                  if (!context.mounted) return;
                  onNavigate('/');
                } else {
                  onNavigate('/login');
                }
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  int _selectedIndex(String location) {
    if (location.startsWith('/aktuell')) return 1;
    if (location.startsWith('/entdecken')) return 2;
    if (location.startsWith('/reisen')) return 3;
    return 0;
  }
}
