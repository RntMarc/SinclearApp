import 'package:go_router/go_router.dart';
import '../features/auth/services/auth_service.dart';
import '../features/welcome/welcome_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/verify_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/calendar/screens/calendar_screen.dart';
import '../features/calendar/screens/event_detail_screen.dart';
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
import '../features/feedback/screens/feedback_screen.dart';
import '../features/feedback/screens/feedback_detail_screen.dart';
import '../features/recipes/screens/recipe_list_screen.dart';
import '../features/recipes/screens/recipe_catalog_screen.dart';
import '../features/recipes/screens/recipe_detail_screen.dart';
import '../features/forum/screens/forum_list_screen.dart';
import '../features/forum/screens/forum_detail_screen.dart';
import '../features/forum/screens/post_detail_screen.dart';
import '../features/forum/screens/create_post_screen.dart';
import '../features/showcase/screens/design_showcase_screen.dart';

GoRouter createRouter(AuthService auth) {
  return GoRouter(
    refreshListenable: auth,
    initialLocation: '/',
    redirect: (context, state) {
      final loggedIn = auth.isLoggedIn;
      final location = state.matchedLocation;

      final isAuth =
          location.startsWith('/home') ||
          location.startsWith('/kalender') ||
          location.startsWith('/entdecken') ||
          location.startsWith('/reisen') ||
          location.startsWith('/kontakte') ||
          location.startsWith('/einstellungen') ||
          location.startsWith('/feedback') ||
          location.startsWith('/forum') ||
          location.startsWith('/rezepte') ||
          location.startsWith('/design-showcase');

      if (loggedIn && !auth.onboardingCompleted && location != '/onboarding') {
        return '/onboarding';
      }
      if (loggedIn && auth.onboardingCompleted && location == '/onboarding') {
        return '/home';
      }
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
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/kalender',
            builder: (context, state) => const CalendarScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    EventDetailScreen(id: state.pathParameters['id']!),
              ),
            ],
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
            path: '/feedback',
            builder: (context, state) => const FeedbackScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    FeedbackDetailScreen(id: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/forum',
            builder: (context, state) => const ForumListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    ForumDetailScreen(id: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'beitrag/:postId',
                    builder: (context, state) => PostDetailScreen(
                      forumId: state.pathParameters['id']!,
                      postId: state.pathParameters['postId']!,
                    ),
                  ),
                  GoRoute(
                    path: 'erstellen',
                    builder: (context, state) =>
                        CreatePostScreen(forumId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/rezepte',
            builder: (context, state) => const RecipeListScreen(),
            routes: [
              GoRoute(
                path: 'alle',
                builder: (context, state) =>
                    const RecipeCatalogScreen(),
              ),
              GoRoute(
                path: 'kategorie/:key',
                builder: (context, state) => RecipeCatalogScreen(
                  initialCategory: state.pathParameters['key'],
                ),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => RecipeDetailScreen(
                  id: state.pathParameters['id']!,
                ),
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
          GoRoute(
            path: '/design-showcase',
            builder: (context, state) => const DesignShowcaseScreen(),
          ),
        ],
      ),
    ],
  );
}
