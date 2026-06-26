import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../notifications/services/notification_service.dart';
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

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_titleForLocation(location)),
        trailing: const _NotificationBell(),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 288,
            child: _NavContent(
              currentLocation: location,
              onNavigate: (route) => context.go(route),
            ),
          ),
          Container(width: 1, color: CupertinoColors.systemGrey4),
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
    final active = _categoryForLocation(location);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(title),
        trailing: const _NotificationBell(),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(child: child),
            _MobileBottomNav(currentLocation: location, currentIndex: active.index),
          ],
        ),
      ),
    );
  }
}

String _titleForLocation(String location) {
  if (location.startsWith('/kalender')) return 'Kalender';
  if (location.startsWith('/entdecken')) return 'Entdecken';
  if (location.startsWith('/reisen')) return 'Reisen & Events';
  if (location.startsWith('/kontakte')) return 'Kontakte';
  if (location.startsWith('/einstellungen')) return 'Einstellungen';
  return 'Home';
}

// ---------------------------------------------------------------------------
// Mobile Bottom Navigation
// ---------------------------------------------------------------------------

enum _NavCategory { system, gemeinschaft, home, unterwegs, organisation }

_NavCategory _categoryForLocation(String location) {
  if (location.startsWith('/einstellungen')) return _NavCategory.system;
  if (location.startsWith('/kontakte')) return _NavCategory.gemeinschaft;
  if (location.startsWith('/entdecken') || location.startsWith('/reisen')) {
    return _NavCategory.unterwegs;
  }
  if (location.startsWith('/kalender')) return _NavCategory.organisation;
  return _NavCategory.home;
}

class _MobileBottomNav extends StatelessWidget {
  final String currentLocation;
  final int currentIndex;

  const _MobileBottomNav({required this.currentLocation, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabBar(
      currentIndex: currentIndex,
      onTap: (index) => _onTap(context, _NavCategory.values[index]),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.gear_alt_fill),
          label: 'System',
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.person_2_fill),
          label: 'Gemeinschaft',
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.house_fill),
          label: 'Start',
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.compass),
          label: 'Unterwegs',
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.calendar),
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
        _showCategorySheet(context, category: 'System', items: [
          _SheetItem('Einstellungen', CupertinoIcons.gear_alt_fill, '/einstellungen'),
          _SheetItem('Admin', CupertinoIcons.shield_lefthalf_fill, null),
          _SheetItem('Feedback', CupertinoIcons.chat_bubble_text_fill, null),
          _SheetItem('Changelog', CupertinoIcons.clock_fill, null),
        ]);
      case _NavCategory.gemeinschaft:
        _showCategorySheet(context, category: 'Gemeinschaft', items: [
          _SheetItem('Forum', CupertinoIcons.bubble_left_bubble_right_fill, null),
          _SheetItem('Kritik', CupertinoIcons.pencil_circle_fill, null),
          _SheetItem('Rezepte', CupertinoIcons.book_fill, null),
          _SheetItem('Fotos', CupertinoIcons.photo_fill, null),
          _SheetItem('Kontakte', CupertinoIcons.person_2_fill, '/kontakte'),
        ]);
      case _NavCategory.unterwegs:
        _showCategorySheet(context, category: 'Unterwegs', items: [
          _SheetItem('Entdecken', CupertinoIcons.compass, '/entdecken'),
          _SheetItem('Reisen', CupertinoIcons.airplane, '/reisen'),
        ]);
      case _NavCategory.organisation:
        _showCategorySheet(context, category: 'Organisation', items: [
          _SheetItem('Kalender', CupertinoIcons.calendar, '/kalender'),
          _SheetItem('Umfrage', CupertinoIcons.chart_bar_fill, null),
          _SheetItem('Abos', CupertinoIcons.music_note_list, null),
        ]);
    }
  }

  void _showCategorySheet(
    BuildContext context, {
    required String category,
    required List<_SheetItem> items,
  }) {
    final location = GoRouterState.of(context).matchedLocation;

    showCupertinoModalPopup<void>(
      context: context,
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
    final theme = CupertinoTheme.of(context);

    return CupertinoActionSheet(
      title: Text(
        category,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      actions: items.map((item) {
        final isActive =
            item.route != null && currentLocation.startsWith(item.route!);
        final isPlaceholder = item.route == null;

        return CupertinoActionSheetAction(
          onPressed: isPlaceholder
              ? () => Navigator.pop(context)
              : () {
                  Navigator.pop(context);
                  context.go(item.route!);
                },
          child: Row(
            children: [
              Icon(
                item.icon,
                color: isPlaceholder
                    ? theme.textTheme.textStyle.color?.withValues(alpha: 0.3)
                    : theme.primaryColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: isPlaceholder
                        ? theme.textTheme.textStyle.color?.withValues(alpha: 0.3)
                        : null,
                  ),
                ),
              ),
              if (isActive)
                Icon(CupertinoIcons.check_mark, color: theme.primaryColor),
              if (isPlaceholder)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey5,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Bald',
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
      cancelButton: CupertinoActionSheetAction(
        isDefaultAction: true,
        onPressed: () => Navigator.pop(context),
        child: const Text('Abbrechen'),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop Sidebar Navigation (unchanged)
// ---------------------------------------------------------------------------

class _NavContent extends StatelessWidget {
  final String currentLocation;
  final void Function(String route) onNavigate;

  const _NavContent({required this.currentLocation, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final selectedIndex = _selectedIndex(currentLocation);

    return SafeArea(
      child: SingleChildScrollView(
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.textStyle.color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _SidebarTile(
              icon: CupertinoIcons.house_fill,
              label: 'Home',
              selected: selectedIndex == 0,
              onTap: () => onNavigate('/home'),
            ),
            _SidebarTile(
              icon: CupertinoIcons.calendar,
              label: 'Kalender',
              selected: selectedIndex == 1,
              onTap: () => onNavigate('/kalender'),
            ),
            _SidebarTile(
              icon: CupertinoIcons.compass,
              label: 'Entdecken',
              selected: selectedIndex == 2,
              onTap: () => onNavigate('/entdecken'),
            ),
            _SidebarTile(
              icon: CupertinoIcons.airplane,
              label: 'Reisen & Events',
              selected: selectedIndex == 3,
              onTap: () => onNavigate('/reisen'),
            ),
            _SidebarTile(
              icon: CupertinoIcons.person_2_fill,
              label: 'Kontakte',
              selected: selectedIndex == 4,
              onTap: () => onNavigate('/kontakte'),
            ),
            _SidebarTile(
              icon: CupertinoIcons.gear_alt_fill,
              label: 'Einstellungen',
              selected: selectedIndex == 5,
              onTap: () => onNavigate('/einstellungen'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  int _selectedIndex(String location) {
    if (location.startsWith('/kalender')) return 1;
    if (location.startsWith('/entdecken')) return 2;
    if (location.startsWith('/reisen')) return 3;
    if (location.startsWith('/kontakte')) return 4;
    if (location.startsWith('/einstellungen')) return 5;
    return 0;
  }
}

class _SidebarTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? theme.primaryColor.withValues(alpha: 0.12)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: selected
                  ? theme.primaryColor
                  : theme.textTheme.textStyle.color,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected
                    ? theme.primaryColor
                    : theme.textTheme.textStyle.color,
              ),
            ),
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
    return GestureDetector(
      onTap: () => _showSheet(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            notif.unreadCount > 0
                ? CupertinoIcons.bell_fill
                : CupertinoIcons.bell,
            size: 22,
            color: CupertinoTheme.of(context).primaryColor,
          ),
          if (notif.unreadCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: CupertinoColors.destructiveRed,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  notif.unreadCount > 99
                      ? '99+'
                      : notif.unreadCount.toString(),
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showSheet(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => const NotificationSheet(),
    );
  }
}
