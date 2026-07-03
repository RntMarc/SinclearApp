import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../notifications/services/notification_service.dart';
import '../notifications/widgets/notification_sheet.dart';
import '../../core/di/app_scope.dart';
import '../../core/models/app_update_info.dart';
import '../../core/services/android_update_service.dart';
import '../update/update_dialog.dart';

class MainShell extends StatefulWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  bool _updateChecked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_updateChecked) {
      _updateChecked = true;
      _checkForUpdate();
    }
  }

  Future<void> _checkForUpdate() async {
    developer.log('MainShell._checkForUpdate — kReleaseMode=$kReleaseMode');
    if (!kReleaseMode) return;
    final androidUpdate = AppScope.of(context).androidUpdate;
    developer.log('isSupported=${androidUpdate.isSupported}');
    if (!androidUpdate.isSupported) return;

    AppUpdateInfo? updateInfo;
    try {
      updateInfo = await androidUpdate.checkForUpdate();
    } catch (e) {
      developer.log('Update check threw: $e');
    }

    developer.log('updateInfo=$updateInfo, mounted=$mounted');
    if (!mounted || updateInfo == null) return;

    await UpdateDialog.show(
      context,
      updateInfo: updateInfo,
      onDownload: (dialog) =>
          _downloadAndInstall(dialog, androidUpdate, updateInfo!),
    );
  }

  Future<void> _downloadAndInstall(
    UpdateDialogState dialog,
    AndroidUpdateService service,
    AppUpdateInfo info,
  ) async {
    developer.log('=== Download & Install flow started ===');
    try {
      developer.log('Starting download from ${info.downloadUrl}');
      final filePath = await service.downloadApk(
        info.downloadUrl,
        onProgress: (p) => dialog.setProgress(p),
      );
      developer.log('Download done, filePath=$filePath');

      if (!mounted) {
        developer.log('Widget unmounted before pop, aborting');
        return;
      }

      developer.log('Popping dialog');
      Navigator.pop(context, true);
      await Future<void>.delayed(Duration.zero);

      developer.log('Calling installApk…');
      await service.installApk(filePath);
      developer.log('installApk returned successfully');
    } catch (e) {
      developer.log('ERROR in _downloadAndInstall: $e');
      dialog.setError('Download fehlgeschlagen: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 600;

    if (isDesktop) {
      return _DesktopShell(child: widget.child);
    }
    return _MobileShell(child: widget.child);
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
      appBar: AppBar(title: Text(title), actions: [_NotificationBell()]),
      body: child,
      bottomNavigationBar: _MobileBottomNav(currentLocation: location),
    );
  }
}

String _titleForLocation(String location) {
  if (location.startsWith('/kalender')) return 'KALENDER';
  if (location.startsWith('/entdecken')) return 'ENTDECKEN';
  if (location.startsWith('/reisen')) return 'REISEN & EVENTS';
  if (location.startsWith('/kontakte')) return 'KONTAKTE';
  if (location.startsWith('/einstellungen')) return 'EINSTELLUNGEN';
  if (location.startsWith('/feedback')) return 'FEEDBACK';
  if (location.startsWith('/forum')) return 'FORUM';
  if (location.startsWith('/rezepte')) return 'REZEPTE';
  return 'HOME';
}

// ---------------------------------------------------------------------------
// Mobile Bottom Navigation
// ---------------------------------------------------------------------------

enum _NavCategory { system, gemeinschaft, home, unterwegs, organisation }

_NavCategory _categoryForLocation(String location) {
  if (location.startsWith('/einstellungen') ||
      location.startsWith('/feedback')) {
    return _NavCategory.system;
  }
  if (location.startsWith('/kontakte') ||
      location.startsWith('/forum') ||
      location.startsWith('/rezepte')) {
    return _NavCategory.gemeinschaft;
  }
  if (location.startsWith('/entdecken') || location.startsWith('/reisen')) {
    return _NavCategory.unterwegs;
  }
  if (location.startsWith('/kalender')) return _NavCategory.organisation;
  return _NavCategory.home;
}

class _MobileBottomNav extends StatelessWidget {
  final String currentLocation;

  const _MobileBottomNav({required this.currentLocation});

  @override
  Widget build(BuildContext context) {
    final active = _categoryForLocation(currentLocation);

    return BottomNavigationBar(
      currentIndex: active.index,
      onTap: (index) => _onTap(context, _NavCategory.values[index]),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_rounded),
          label: 'System',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_rounded),
          label: 'Gemeinschaft',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Start'),
        BottomNavigationBarItem(
          icon: Icon(Icons.explore_rounded),
          label: 'Unterwegs',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month_rounded),
          label: 'Organisation',
        ),
      ],
    );
  }

  void _onTap(BuildContext context, _NavCategory category) {
    switch (category) {
      case _NavCategory.home:
        context.go('/home');
      case _NavCategory.system:
        _showCategorySheet(
          context,
          category: 'System',
          items: [
            _SheetItem(
              'Einstellungen',
              Icons.settings_rounded,
              '/einstellungen',
            ),
            _SheetItem('Admin', Icons.admin_panel_settings_rounded, null),
            _SheetItem('Feedback', Icons.feedback_rounded, '/feedback'),
            _SheetItem('Changelog', Icons.history_rounded, null),
          ],
        );
      case _NavCategory.gemeinschaft:
        _showCategorySheet(
          context,
          category: 'Gemeinschaft',
          items: [
            _SheetItem('Forum', Icons.forum_rounded, '/forum'),
            _SheetItem('Kritik', Icons.rate_review_rounded, null),
            _SheetItem('Rezepte', Icons.restaurant_rounded, '/rezepte'),
            _SheetItem('Fotos', Icons.photo_library_rounded, null),
            _SheetItem('Kontakte', Icons.people_rounded, '/kontakte'),
          ],
        );
      case _NavCategory.unterwegs:
        _showCategorySheet(
          context,
          category: 'Unterwegs',
          items: [
            _SheetItem('Entdecken', Icons.explore_rounded, '/entdecken'),
            _SheetItem('Reisen', Icons.flight_rounded, '/reisen'),
          ],
        );
      case _NavCategory.organisation:
        _showCategorySheet(
          context,
          category: 'Organisation',
          items: [
            _SheetItem('Kalender', Icons.calendar_month_rounded, '/kalender'),
            _SheetItem('Umfrage', Icons.poll_rounded, null),
            _SheetItem('Abos', Icons.subscriptions_rounded, null),
          ],
        );
    }
  }

  void _showCategorySheet(
    BuildContext context, {
    required String category,
    required List<_SheetItem> items,
  }) {
    final location = GoRouterState.of(context).matchedLocation;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CategorySheet(
        category: category,
        items: items,
        currentLocation: location,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category Bottom Sheet
// ---------------------------------------------------------------------------

class _SheetItem {
  final String label;
  final IconData icon;
  final String? route;

  const _SheetItem(this.label, this.icon, this.route);
}

class _CategorySheet extends StatelessWidget {
  final String category;
  final List<_SheetItem> items;
  final String currentLocation;

  const _CategorySheet({
    required this.category,
    required this.items,
    required this.currentLocation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            category,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) {
            final isActive =
                item.route != null && currentLocation.startsWith(item.route!);
            final isPlaceholder = item.route == null;

            return ListTile(
              leading: Icon(
                item.icon,
                color: isPlaceholder
                    ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
                    : null,
              ),
              title: Text(
                item.label,
                style: isPlaceholder
                    ? TextStyle(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.4,
                        ),
                      )
                    : null,
              ),
              trailing: isPlaceholder
                  ? Chip(
                      label: const Text('Bald'),
                      visualDensity: VisualDensity.compact,
                      side: BorderSide.none,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      labelStyle: theme.textTheme.labelSmall,
                    )
                  : null,
              selected: isActive,
              selectedTileColor: theme.colorScheme.primaryContainer,
              onTap: isPlaceholder
                  ? null
                  : () {
                      Navigator.pop(context);
                      context.go(item.route!);
                    },
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// Desktop Sidebar Navigation
// ---------------------------------------------------------------------------

class _NavContent extends StatelessWidget {
  final String currentLocation;
  final void Function(String route) onNavigate;

  const _NavContent({required this.currentLocation, required this.onNavigate});

  bool _isActive(String route) => currentLocation.startsWith(route);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.home_rounded),
              title: const Text('Start'),
              selected: _isActive('/home'),
              onTap: () => onNavigate('/home'),
            ),
            _CategoryHeader(title: 'SYSTEM'),
            ListTile(
              leading: const Icon(Icons.settings_rounded),
              title: const Text('Einstellungen'),
              selected: _isActive('/einstellungen'),
              onTap: () => onNavigate('/einstellungen'),
            ),
            ListTile(
              leading: const Icon(Icons.feedback_rounded),
              title: const Text('Feedback'),
              selected: _isActive('/feedback'),
              onTap: () => onNavigate('/feedback'),
            ),
            _CategoryHeader(title: 'GEMEINSCHAFT'),
            ListTile(
              leading: const Icon(Icons.forum_rounded),
              title: const Text('Forum'),
              selected: _isActive('/forum'),
              onTap: () => onNavigate('/forum'),
            ),
            ListTile(
              leading: const Icon(Icons.restaurant_rounded),
              title: const Text('Rezepte'),
              selected: _isActive('/rezepte'),
              onTap: () => onNavigate('/rezepte'),
            ),
            ListTile(
              leading: const Icon(Icons.people_rounded),
              title: const Text('Kontakte'),
              selected: _isActive('/kontakte'),
              onTap: () => onNavigate('/kontakte'),
            ),
            _CategoryHeader(title: 'UNTERWEGS'),
            ListTile(
              leading: const Icon(Icons.explore_rounded),
              title: const Text('Entdecken'),
              selected: _isActive('/entdecken'),
              onTap: () => onNavigate('/entdecken'),
            ),
            ListTile(
              leading: const Icon(Icons.flight_rounded),
              title: const Text('Reisen & Events'),
              selected: _isActive('/reisen'),
              onTap: () => onNavigate('/reisen'),
            ),
            _CategoryHeader(title: 'ORGANISATION'),
            ListTile(
              leading: const Icon(Icons.calendar_month_rounded),
              title: const Text('Kalender'),
              selected: _isActive('/kalender'),
              onTap: () => onNavigate('/kalender'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final String title;
  const _CategoryHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Notification Bell (shared between desktop & mobile)
// ---------------------------------------------------------------------------

class _NotificationBell extends StatefulWidget {
  @override
  State<_NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<_NotificationBell> {
  NotificationService? _notification;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _notification ??= AppScope.of(context).notification;
    _notification!.addListener(_onChange);
  }

  @override
  void dispose() {
    _notification?.removeListener(_onChange);
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
