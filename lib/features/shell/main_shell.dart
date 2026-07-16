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
import '../../design/theme/design_theme.dart';
import '../../design/widgets/foundation/design_surface.dart';
import '../../design/widgets/foundation/design_text.dart';
import '../../design/widgets/composite/design_app_bar.dart';
import '../../design/widgets/composite/design_bottom_sheet.dart';
import '../../design/widgets/composite/design_list_tile.dart';
import '../../design/widgets/primitives/design_icon_button.dart';
import '../../design/widgets/primitives/design_badge.dart';
import '../../design/widgets/primitives/press_scale.dart';

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
    final tokens = DesignTheme.of(context);
    final location = GoRouterState.of(context).matchedLocation;

    return DesignSurface(
      child: Column(
        children: [
          DesignAppBar(
            title: _titleForLocation(location),
            actions: [_NotificationBell()],
          ),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 288,
                  child: _NavContent(
                    currentLocation: location,
                    onNavigate: (route) => context.go(route),
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: tokens.border.withValues(alpha: 0.6),
                ),
                Expanded(child: child),
              ],
            ),
          ),
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

    return DesignSurface(
      child: Column(
        children: [
          DesignAppBar(title: title, actions: [_NotificationBell()]),
          Expanded(child: child),
          _MobileBottomNav(currentLocation: location),
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
  if (location.startsWith('/design-showcase')) return 'DESIGN SHOWCASE';
  if (location.startsWith('/standort-teilen')) return 'STANDORT TEILEN ∝';
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
  if (location.startsWith('/entdecken') ||
      location.startsWith('/reisen') ||
      location.startsWith('/standort-teilen')) {
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
    final tokens = DesignTheme.of(context);
    final active = _categoryForLocation(currentLocation);

    final items = <({IconData icon, String label, _NavCategory category})>[
      (
        icon: Icons.settings_rounded,
        label: 'System',
        category: _NavCategory.system,
      ),
      (
        icon: Icons.people_rounded,
        label: 'Gemeinschaft',
        category: _NavCategory.gemeinschaft,
      ),
      (
        icon: Icons.home_rounded,
        label: 'Start',
        category: _NavCategory.home,
      ),
      (
        icon: Icons.explore_rounded,
        label: 'Unterwegs',
        category: _NavCategory.unterwegs,
      ),
      (
        icon: Icons.calendar_month_rounded,
        label: 'Organisation',
        category: _NavCategory.organisation,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(
          top: BorderSide(
            color: tokens.border.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: tokens.spaceXs,
            horizontal: tokens.spaceSm,
          ),
          child: Row(
            children: items.map((item) {
              final isActive = item.category == active;
              final fg = isActive ? tokens.primary : tokens.textLow;
              return Expanded(
                child: PressScale(
                  onTap: () => _onTap(context, item.category),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.icon, color: fg, size: 24),
                      SizedBox(height: 4),
                      Text(
                        item.label,
                        style: tokens.labelStyle(fg).copyWith(fontSize: 11),
                        maxLines: 1,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
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
              'Design Showcase',
              Icons.palette_rounded,
              '/design-showcase',
            ),
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
          items: [
            _SheetItem(
              'Kalender',
              Icons.calendar_month_rounded,
              '/kalender',
            ),
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
    showDesignSheet(
      context: context,
      child: _CategorySheet(
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
  final bool comingSoon;

  const _SheetItem(
    this.label,
    this.icon,
    this.route, {
    this.comingSoon = false,
  });
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
    final tokens = DesignTheme.of(context);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DesignText(
            category,
            style: DesignTextStyle.subtitle,
            color: tokens.textHigh,
          ),
          SizedBox(height: tokens.spaceMd),
          ...items.map((item) {
            final isActive =
                item.route != null && currentLocation.startsWith(item.route!);
            final isPlaceholder = item.route == null;
            final showBadge = isPlaceholder || item.comingSoon;

            return Opacity(
              opacity: isPlaceholder ? 0.45 : 1.0,
              child: DesignListTile(
                leading: Icon(
                  item.icon,
                  color: isPlaceholder ? tokens.textLow : tokens.textHigh,
                ),
                title: item.label,
                onTap: isPlaceholder
                    ? null
                    : () {
                        Navigator.pop(context);
                        context.go(item.route!);
                      },
                trailing: showBadge
                    ? DesignBadge(label: 'Bald')
                    : isActive
                        ? DesignBadge(
                            label: 'Aktiv',
                            color: tokens.primary,
                          )
                        : null,
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.spaceMd,
                  vertical: tokens.spaceSm,
                ),
              ),
            );
          }),
          SizedBox(height: tokens.spaceMd),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop Sidebar Navigation
// ---------------------------------------------------------------------------

class _NavContent extends StatelessWidget {
  final String currentLocation;
  final void Function(String route) onNavigate;

  const _NavContent({
    required this.currentLocation,
    required this.onNavigate,
  });

  bool _isActive(String route) => currentLocation.startsWith(route);

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                tokens.spaceLg,
                tokens.spaceLg,
                tokens.spaceLg,
                tokens.spaceMd,
              ),
              child: Row(
                children: [
                  Image.asset('assets/logo.png', width: 32, height: 32),
                  SizedBox(width: tokens.spaceMd),
                  DesignText(
                    'Beyond',
                    style: DesignTextStyle.subtitle,
                    color: tokens.textHigh,
                  ),
                ],
              ),
            ),
            _tile(
              context,
              icon: Icons.home_rounded,
              label: 'Start',
              active: _isActive('/home'),
              onTap: () => onNavigate('/home'),
            ),
            _tile(
              context,
              icon: Icons.palette_rounded,
              label: 'Design Showcase',
              active: _isActive('/design-showcase'),
              onTap: () => onNavigate('/design-showcase'),
            ),
            _header(context, 'SYSTEM'),
            _tile(
              context,
              icon: Icons.settings_rounded,
              label: 'Einstellungen',
              active: _isActive('/einstellungen'),
              onTap: () => onNavigate('/einstellungen'),
            ),
            _tile(
              context,
              icon: Icons.feedback_rounded,
              label: 'Feedback',
              active: _isActive('/feedback'),
              onTap: () => onNavigate('/feedback'),
            ),
            _header(context, 'GEMEINSCHAFT'),
            _tile(
              context,
              icon: Icons.forum_rounded,
              label: 'Forum',
              active: _isActive('/forum'),
              onTap: () => onNavigate('/forum'),
            ),
            _tile(
              context,
              icon: Icons.restaurant_rounded,
              label: 'Rezepte',
              active: _isActive('/rezepte'),
              onTap: () => onNavigate('/rezepte'),
            ),
            _tile(
              context,
              icon: Icons.people_rounded,
              label: 'Kontakte',
              active: _isActive('/kontakte'),
              onTap: () => onNavigate('/kontakte'),
            ),
            _header(context, 'UNTERWEGS'),
            _tile(
              context,
              icon: Icons.explore_rounded,
              label: 'Entdecken',
              active: _isActive('/entdecken'),
              onTap: () => onNavigate('/entdecken'),
            ),
            _tile(
              context,
              icon: Icons.flight_rounded,
              label: 'Reisen & Events',
              active: _isActive('/reisen'),
              onTap: () => onNavigate('/reisen'),
            ),
            _tile(
              context,
              icon: Icons.share_location_rounded,
              label: 'Standort teilen',
              active: _isActive('/standort-teilen'),
              onTap: () => onNavigate('/standort-teilen'),
              trailing: DesignBadge(label: 'Bald'),
            ),
            _header(context, 'ORGANISATION'),
            _tile(
              context,
              icon: Icons.calendar_month_rounded,
              label: 'Kalender',
              active: _isActive('/kalender'),
              onTap: () => onNavigate('/kalender'),
            ),
            SizedBox(height: tokens.spaceMd),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, String title) {
    final tokens = DesignTheme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLg,
        tokens.spaceLg,
        tokens.spaceLg,
        tokens.spaceXs,
      ),
      child: DesignText(
        title,
        style: DesignTextStyle.label,
        color: tokens.primary,
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback? onTap,
    Widget? trailing,
  }) {
    final tokens = DesignTheme.of(context);
    final enabled = onTap != null;
    final fg = active
        ? tokens.primary
        : enabled
            ? tokens.textLow
            : tokens.textLow.withValues(alpha: 0.4);

    return PressScale(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: tokens.spaceMd,
          vertical: tokens.spaceXs,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceMd,
          vertical: tokens.spaceSm,
        ),
        decoration: BoxDecoration(
          color: active ? tokens.surfaceVariant : Colors.transparent,
          borderRadius: BorderRadius.circular(tokens.radiusMd),
        ),
        child: Row(
          children: [
            Icon(icon, color: fg, size: 22),
            SizedBox(width: tokens.spaceMd),
            Expanded(
              child: DesignText(
                label,
                style: DesignTextStyle.body,
                color: fg,
              ),
            ),
            trailing ?? const SizedBox.shrink(),
          ],
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
    final unread = notif.unreadCount;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        DesignIconButton(
          icon: unread > 0
              ? Icons.notifications_rounded
              : Icons.notifications_outlined,
          onPressed: () => _showSheet(context),
        ),
        if (unread > 0)
          Positioned(
            top: 2,
            right: 2,
            child: DesignBadge(
              label: unread > 99 ? '99+' : unread.toString(),
            ),
          ),
      ],
    );
  }

  void _showSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NotificationSheet(),
    );
  }
}
