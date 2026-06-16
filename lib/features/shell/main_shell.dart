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
    final theme = Theme.of(context);
    final auth = AppScope.of(context).auth;
    final location = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      body: Row(
        children: [
          NavigationDrawer(
            selectedIndex: _selectedIndex(location),
            onDestinationSelected: (i) =>
                _onNavigate(context, i),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: SafeArea(
                  bottom: false,
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
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  'Navigation',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              NavigationDrawerDestination(
                icon: const Icon(Icons.home_rounded),
                label: const Text('Home'),
              ),
              NavigationDrawerDestination(
                icon: const Icon(Icons.article_rounded),
                label: const Text('Aktuell'),
              ),
              NavigationDrawerDestination(
                icon: const Icon(Icons.explore_rounded),
                label: const Text('Entdecken'),
              ),
              const Divider(),
              ListenableBuilder(
                listenable: auth,
                builder: (context, _) {
                  return NavigationDrawerDestination(
                    icon: const Icon(Icons.logout_rounded),
                    label: Text(auth.isLoggedIn ? 'Abmelden' : 'Anmelden'),
                  );
                },
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }

  int _selectedIndex(String location) {
    if (location.startsWith('/aktuell')) return 1;
    if (location.startsWith('/entdecken')) return 2;
    return 0;
  }

  void _onNavigate(BuildContext context, int index) async {
    switch (index) {
      case 0:
        context.go('/home');
      case 1:
        context.go('/aktuell');
      case 2:
        context.go('/entdecken');
      case 3:
        final auth = AppScope.of(context).auth;
        if (auth.isLoggedIn) {
          await auth.logout();
          if (!context.mounted) return;
          context.go('/');
        } else {
          context.go('/login');
        }
    }
  }
}

class _MobileShell extends StatelessWidget {
  final Widget child;
  const _MobileShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = AppScope.of(context).auth;
    final location = GoRouterState.of(context).matchedLocation;
    final title = location.startsWith('/aktuell')
        ? 'Aktuell'
        : location.startsWith('/entdecken')
            ? 'Entdecken'
            : 'Home';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              DrawerHeader(
                child: Row(
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      width: 40,
                      height: 40,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Beyond',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home_rounded),
                title: const Text('Home'),
                selected: location == '/home',
                onTap: () {
                  Navigator.pop(context);
                  context.go('/home');
                },
              ),
              ListTile(
                leading: const Icon(Icons.article_rounded),
                title: const Text('Aktuell'),
                selected: location.startsWith('/aktuell'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/aktuell');
                },
              ),
              ListTile(
                leading: const Icon(Icons.explore_rounded),
                title: const Text('Entdecken'),
                selected: location.startsWith('/entdecken'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/entdecken');
                },
              ),
              const Spacer(),
              ListenableBuilder(
                listenable: auth,
                builder: (context, _) => ListTile(
                  leading: const Icon(Icons.logout_rounded),
                  title: Text(auth.isLoggedIn ? 'Abmelden' : 'Anmelden'),
                  onTap: () async {
                    Navigator.pop(context);
                    if (auth.isLoggedIn) {
                      await auth.logout();
                      if (!context.mounted) return;
                      context.go('/');
                    } else {
                      context.go('/login');
                    }
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: child,
    );
  }
}
