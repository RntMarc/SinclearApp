import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/di/app_scope.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_app_bar.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../settings/models/notification_preference.dart';
import '../services/notification_method_coordinator.dart';
import '../widgets/notification_method_selector.dart';
import 'push_setup_screens.dart';

/// Verpflichtendes Benachrichtigungs-Setup direkt nach dem Login (Android).
///
/// Der Nutzer wählt eine Methode; die Auswahl wird sofort geprüft und
/// eingerichtet. Schlägt die Prüfung fehl (kein Distributor, fehlende
/// Berechtigung), wird die Option nicht übernommen und der Nutzer muss eine
/// andere wählen. Ohne Auswahl geht es nicht weiter.
class NotificationSetupScreen extends StatefulWidget {
  const NotificationSetupScreen({super.key});

  @override
  State<NotificationSetupScreen> createState() =>
      _NotificationSetupScreenState();
}

class _NotificationSetupScreenState extends State<NotificationSetupScreen> {
  bool _working = false;
  String? _error;

  Future<void> _select(NotificationMethod method) async {
    if (_working) return;
    final scope = AppScope.of(context);
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final coordinator = scope.notificationCoordinator;
      final outcome = await coordinator.apply(
        method,
        previous: scope.notificationMethod.value,
      );
      if (!mounted) return;

      switch (outcome) {
        case NotificationMethodOutcome.applied:
          await _commit(scope, method);
        case NotificationMethodOutcome.needsDistributor:
          final selected = await showDistributorPickerSheet(
            context: context,
            distributors: coordinator.pendingDistributors,
          );
          if (selected == null || !mounted) return;
          await coordinator.selectDistributor(selected);
          if (!mounted) return;
          await _commit(scope, method);
        case NotificationMethodOutcome.noDistributor:
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NoDistributorScreen()),
          );
          if (!mounted) return;
          setState(() {
            _error =
                'Kein UnifiedPush-Distributor gefunden. Bitte wähle eine '
                'andere Option.';
          });
        case NotificationMethodOutcome.permissionDenied:
          setState(() {
            _error =
                'Benachrichtigungen sind nicht erlaubt. Bitte erlaube sie in '
                'den Systemeinstellungen oder wähle eine andere Option.';
          });
        case NotificationMethodOutcome.unavailable:
          break;
      }
    } catch (e, st) {
      developer.log(
        'Notification setup failed',
        error: e,
        stackTrace: st,
        name: 'notification_setup',
      );
      if (mounted) {
        setState(() {
          _error = 'Einrichtung fehlgeschlagen. Bitte versuche es erneut.';
        });
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _commit(AppScope scope, NotificationMethod method) async {
    scope.notificationMethod.value = method;
    await NotificationPreference.save(method);
    await (await SharedPreferences.getInstance())
        .setBool('notification_setup_completed', true);
    if (!mounted) return;
    final target = scope.auth.onboardingCompleted ? '/home' : '/onboarding';
    context.go(target);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return DesignSurface(
      withGrain: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const DesignAppBar(title: 'Benachrichtigungen einrichten'),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spaceXl,
                vertical: tokens.spaceXl,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.notifications_active_rounded,
                      size: 56,
                      color: tokens.primary,
                    ),
                    SizedBox(height: tokens.spaceXl),
                    const DesignText(
                      'Wie möchtest du Benachrichtigungen erhalten?',
                      style: DesignTextStyle.subtitle,
                    ),
                    SizedBox(height: tokens.spaceXs),
                    DesignText(
                      'Wähle eine Option. Die Einrichtung prüft automatisch, '
                      'ob sie auf deinem Gerät funktioniert. Über das '
                      'Info-Symbol erfährst du Vor- und Nachteile.',
                      style: DesignTextStyle.body,
                      color: tokens.textLow,
                    ),
                    SizedBox(height: tokens.spaceLg),
                    NotificationMethodSelector(
                      selected: AppScope.of(context).notificationMethod.value,
                      saving: _working,
                      onSelect: _select,
                    ),
                    if (_error != null) ...[
                      SizedBox(height: tokens.spaceMd),
                      DesignCard(
                        child: DesignText(
                          _error!,
                          style: DesignTextStyle.body,
                          color: tokens.danger,
                        ),
                      ),
                    ],
                    SizedBox(height: tokens.spaceMd),
                    DesignText(
                      'Ohne Auswahl kannst du nicht fortfahren.',
                      style: DesignTextStyle.label,
                      color: tokens.textLow,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
