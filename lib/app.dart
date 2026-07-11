import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/di/app_scope.dart';
import 'core/services/android_update_service.dart';
import 'core/services/web_update_service.dart';
import 'core/widgets/web_update_banner.dart';
import 'design/beyond.dart';
import 'features/auth/services/auth_service.dart';
import 'features/calendar/services/calendar_service.dart';
import 'features/explore/services/explore_service.dart';
import 'features/explore/services/nominatim_service.dart';
import 'features/feedback/services/feedback_service.dart';
import 'features/forum/services/forum_service.dart';
import 'features/location_sharing/services/location_sharing_service.dart';
import 'features/location_sharing/services/location_sharing_manager.dart';
import 'features/notifications/services/notification_service.dart';
import 'features/recipes/services/recipes_service.dart';
import 'features/travel/services/travel_service.dart';
import 'features/user/services/user_service.dart';

class SinclearApp extends StatelessWidget {
  final AuthService auth;
  final ExploreService explore;
  final NominatimService nominatim;
  final TravelService travel;
  final UserService user;
  final NotificationService notification;
  final CalendarService calendar;
  final FeedbackService feedback;
  final ForumService forum;
  final RecipesService recipes;
  final LocationSharingService locationSharing;
  final LocationSharingManager locationSharingManager;
  final AndroidUpdateService androidUpdate;
  final WebUpdateService webUpdate;
  final GoRouter router;

  const SinclearApp({
    super.key,
    required this.auth,
    required this.explore,
    required this.nominatim,
    required this.travel,
    required this.user,
    required this.notification,
    required this.calendar,
    required this.feedback,
    required this.forum,
    required this.recipes,
    required this.locationSharing,
    required this.locationSharingManager,
    required this.androidUpdate,
    required this.webUpdate,
    required this.router,
  });

  @override
  Widget build(BuildContext context) {
    return AppScope(
      auth: auth,
      explore: explore,
      nominatim: nominatim,
      travel: travel,
      user: user,
      notification: notification,
      calendar: calendar,
      feedback: feedback,
      forum: forum,
      recipes: recipes,
      locationSharing: locationSharing,
      locationSharingManager: locationSharingManager,
      androidUpdate: androidUpdate,
      webUpdate: webUpdate,
      child: WebUpdateBanner(
        service: webUpdate,
        child: MaterialApp.router(
          title: 'Sinclear Beyond',
          debugShowCheckedModeBanner: false,
          theme: BeyondTheme.light(),
          darkTheme: BeyondTheme.dark(),
          themeMode: ThemeMode.dark,
          routerConfig: router,
        ),
      ),
    );
  }
}
