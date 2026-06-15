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

GoRouter createRouter(AuthService auth) {
  return GoRouter(
    refreshListenable: auth,
    initialLocation: '/',
    redirect: (context, state) {
      final loggedIn = auth.isLoggedIn;
      final location = state.matchedLocation;

      final isAuth = location.startsWith('/home') ||
          location.startsWith('/entdecken');

      if (loggedIn && location == '/') return '/home';
      if (!loggedIn && isAuth) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
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
        ],
      ),
    ],
  );
}
