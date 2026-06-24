import 'package:go_router/go_router.dart';
import '../features/auth/services/auth_service.dart';
import '../features/welcome/welcome_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/verify_screen.dart';
import '../features/home/home_screen.dart';
import '../features/explore/screens/explore_screen.dart';
import '../features/explore/screens/category_screen.dart';
import '../features/explore/screens/detail_screen.dart';
import '../features/explore/screens/create_place_screen.dart';

import '../features/shell/main_shell.dart';
import '../features/travel/screens/travel_screen.dart';
import '../features/travel/screens/trip_detail_screen.dart';
import '../features/user/screens/contacts_screen.dart';
import '../features/user/screens/user_detail_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/settings/screens/edit_profile_screen.dart';
import '../features/settings/screens/edit_social_screen.dart';
import '../features/settings/screens/edit_contact_screen.dart';
import '../features/settings/screens/email_change_screen.dart';
import '../features/settings/screens/discord_relink_screen.dart';

GoRouter createRouter(AuthService auth) {
  return GoRouter(
    refreshListenable: auth,
    initialLocation: '/',
    redirect: (context, state) {
      final loggedIn = auth.isLoggedIn;
      final location = state.matchedLocation;

      final isAuth =
          location.startsWith('/home') ||
          location.startsWith('/entdecken') ||
          location.startsWith('/reisen') ||
          location.startsWith('/kontakte') ||
          location.startsWith('/einstellungen');

      if (loggedIn && location == '/') return '/home';
      if (!loggedIn && isAuth) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/login/verify',
        builder: (context, state) => const VerifyScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/reisen',
            builder: (context, state) => const TravelScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    TripDetailScreen(id: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/entdecken',
            builder: (context, state) => const ExploreScreen(),
            routes: [
              GoRoute(
                path: 'gastronomie',
                builder: (context, state) =>
                    const CategoryScreen(category: 'gastronomy'),
              ),
              GoRoute(
                path: 'freizeit',
                builder: (context, state) =>
                    const CategoryScreen(category: 'leisure'),
              ),
              GoRoute(
                path: 'neu',
                builder: (context, state) => const CreatePlaceScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    DetailScreen(id: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/kontakte',
            builder: (context, state) => const ContactsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    UserDetailScreen(id: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/einstellungen',
            builder: (context, state) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: 'profil',
                builder: (context, state) => const EditProfileScreen(),
              ),
              GoRoute(
                path: 'social',
                builder: (context, state) => const EditSocialScreen(),
              ),
              GoRoute(
                path: 'kontakt',
                builder: (context, state) => const EditContactScreen(),
              ),
              GoRoute(
                path: 'email',
                builder: (context, state) => const EmailChangeScreen(),
              ),
              GoRoute(
                path: 'discord',
                builder: (context, state) => const DiscordRelinkScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
