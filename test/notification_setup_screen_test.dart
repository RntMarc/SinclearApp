import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sinclear_beyond/core/di/app_scope.dart';
import 'package:sinclear_beyond/core/network/api_client.dart';
import 'package:sinclear_beyond/core/services/android_update_service.dart';
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
import 'package:sinclear_beyond/features/notifications/screens/notification_setup_screen.dart';
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
import 'package:sinclear_beyond/features/settings/services/mcp_key_service.dart';
import 'package:sinclear_beyond/features/stories/services/stories_service.dart';
import 'package:sinclear_beyond/features/subscription/services/subscription_service.dart';
import 'package:sinclear_beyond/features/travel/services/pt_service.dart';
import 'package:sinclear_beyond/features/travel/services/travel_service.dart';
import 'package:sinclear_beyond/features/user/services/user_service.dart';
import 'package:sinclear_beyond/features/weather/services/user_weather_location_service.dart';
import 'package:sinclear_beyond/features/weather/services/weather_service.dart';

/// Koordinator-Attrappe, die ein festes Ergebnis liefert und die Aufrufe zählt.
class _FakeCoordinator extends NotificationMethodCoordinator {
  _FakeCoordinator(ApiClient api, this.outcome)
    : super(
        unifiedPush: UnifiedPushService(api: api),
        notification: NotificationService(api: api),
        foregroundPolling: ForegroundPollingService(),
        getToken: () async => 'token',
        requestPermission: () async => true,
      );

  final NotificationMethodOutcome outcome;
  int applyCalls = 0;

  @override
  Future<NotificationMethodOutcome> apply(
    NotificationMethod method, {
    NotificationMethod? previous,
  }) async {
    applyCalls++;
    return outcome;
  }
}

Future<void> _pumpSetup(
  WidgetTester tester,
  NotificationMethodCoordinator coordinator,
) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final api = ApiClient(baseUrl: 'http://test');
  final auth = AuthService(api: api, storage: TokenStorage());
  await tester.pumpWidget(
    _buildScope(
      api: api,
      auth: auth,
      prefs: prefs,
      coordinator: coordinator,
      child: DesignScope(
        variant: ValueNotifier<DesignVariant>(DesignVariant.materiaPop),
        child: const MaterialApp(home: NotificationSetupScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Auswahl richtet nicht sofort ein, erst der FAB', (tester) async {
    final coordinator = _FakeCoordinator(
      ApiClient(baseUrl: 'http://test'),
      NotificationMethodOutcome.permissionDenied,
    );
    await _pumpSetup(tester, coordinator);

    await tester.tap(find.text('Polling'));
    await tester.pumpAndSettle();
    expect(coordinator.applyCalls, 0);

    await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
    await tester.pumpAndSettle();
    expect(coordinator.applyCalls, 1);
  });

  testWidgets('permissionDenied zeigt Infobox und bleibt offen', (
    tester,
  ) async {
    final coordinator = _FakeCoordinator(
      ApiClient(baseUrl: 'http://test'),
      NotificationMethodOutcome.permissionDenied,
    );
    await _pumpSetup(tester, coordinator);

    await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Benachrichtigungen sind nicht erlaubt'),
      findsOneWidget,
    );
    expect(find.byType(NotificationSetupScreen), findsOneWidget);
  });

  testWidgets('noDistributor zeigt Fehler und bleibt offen', (tester) async {
    final coordinator = _FakeCoordinator(
      ApiClient(baseUrl: 'http://test'),
      NotificationMethodOutcome.noDistributor,
    );
    await _pumpSetup(tester, coordinator);

    await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
    await tester.pumpAndSettle();

    expect(find.textContaining('Kein UnifiedPush-Distributor'), findsOneWidget);
    expect(find.byType(NotificationSetupScreen), findsOneWidget);
  });
}

AppScope _buildScope({
  required ApiClient api,
  required AuthService auth,
  required SharedPreferences prefs,
  required NotificationMethodCoordinator coordinator,
  required Widget child,
}) {
  final user = UserService(api: api, auth: auth);
  final forum = ForumService(api: api, auth: auth);
  final calendar = CalendarService(api: api, auth: auth);
  final travel = TravelService(api: api, auth: auth);
  final subscription = SubscriptionService(api: api, auth: auth);
  final recipes = RecipesService(api: api, auth: auth);
  final weather = WeatherService(api: api, auth: auth);
  final weatherLocations = UserWeatherLocationService(api: api, auth: auth);
  final davTokens = DavTokenService(api: api, auth: auth);
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
    notification: NotificationService(api: api),
    weather: weather,
    weatherLocations: weatherLocations,
    notificationContent: NotificationContentResolver(user: user, forum: forum),
    unifiedPush: UnifiedPushService(api: api),
    webPush: WebPushService(api: api),
    foregroundPolling: ForegroundPollingService(),
    notificationCoordinator: coordinator,
    notificationMethod: ValueNotifier<NotificationMethod>(
      NotificationMethod.polling,
    ),
    mapApp: ValueNotifier<MapApp>(MapApp.ask),
    appBaseUrl: api.baseUrl,
    apiBaseUrl: api.baseUrl,
    child: child,
  );
}
