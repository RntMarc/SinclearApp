import 'package:flutter/material.dart';
import '../services/android_update_service.dart';
import '../services/web_update_service.dart';
import '../../features/auth/services/auth_service.dart';
import '../../features/calendar/services/calendar_service.dart';
import '../../features/explore/services/explore_service.dart';
import '../../features/explore/services/nominatim_service.dart';
import '../../features/feedback/services/feedback_service.dart';
import '../../features/forum/services/forum_service.dart';
import '../../features/notifications/services/notification_service.dart';
import '../../features/recipes/services/recipes_service.dart';
import '../../features/subscription/services/subscription_service.dart';
import '../../features/travel/services/travel_service.dart';
import '../../features/travel/services/pt_service.dart';
import '../../features/user/services/user_service.dart';
class AppScope extends InheritedWidget {
  final AuthService auth;
  final ExploreService explore;
  final NominatimService nominatim;
  final TravelService travel;
  final PublicTransportService publicTransport;
  final UserService user;
  final NotificationService notification;
  final CalendarService calendar;
  final FeedbackService feedback;
  final ForumService forum;
  final RecipesService recipes;
  final SubscriptionService subscription;
  final AndroidUpdateService androidUpdate;
  final WebUpdateService? webUpdate;
  const AppScope({
    super.key,
    required this.auth,
    required this.explore,
    required this.nominatim,
    required this.travel,
    required this.publicTransport,
    required this.user,
    required this.notification,
    required this.calendar,
    required this.feedback,
    required this.forum,
    required this.recipes,
    required this.subscription,
    required this.androidUpdate,
    this.webUpdate,
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
