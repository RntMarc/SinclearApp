import 'package:flutter/material.dart';
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
import '../features/explore/screens/submit_place_screen.dart';
import '../features/explore/screens/place_confirm_screen.dart';
import '../features/explore/screens/submissions_list_screen.dart';
import '../features/explore/screens/submission_detail_screen.dart';
import '../features/explore/models/explore_models.dart';

import '../features/shell/main_shell.dart';
import '../features/travel/screens/travel_screen.dart';
import '../features/travel/screens/event_detail_screen.dart';
import '../features/travel/screens/trip_detail_screen.dart';
import '../features/travel/screens/pt_journey_detail_screen.dart';
import '../features/user/screens/contacts_screen.dart';
import '../features/user/screens/user_detail_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/settings/screens/notification_settings_screen.dart';
import '../features/settings/screens/edit_profile_screen.dart';
import '../features/settings/screens/edit_social_screen.dart';
import '../features/settings/screens/edit_contact_screen.dart';
import '../features/settings/screens/email_change_screen.dart';
import '../features/settings/screens/discord_relink_screen.dart';
import '../features/settings/screens/mcp_keys_screen.dart';
import '../features/settings/screens/dav_tokens_screen.dart';
import '../features/settings/screens/map_app_screen.dart';
import '../features/settings/screens/location_sharing_settings_screen.dart';
import '../features/settings/screens/location_sharing_create_screen.dart';
import '../features/location_sharing/screens/location_sharing_screen.dart';
import '../features/location_sharing/screens/location_sharing_session_detail_screen.dart';
import '../features/feedback/screens/feedback_screen.dart';
import '../features/feedback/screens/feedback_detail_screen.dart';
import '../features/recipes/screens/recipe_list_screen.dart';
import '../features/recipes/screens/recipe_catalog_screen.dart';
import '../features/recipes/screens/recipe_create_screen.dart';
import '../features/recipes/screens/recipe_detail_screen.dart';
import '../features/forum/screens/forum_list_screen.dart';
import '../features/forum/screens/forum_detail_screen.dart';
import '../features/forum/screens/post_detail_screen.dart';
import '../features/forum/screens/create_post_screen.dart';
import '../features/moderation/screens/moderation_requests_screen.dart';
import '../features/showcase/screens/design_showcase_screen.dart';
import '../features/stories/screens/story_deep_link_screen.dart';
import '../features/subscription/screens/subscription_list_screen.dart';
import '../features/chat/screens/conversation_screen.dart';

GoRouter createRouter(AuthService auth, {String? initialLocation}) {
  return GoRouter(
    refreshListenable: auth,
    initialLocation: initialLocation ?? '/',
    errorBuilder: (context, state) => const _RouterErrorScreen(),
    redirect: (context, state) {
      final loggedIn = auth.isLoggedIn;
      final location = state.matchedLocation;

      final isAuth =
          location.startsWith('/home') ||
          location.startsWith('/kalender') ||
          (location.startsWith('/entdecken') && !_isGuestExplore(location)) ||
          location.startsWith('/reisen') ||
          location.startsWith('/kontakte') ||
          location.startsWith('/standort') ||
          location.startsWith('/einstellungen') ||
          location.startsWith('/feedback') ||
          location.startsWith('/mod-anfragen') ||
          location.startsWith('/forum') ||
          (location.startsWith('/rezepte') && !_isGuestRecipes(location)) ||
          location.startsWith('/abos') ||
          location.startsWith('/stories') ||
          location.startsWith('/chat') ||
          location.startsWith('/design-showcase');

      if (loggedIn && !auth.onboardingCompleted && location != '/onboarding') {
        return '/onboarding';
      }
      if (loggedIn && auth.onboardingCompleted && location == '/onboarding') {
        return '/home';
      }
      if (loggedIn &&
          location.startsWith('/design-showcase') &&
          !auth.isAdmin) {
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
              GoRoute(
                path: 'pt/:id',
                builder: (context, state) => PtJourneyDetailScreen(
                  journeyId: state.pathParameters['id']!,
                ),
              ),
              GoRoute(
                path: 'einzelevent/:id',
                builder: (context, state) =>
                    TravelEventDetailScreen(id: state.pathParameters['id']!),
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
                routes: [
                  GoRoute(
                    path: 'bestaetigen',
                    builder: (context, state) => PlaceConfirmScreen(
                      result: state.extra as NominatimResult,
                    ),
                  ),
                  GoRoute(
                    path: 'melden',
                    builder: (context, state) => const SubmitPlaceScreen(),
                  ),
                  GoRoute(
                    path: 'einreichungen',
                    builder: (context, state) => const SubmissionsListScreen(),
                    routes: [
                      GoRoute(
                        path: ':submissionId',
                        builder: (context, state) => SubmissionDetailScreen(
                          id: state.pathParameters['submissionId']!,
                        ),
                      ),
                    ],
                  ),
                ],
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
            path: '/standort',
            builder: (context, state) => const LocationSharingScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => LocationSharingSessionDetailScreen(
                  sessionId: state.pathParameters['id']!,
                  ownerName: state.extra as String?,
                ),
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
            path: '/mod-anfragen',
            builder: (context, state) => const ModerationRequestsScreen(),
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
                builder: (context, state) => const RecipeCatalogScreen(),
              ),
              GoRoute(
                path: 'kategorie/:key',
                builder: (context, state) => RecipeCatalogScreen(
                  initialCategory: state.pathParameters['key'],
                ),
              ),
              GoRoute(
                path: 'neu',
                builder: (context, state) => const RecipeCreateScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    RecipeDetailScreen(id: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'bearbeiten',
                    builder: (context, state) => RecipeCreateScreen(
                      recipeId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/einstellungen',
            builder: (context, state) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: 'benachrichtigungen',
                builder: (context, state) => const NotificationSettingsScreen(),
              ),
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
              GoRoute(
                path: 'mcp',
                builder: (context, state) => const McpKeysScreen(),
              ),
              GoRoute(
                path: 'dav',
                builder: (context, state) => const DavTokensScreen(),
              ),
              GoRoute(
                path: 'karte',
                builder: (context, state) => const MapAppScreen(),
              ),
              GoRoute(
                path: 'standort',
                builder: (context, state) =>
                    const LocationSharingSettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'neu',
                    builder: (context, state) =>
                        const LocationSharingCreateScreen(),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/chat/:conversationId',
            builder: (context, state) => ConversationScreen(
              conversationId: state.pathParameters['conversationId']!,
            ),
          ),
          GoRoute(
            path: '/abos',
            builder: (context, state) => const SubscriptionListScreen(),
          ),
          GoRoute(
            path: '/design-showcase',
            builder: (context, state) => const DesignShowcaseScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/stories/:id',
        builder: (context, state) =>
            StoryDeepLinkScreen(storyId: state.pathParameters['id']!),
      ),
    ],
  );
}

/// Entdecken-Seiten, die auch ohne Login erreichbar sind (Liste, Kategorien,
/// Details). Die Erstellen-Flows unter `/entdecken/neu` bleiben angemeldeten
/// Nutzern vorbehalten.
bool _isGuestExplore(String location) {
  return location.startsWith('/entdecken') &&
      !location.startsWith('/entdecken/neu');
}

/// Rezepte-Seiten, die auch ohne Login erreichbar sind (Liste, Katalog,
/// Details). Die Erstellen-/Bearbeiten-Flows (`/rezepte/neu`,
/// `/rezepte/:id/bearbeiten`) bleiben angemeldeten Nutzern vorbehalten.
bool _isGuestRecipes(String location) {
  return location.startsWith('/rezepte') &&
      !location.startsWith('/rezepte/neu') &&
      !location.endsWith('/bearbeiten');
}

/// Simple error screen to avoid go_router's default error screen overflow.
class _RouterErrorScreen extends StatelessWidget {
  const _RouterErrorScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Seite nicht gefunden'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go('/'),
              child: const Text('Zur Startseite'),
            ),
          ],
        ),
      ),
    );
  }
}
