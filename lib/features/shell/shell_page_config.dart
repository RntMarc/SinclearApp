import 'package:flutter/material.dart';
import '../../design/theme/design_theme.dart';
import '../calendar/screens/calendar_screen.dart';
import '../explore/screens/explore_screen.dart';
import '../feedback/screens/feedback_screen.dart';
import '../forum/screens/forum_list_screen.dart';
import '../home/home_screen.dart';
import '../recipes/screens/recipe_list_screen.dart';
import '../settings/screens/settings_screen.dart';
import '../showcase/screens/design_showcase_screen.dart';
import '../subscription/screens/subscription_list_screen.dart';
import '../travel/screens/travel_screen.dart';
import '../user/screens/contacts_screen.dart';

enum ShellNavCategory { system, gemeinschaft, home, unterwegs, organisation }

class ShellPageEntry {
  final String label;
  final IconData icon;
  final String? route;
  final ShellNavCategory category;
  final bool isPlaceholder;

  const ShellPageEntry({
    required this.label,
    required this.icon,
    this.route,
    required this.category,
    this.isPlaceholder = false,
  });
}

const List<ShellPageEntry> allPages = [
  ShellPageEntry(
    label: 'Design Showcase',
    icon: Icons.palette_rounded,
    route: '/design-showcase',
    category: ShellNavCategory.system,
  ),
  ShellPageEntry(
    label: 'Einstellungen',
    icon: Icons.settings_rounded,
    route: '/einstellungen',
    category: ShellNavCategory.system,
  ),
  ShellPageEntry(
    label: 'Admin',
    icon: Icons.admin_panel_settings_rounded,
    category: ShellNavCategory.system,
    isPlaceholder: true,
  ),
  ShellPageEntry(
    label: 'Feedback',
    icon: Icons.feedback_rounded,
    route: '/feedback',
    category: ShellNavCategory.system,
  ),
  ShellPageEntry(
    label: 'Changelog',
    icon: Icons.history_rounded,
    category: ShellNavCategory.system,
    isPlaceholder: true,
  ),
  ShellPageEntry(
    label: 'Forum',
    icon: Icons.forum_rounded,
    route: '/forum',
    category: ShellNavCategory.gemeinschaft,
  ),
  ShellPageEntry(
    label: 'Kritik',
    icon: Icons.rate_review_rounded,
    category: ShellNavCategory.gemeinschaft,
    isPlaceholder: true,
  ),
  ShellPageEntry(
    label: 'Rezepte',
    icon: Icons.restaurant_rounded,
    route: '/rezepte',
    category: ShellNavCategory.gemeinschaft,
  ),
  ShellPageEntry(
    label: 'Fotos',
    icon: Icons.photo_library_rounded,
    category: ShellNavCategory.gemeinschaft,
    isPlaceholder: true,
  ),
  ShellPageEntry(
    label: 'Kontakte',
    icon: Icons.people_rounded,
    route: '/kontakte',
    category: ShellNavCategory.gemeinschaft,
  ),
  ShellPageEntry(
    label: 'Home',
    icon: Icons.home_rounded,
    route: '/home',
    category: ShellNavCategory.home,
  ),
  ShellPageEntry(
    label: 'Entdecken',
    icon: Icons.explore_rounded,
    route: '/entdecken',
    category: ShellNavCategory.unterwegs,
  ),
  ShellPageEntry(
    label: 'Reisen',
    icon: Icons.flight_rounded,
    route: '/reisen',
    category: ShellNavCategory.unterwegs,
  ),
  ShellPageEntry(
    label: 'Kalender',
    icon: Icons.calendar_month_rounded,
    route: '/kalender',
    category: ShellNavCategory.organisation,
  ),
  ShellPageEntry(
    label: 'Umfrage',
    icon: Icons.poll_rounded,
    category: ShellNavCategory.organisation,
    isPlaceholder: true,
  ),
  ShellPageEntry(
    label: 'Abos',
    icon: Icons.subscriptions_rounded,
    route: '/abos',
    category: ShellNavCategory.organisation,
  ),
];

List<int> indicesForCategory(ShellNavCategory category) => [
  for (var i = 0; i < allPages.length; i++)
    if (allPages[i].category == category) i,
];

Map<ShellNavCategory, List<int>> pagesByCategory() => {
  for (final cat in ShellNavCategory.values) cat: indicesForCategory(cat),
};

ShellNavCategory categoryForPageIndex(int index) => allPages[index].category;

int? pageIndexForLocation(String location) {
  for (var i = 0; i < allPages.length; i++) {
    final route = allPages[i].route;
    if (route == null) continue;
    if (location == route || location.startsWith('$route/')) return i;
  }
  return null;
}

bool isExactRootLocation(String location) {
  for (final page in allPages) {
    if (page.route == location) return true;
  }
  return false;
}

int firstPageInCategory(ShellNavCategory category) =>
    allPages.indexWhere((p) => p.category == category);

String shellTitleForPageIndex(int index) => allPages[index].label;

Widget buildPageForIndex(int index) {
  final entry = allPages[index];
  if (entry.isPlaceholder) {
    return _PlaceholderPage(entry: entry);
  }
  return switch (index) {
    0 => const DesignShowcaseScreen(),
    1 => const SettingsScreen(),
    3 => const FeedbackScreen(),
    5 => const ForumListScreen(),
    7 => const RecipeListScreen(),
    9 => const ContactsScreen(),
    10 => const HomeScreen(),
    11 => const ExploreScreen(),
    12 => const TravelScreen(),
    13 => const CalendarScreen(),
    15 => const SubscriptionListScreen(),
    _ => const SizedBox.shrink(),
  };
}

class _PlaceholderPage extends StatelessWidget {
  final ShellPageEntry entry;
  const _PlaceholderPage({required this.entry});

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            entry.icon,
            size: 64,
            color: tokens.textLow.withValues(alpha: 0.4),
          ),
          SizedBox(height: tokens.spaceMd),
          Text(
            entry.label,
            style: tokens.titleStyle(tokens.textLow.withValues(alpha: 0.4)),
          ),
          SizedBox(height: tokens.spaceSm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: tokens.textLow.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(tokens.radiusPill),
            ),
            child: Text(
              'Bald verfügbar',
              style: tokens.labelStyle(tokens.textLow.withValues(alpha: 0.5)),
            ),
          ),
        ],
      ),
    );
  }
}
