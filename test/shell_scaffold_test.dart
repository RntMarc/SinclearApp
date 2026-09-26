import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sinclear_beyond/core/di/app_scope.dart';
import 'package:sinclear_beyond/core/network/api_client.dart';
import 'package:sinclear_beyond/core/services/android_update_service.dart';
import 'package:sinclear_beyond/core/services/time_zone_service.dart';
import 'package:sinclear_beyond/core/storage/token_storage.dart';
import 'package:sinclear_beyond/design/design_variant.dart';
import 'package:sinclear_beyond/design/theme/design_theme.dart';
import 'package:sinclear_beyond/features/auth/services/auth_service.dart';
import 'package:sinclear_beyond/features/calendar/services/calendar_service.dart';
import 'package:sinclear_beyond/features/chat/services/chat_service.dart';
import 'package:sinclear_beyond/features/explore/services/explore_service.dart';
import 'package:sinclear_beyond/features/feedback/services/feedback_service.dart';
import 'package:sinclear_beyond/features/forum/services/forum_service.dart';
import 'package:sinclear_beyond/features/home/dashboard_cache.dart';
import 'package:sinclear_beyond/features/home/dashboard_controller.dart';
import 'package:sinclear_beyond/features/home/dashboard_layout_store.dart';
import 'package:sinclear_beyond/features/home/dashboard_widget.dart';
import 'package:sinclear_beyond/features/home/dashboard_widget_repository.dart';
import 'package:sinclear_beyond/features/location_sharing/services/location_sharing_service.dart';
import 'package:sinclear_beyond/features/moderation/services/moderation_service.dart';
import 'package:sinclear_beyond/features/notifications/services/foreground_polling_service.dart';
import 'package:sinclear_beyond/features/notifications/services/notification_content_resolver.dart';
import 'package:sinclear_beyond/features/notifications/services/notification_method_coordinator.dart';
import 'package:sinclear_beyond/features/notifications/services/notification_service.dart';
import 'package:sinclear_beyond/features/notifications/services/unified_push_service.dart';
import 'package:sinclear_beyond/features/notifications/services/web_push_service.dart';
import 'package:sinclear_beyond/features/photos/services/photos_service.dart';
import 'package:sinclear_beyond/features/recipes/services/recipes_service.dart';
import 'package:sinclear_beyond/features/settings/models/map_app_preference.dart';
import 'package:sinclear_beyond/features/settings/models/notification_preference.dart';
import 'package:sinclear_beyond/features/settings/services/dav_sync_service.dart';
import 'package:sinclear_beyond/features/settings/services/dav_token_service.dart';
import 'package:sinclear_beyond/features/settings/services/lametric_token_service.dart';
import 'package:sinclear_beyond/features/settings/services/mcp_key_service.dart';
import 'package:sinclear_beyond/features/shell/widgets/shell_widgets.dart';
import 'package:sinclear_beyond/features/stories/services/stories_service.dart';
import 'package:sinclear_beyond/features/subscription/services/subscription_service.dart';
import 'package:sinclear_beyond/features/travel/services/pt_service.dart';
import 'package:sinclear_beyond/features/travel/services/travel_service.dart';
import 'package:sinclear_beyond/features/user/services/user_service.dart';
import 'package:sinclear_beyond/features/weather/services/user_weather_location_service.dart';
import 'package:sinclear_beyond/features/weather/services/weather_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'ShellDesktop rendert einen Scaffold und traegt SnackBars',
    (tester) async {
      await _pumpShell(
        tester,
        const ShellDesktop(child: Text('inhalt')),
      );

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('inhalt'), findsOneWidget);

      // Ohne Scaffold unterhalb des Shell moechte ScaffoldMessenger
      // warnen ("currently no descendant Scaffolds") und wirft in
      // Debug-Bauten einen Assertion-Fehler.
      final context = tester.element(find.text('inhalt'));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('meldung')));
      await tester.pumpAndSettle();

      expect(find.text('meldung'), findsOneWidget);
    },
  );
}

Future<void> _pumpShell(WidgetTester tester, Widget shell) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final api = ApiClient(baseUrl: 'http://test');
  final auth = AuthService(api: api, storage: TokenStorage());
  final router = GoRouter(
    routes: [GoRoute(path: '/', builder: (context, state) => shell)],
  );

  await tester.pumpWidget(
    _buildScope(
      api: api,
      auth: auth,
      prefs: prefs,
      child: DesignScope(
        variant: ValueNotifier<DesignVariant>(DesignVariant.materiaPop),
        child: MaterialApp.router(routerConfig: router),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

AppScope _buildScope({
  required ApiClient api,
  required AuthService auth,
  required SharedPreferences prefs,
  required Widget child,
}) {
  final user = UserService(api: api, auth: auth);
  final forum = ForumService(api: api, auth: auth);
  final timeZones = TimeZoneService();
  final calendar = CalendarService(
    api: api,
    auth: auth,
    timeZones: timeZones,
  );
  final travel = TravelService(api: api, auth: auth);
  final subscription = SubscriptionService(api: api, auth: auth);
  final recipes = RecipesService(api: api, auth: auth);
  final weather = WeatherService(api: api, auth: auth);
  final weatherLocations = UserWeatherLocationService(api: api, auth: auth);
  final davTokens = DavTokenService(api: api, auth: auth);
  final notification = NotificationService(api: api);
  final unifiedPush = UnifiedPushService(api: api);
  final foregroundPolling = ForegroundPollingService();

  return AppScope(
    auth: auth,
    explore: ExploreService(api: api, auth: auth),
    travel: travel,
    publicTransport: PublicTransportService(api: api, auth: auth),
    user: user,
    calendar: calendar,
    feedback: FeedbackService(api: api, auth: auth),
    forum: forum,
    chat: ChatService(api: api, auth: auth),
    locationSharing: LocationSharingService(api: api, auth: auth),
    recipes: recipes,
    photos: PhotosService(api: api, auth: auth),
    moderation: ModerationService(api: api, auth: auth),
    subscription: subscription,
    stories: StoriesService(api: api, auth: auth),
    mcpKeys: McpKeyService(api: api, auth: auth),
    davTokens: davTokens,
    davSync: DavSyncService(
      davTokens: davTokens,
      user: user,
      apiBaseUrl: api.baseUrl,
      prefs: prefs,
    ),
    lametricToken: LaMetricTokenService(api: api, auth: auth),
    androidUpdate: AndroidUpdateService(baseUrl: api.baseUrl),
    dashboard: DashboardController(
      initialLayout: const DashboardLayout(widgets: []),
      store: SharedPreferencesDashboardLayoutStore(),
      cache: DashboardCache(),
    ),
    dashboardWidgets: DashboardWidgetRepository(
      recipes: recipes,
      calendar: calendar,
      travel: travel,
      forum: forum,
      subscription: subscription,
      weather: weather,
      weatherLocations: weatherLocations,
    ),
    notification: notification,
    weather: weather,
    weatherLocations: weatherLocations,
    timeZones: timeZones,
    notificationContent: NotificationContentResolver(user: user, forum: forum),
    unifiedPush: unifiedPush,
    webPush: WebPushService(api: api),
    foregroundPolling: foregroundPolling,
    notificationCoordinator: NotificationMethodCoordinator(
      unifiedPush: unifiedPush,
      notification: notification,
      foregroundPolling: foregroundPolling,
      getToken: auth.getAccessToken,
    ),
    notificationMethod: ValueNotifier<NotificationMethod>(
      NotificationMethod.polling,
    ),
    mapApp: ValueNotifier<MapApp>(MapApp.ask),
    appBaseUrl: api.baseUrl,
    apiBaseUrl: api.baseUrl,
    child: child,
  );
}
