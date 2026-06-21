import 'package:flutter/material.dart';
import '../../features/auth/services/auth_service.dart';
import '../../features/explore/services/explore_service.dart';
import '../../features/explore/services/nominatim_service.dart';

import '../../features/travel/services/travel_service.dart';
import '../../features/user/services/user_service.dart';

class AppScope extends InheritedWidget {
  final AuthService auth;
  final ExploreService explore;
  final NominatimService nominatim;
  final TravelService travel;
  final UserService user;

  const AppScope({
    super.key,
    required this.auth,
    required this.explore,
    required this.nominatim,
    required this.travel,
    required this.user,
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
