import 'package:flutter/material.dart';
import '../../features/auth/services/auth_service.dart';

class AppScope extends InheritedWidget {
  final AuthService auth;

  const AppScope({
    super.key,
    required this.auth,
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
