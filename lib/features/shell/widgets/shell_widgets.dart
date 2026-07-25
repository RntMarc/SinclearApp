import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/app_scope.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../notifications/services/notification_service.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/composite/design_app_bar.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../../design/widgets/primitives/design_badge.dart';
import '../../../design/widgets/primitives/press_scale.dart';
import '../../notifications/widgets/notification_sheet.dart';
import '../shell_page_config.dart';
import 'shell_sub_page_nav.dart';

String shellTitleForLocation(String location) {
  if (location.startsWith('/kalender')) return 'KALENDER';
  if (location.startsWith('/entdecken')) return 'ENTDECKEN';
  if (location.startsWith('/reisen')) return 'REISEN & EVENTS';
  if (location.startsWith('/kontakte')) return 'KONTAKTE';
  if (location.startsWith('/einstellungen')) return 'EINSTELLUNGEN';
  if (location.startsWith('/feedback')) return 'FEEDBACK';
  if (location.startsWith('/forum')) return 'FORUM';
  if (location.startsWith('/rezepte')) return 'REZEPTE';
  if (location.startsWith('/abos')) return 'ABOS';
  if (location.startsWith('/design-showcase')) return 'DESIGN SHOWCASE';
  return 'HOME';
}

// ---------------------------------------------------------------------------
// Desktop Sidebar Navigation
// ---------------------------------------------------------------------------

class ShellNavContent extends StatelessWidget {
  final String currentLocation;
  final void Function(String route) onNavigate;

  const ShellNavContent({
    super.key,
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
            _header(context, 'ORGANISATION'),
            _tile(
              context,
              icon: Icons.calendar_month_rounded,
              label: 'Kalender',
              active: _isActive('/kalender'),
              onTap: () => onNavigate('/kalender'),
            ),
            _tile(
              context,
              icon: Icons.subscriptions_rounded,
              label: 'Abos',
              active: _isActive('/abos'),
              onTap: () => onNavigate('/abos'),
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
              child: DesignText(label, style: DesignTextStyle.body, color: fg),
            ),
            trailing ?? const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop Shell
// ---------------------------------------------------------------------------

class ShellDesktop extends StatelessWidget {
  final Widget child;

  const ShellDesktop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final location = GoRouterState.of(context).matchedLocation;

    return DesignSurface(
      child: Column(
        children: [
          DesignAppBar(
            title: shellTitleForLocation(location),
            actions: const [ShellNotificationBell()],
          ),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 288,
                  child: ShellNavContent(
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

// ---------------------------------------------------------------------------
// Mobile Shell
// ---------------------------------------------------------------------------

class ShellMobile extends StatefulWidget {
  final Widget child;

  const ShellMobile({super.key, required this.child});

  @override
  State<ShellMobile> createState() => _ShellMobileState();
}

class _ShellMobileState extends State<ShellMobile> {
  late PageController _pageController;
  int _currentPageIndex = 0;
  String _lastLocation = '';
  bool _initialized = false;

  int get _pvCount => allPages.length + 2;

  int _realIndex(int pvIndex) {
    final n = allPages.length;
    if (pvIndex == 0) return n - 1;
    if (pvIndex == n + 1) return 0;
    return pvIndex - 1;
  }

  int _pvIndex(int realIndex) => realIndex + 1;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final location = GoRouterState.of(context).matchedLocation;
      _currentPageIndex = pageIndexForLocation(location) ?? 0;
      _lastLocation = location;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _pageController.jumpToPage(_pvIndex(_currentPageIndex));
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _syncPageWithRoute() {
    final location = GoRouterState.of(context).matchedLocation;
    if (location == _lastLocation) return;
    _lastLocation = location;
    final idx = pageIndexForLocation(location);
    if (idx != null && idx != _currentPageIndex) {
      _currentPageIndex = idx;
      _pageController.jumpToPage(_pvIndex(idx));
    }
  }

  @override
  Widget build(BuildContext context) {
    _syncPageWithRoute();

    final location = GoRouterState.of(context).matchedLocation;
    final pageIdx = pageIndexForLocation(location);
    final isRoot = pageIdx != null && isExactRootLocation(location);
    final activeCategory = pageIdx != null
        ? categoryForPageIndex(pageIdx)
        : ShellNavCategory.home;
    final activePage = pageIdx ?? _currentPageIndex;

    return DesignSurface(
      child: Column(
        children: [
          DesignAppBar(
            title: isRoot
                ? shellTitleForPageIndex(activePage)
                : shellTitleForLocation(location),
            actions: const [ShellNotificationBell()],
          ),
          Expanded(
            child: isRoot
                ? PageView.builder(
                    controller: _pageController,
                    itemCount: _pvCount,
                    itemBuilder: (context, pvIndex) =>
                        buildPageForIndex(_realIndex(pvIndex)),
                    onPageChanged: (pvIndex) {
                      final n = allPages.length;
                      if (pvIndex == 0) {
                        _pageController.jumpToPage(n);
                        return;
                      }
                      if (pvIndex == n + 1) {
                        _pageController.jumpToPage(1);
                        return;
                      }
                      final real = pvIndex - 1;
                      setState(() => _currentPageIndex = real);
                      final route = allPages[real].route;
                      if (route != null) context.go(route);
                    },
                  )
                : widget.child,
          ),
          ShellSubPageNav(
            category: activeCategory,
            activePageIndex: activePage,
            onPageTap: (index) {
              final route = allPages[index].route;
              if (route != null) context.go(route);
            },
          ),
          ShellMobileBottomNav(currentLocation: location),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mobile Bottom Navigation
// ---------------------------------------------------------------------------

class ShellMobileBottomNav extends StatelessWidget {
  final String currentLocation;

  const ShellMobileBottomNav({super.key, required this.currentLocation});

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final pageIdx = pageIndexForLocation(currentLocation);
    final active = pageIdx != null
        ? categoryForPageIndex(pageIdx)
        : ShellNavCategory.home;

    final items = <({IconData icon, String label, ShellNavCategory category})>[
      (
        icon: Icons.settings_rounded,
        label: 'System',
        category: ShellNavCategory.system,
      ),
      (
        icon: Icons.people_rounded,
        label: 'Gemeinschaft',
        category: ShellNavCategory.gemeinschaft,
      ),
      (
        icon: Icons.home_rounded,
        label: 'Start',
        category: ShellNavCategory.home,
      ),
      (
        icon: Icons.explore_rounded,
        label: 'Unterwegs',
        category: ShellNavCategory.unterwegs,
      ),
      (
        icon: Icons.calendar_month_rounded,
        label: 'Organisation',
        category: ShellNavCategory.organisation,
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
                      const SizedBox(height: 4),
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

  void _onTap(BuildContext context, ShellNavCategory category) {
    final index = firstPageInCategory(category);
    final route = allPages[index].route;
    if (route != null) context.go(route);
  }
}

// ---------------------------------------------------------------------------
// Notification Bell
// ---------------------------------------------------------------------------

class ShellNotificationBell extends StatefulWidget {
  const ShellNotificationBell({super.key});

  @override
  State<ShellNotificationBell> createState() => _ShellNotificationBellState();
}

class _ShellNotificationBellState extends State<ShellNotificationBell> {
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
            child: DesignBadge(label: unread > 99 ? '99+' : unread.toString()),
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
