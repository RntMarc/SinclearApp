import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design/beyond.dart';
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
  bool _standortWarningShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_updateChecked) {
      _updateChecked = true;
      _checkForUpdate();
    }
    if (!_standortWarningShown) {
      final location = GoRouterState.of(context).matchedLocation;
      if (location.startsWith('/standort-teilen')) {
        _standortWarningShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Hinweis: Standort-Teilen befindet sich noch in der '
                  'Entwicklung. Die Funktion ist noch nicht vollständig '
                  'funktionsfähig.',
                ),
                duration: const Duration(seconds: 10),
              ),
            );
          }
        });
      }
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
      backgroundColor: Colors.transparent,
      appBar: BeyondAppBar(
        titleText: _titleForLocation(location),
        actions: const <Widget>[_NotificationBell()],
      ),
      body: BeyondSurface(
        child: Row(
          children: <Widget>[
            BeyondSidebar(
              children: <Widget>[
                const BeyondSidebarBrand(),
                BeyondNavItem(
                  icon: Icons.home_rounded,
                  label: 'Start',
                  selected: _isActive(location, '/home'),
                  onTap: () => context.go('/home'),
                ),
                const BeyondCategoryHeader(title: 'SYSTEM'),
                BeyondNavItem(
                  icon: Icons.settings_rounded,
                  label: 'Einstellungen',
                  selected: _isActive(location, '/einstellungen'),
                  onTap: () => context.go('/einstellungen'),
                ),
                BeyondNavItem(
                  icon: Icons.feedback_rounded,
                  label: 'Feedback',
                  selected: _isActive(location, '/feedback'),
                  onTap: () => context.go('/feedback'),
                ),
                const BeyondCategoryHeader(title: 'GEMEINSCHAFT'),
                BeyondNavItem(
                  icon: Icons.forum_rounded,
                  label: 'Forum',
                  selected: _isActive(location, '/forum'),
                  onTap: () => context.go('/forum'),
                ),
                BeyondNavItem(
                  icon: Icons.restaurant_rounded,
                  label: 'Rezepte',
                  selected: _isActive(location, '/rezepte'),
                  onTap: () => context.go('/rezepte'),
                ),
                BeyondNavItem(
                  icon: Icons.people_rounded,
                  label: 'Kontakte',
                  selected: _isActive(location, '/kontakte'),
                  onTap: () => context.go('/kontakte'),
                ),
                const BeyondCategoryHeader(title: 'UNTERWEGS'),
                BeyondNavItem(
                  icon: Icons.explore_rounded,
                  label: 'Entdecken',
                  selected: _isActive(location, '/entdecken'),
                  onTap: () => context.go('/entdecken'),
                ),
                BeyondNavItem(
                  icon: Icons.flight_rounded,
                  label: 'Reisen & Events',
                  selected: _isActive(location, '/reisen'),
                  onTap: () => context.go('/reisen'),
                ),
                BeyondNavItem(
                  icon: Icons.share_location_rounded,
                  label: 'Standort teilen',
                  trailing: const BeyondChip(label: 'Bald'),
                  selected: _isActive(location, '/standort-teilen'),
                  onTap: () => context.go('/standort-teilen'),
                ),
                const BeyondCategoryHeader(title: 'ORGANISATION'),
                BeyondNavItem(
                  icon: Icons.calendar_month_rounded,
                  label: 'Kalender',
                  selected: _isActive(location, '/kalender'),
                  onTap: () => context.go('/kalender'),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
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
    final active = _categoryForLocation(location);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: BeyondAppBar(
        titleText: title,
        actions: const <Widget>[_NotificationBell()],
      ),
      body: BeyondSurface(child: child),
      bottomNavigationBar: BeyondBottomNav(
        destinations: <BeyondNavDestination>[
          BeyondNavDestination(
            icon: Icons.settings_rounded,
            label: 'System',
            active: active == _NavCategory.system,
            onTap: () => _onTap(context, _NavCategory.system),
          ),
          BeyondNavDestination(
            icon: Icons.people_rounded,
            label: 'Gemeinschaft',
            active: active == _NavCategory.gemeinschaft,
            onTap: () => _onTap(context, _NavCategory.gemeinschaft),
          ),
          BeyondNavDestination(
            icon: Icons.home_rounded,
            label: 'Start',
            active: active == _NavCategory.home,
            onTap: () => _onTap(context, _NavCategory.home),
          ),
          BeyondNavDestination(
            icon: Icons.explore_rounded,
            label: 'Unterwegs',
            active: active == _NavCategory.unterwegs,
            onTap: () => _onTap(context, _NavCategory.unterwegs),
          ),
          BeyondNavDestination(
            icon: Icons.calendar_month_rounded,
            label: 'Organisation',
            active: active == _NavCategory.organisation,
            onTap: () => _onTap(context, _NavCategory.organisation),
          ),
        ],
      ),
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
  if (location.startsWith('/standort-teilen')) return 'STANDORT TEILEN ∝';
  return 'HOME';
}

bool _isActive(String location, String route) =>
    location.startsWith(route);

// ---------------------------------------------------------------------------
// Mobile category navigation
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
  if (location.startsWith('/entdecken') ||
      location.startsWith('/reisen') ||
      location.startsWith('/standort-teilen')) {
    return _NavCategory.unterwegs;
  }
  if (location.startsWith('/kalender')) return _NavCategory.organisation;
  return _NavCategory.home;
}

class _SheetItem {
  final String label;
  final IconData icon;
  final String? route;
  final bool comingSoon;

  const _SheetItem(
    this.label,
    this.icon,
    this.route, {
    this.comingSoon = false,
  });
}

void _onTap(BuildContext context, _NavCategory category) {
  switch (category) {
    case _NavCategory.home:
      context.go('/home');
    case _NavCategory.system:
      _showCategorySheet(
        context,
        category: 'System',
        items: <_SheetItem>[
          _SheetItem('Einstellungen', Icons.settings_rounded, '/einstellungen'),
          _SheetItem('Admin', Icons.admin_panel_settings_rounded, null),
          _SheetItem('Feedback', Icons.feedback_rounded, '/feedback'),
          _SheetItem('Changelog', Icons.history_rounded, null),
        ],
      );
    case _NavCategory.gemeinschaft:
      _showCategorySheet(
        context,
        category: 'Gemeinschaft',
        items: <_SheetItem>[
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
        items: <_SheetItem>[
          _SheetItem('Entdecken', Icons.explore_rounded, '/entdecken'),
          _SheetItem('Reisen', Icons.flight_rounded, '/reisen'),
          _SheetItem(
            'Standort teilen',
            Icons.share_location_rounded,
            '/standort-teilen',
            comingSoon: true,
          ),
        ],
      );
    case _NavCategory.organisation:
      _showCategorySheet(
        context,
        category: 'Organisation',
        items: <_SheetItem>[
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

  BeyondSheet.show(
    context: context,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        BeyondHeadline(category),
        const SizedBox(height: 8),
        ...items.map((item) {
          final isPlaceholder = item.route == null;
          final isActive = item.route != null &&
              location.startsWith(item.route!);

          return BeyondNavItem(
            icon: item.icon,
            label: item.label,
            selected: isActive,
            trailing: isPlaceholder || item.comingSoon
                ? const BeyondChip(label: 'Bald')
                : null,
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

// ---------------------------------------------------------------------------
// Notification bell (shared between desktop & mobile)
// ---------------------------------------------------------------------------

class _NotificationBell extends StatefulWidget {
  const _NotificationBell();

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
      onPressed: () => BeyondSheet.show(
        context: context,
        child: const NotificationSheet(),
      ),
    );
  }
}
