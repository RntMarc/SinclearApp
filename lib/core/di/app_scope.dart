import 'package:flutter/material.dart';
import '../services/android_update_service.dart';
import '../services/web_update_service.dart';
import '../../features/auth/services/auth_service.dart';
import '../../features/calendar/services/calendar_service.dart';
import '../../features/explore/services/explore_service.dart';
import '../../features/explore/services/nominatim_service.dart';
import '../../features/feedback/services/feedback_service.dart';
import '../../features/forum/services/forum_service.dart';
import '../../features/moderation/services/moderation_service.dart';
import '../../features/notifications/services/notification_content_resolver.dart';
import '../../features/notifications/services/notification_service.dart';
import '../../features/notifications/services/unified_push_service.dart';
import '../../features/notifications/services/web_push_service.dart';
import '../../features/recipes/services/recipes_service.dart';
import '../../features/settings/models/notification_preference.dart';
import '../../features/settings/services/dav_token_service.dart';
import '../../features/settings/services/dav_sync_service.dart';
import '../../features/settings/services/mcp_key_service.dart';
import '../../features/subscription/services/subscription_service.dart';
import '../../features/travel/services/travel_service.dart';
import '../../features/travel/services/pt_service.dart';
import '../../features/user/services/user_service.dart';
import '../../features/home/dashboard_controller.dart';
import '../../features/home/dashboard_widget_repository.dart';

class AppScope extends InheritedWidget {
  final AuthService auth;
  final ExploreService explore;
  final NominatimService nominatim;
  final TravelService travel;
  final PublicTransportService publicTransport;
  final UserService user;
  final CalendarService calendar;
  final FeedbackService feedback;
  final ForumService forum;
  final RecipesService recipes;
  final ModerationService moderation;
  final SubscriptionService subscription;
  final McpKeyService mcpKeys;
  final DavTokenService davTokens;
  final DavSyncService davSync;
  final AndroidUpdateService androidUpdate;
  final WebUpdateService? webUpdate;
  final DashboardController dashboard;
  final DashboardWidgetRepository dashboardWidgets;
  final NotificationService notification;

  /// Erzeugt aus rohen Benachrichtigungen (`type` + Relation-IDs) Titel,
  /// Text und Deep-Link — einheitlich für Polling, Push und Inbox.
  final NotificationContentResolver notificationContent;
  final UnifiedPushService unifiedPush;
  final WebPushService webPush;

  /// Aktuell gewählte Benachrichtigungs-Methode (lokal persistiert).
  final ValueNotifier<NotificationMethod> notificationMethod;

  final String appBaseUrl;
  final String apiBaseUrl;

  const AppScope({
    super.key,
    required this.auth,
    required this.explore,
    required this.nominatim,
    required this.travel,
    required this.publicTransport,
    required this.user,
    required this.calendar,
    required this.feedback,
    required this.forum,
    required this.recipes,
    required this.moderation,
    required this.subscription,
    required this.mcpKeys,
    required this.davTokens,
    required this.davSync,
    required this.androidUpdate,
    required this.dashboard,
    required this.dashboardWidgets,
    required this.notification,
    required this.notificationContent,
    required this.unifiedPush,
    required this.webPush,
    required this.notificationMethod,
    this.webUpdate,
    required this.appBaseUrl,
    required this.apiBaseUrl,
    required super.child,
  });

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope found in context');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => false;
}
