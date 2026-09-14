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
import '../../../design/widgets/primitives/design_fab.dart';
import '../../settings/models/notification_preference.dart';
import '../services/notification_method_coordinator.dart';
import '../widgets/notification_method_selector.dart';
import 'push_setup_screens.dart';

/// Verpflichtendes Benachrichtigungs-Setup direkt nach dem Login (Android).
///
/// Der Nutzer markiert eine Methode; erst ein Tipp auf den Weiter-FAB richtet
/// sie ein. Schlägt die Prüfung fehl (kein Distributor, fehlende Berechtigung),
/// bleibt der Screen offen, das Ladesymbol weicht wieder dem Pfeil und der
/// Nutzer kann eine andere Option wählen. Ohne erfolgreiches Setup geht es
/// nicht weiter.
class NotificationSetupScreen extends StatefulWidget {
  const NotificationSetupScreen({super.key});

  @override
  State<NotificationSetupScreen> createState() =>
      _NotificationSetupScreenState();
}

class _NotificationSetupScreenState extends State<NotificationSetupScreen> {
  NotificationMethod? _selected;
  bool _working = false;
  bool _needsPermission = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selected ??= AppScope.of(context).notificationMethod.value;
  }

  /// Markiert nur die Auswahl — eingerichtet wird erst über [_submit].
  void _select(NotificationMethod method) {
    if (_working) return;
    setState(() => _selected = method);
  }

  Future<void> _submit() async {
    if (_working) return;
    final scope = AppScope.of(context);
    final method = _selected ?? NotificationPreference.defaultMethod();
    setState(() {
      _working = true;
      _error = null;
      _needsPermission = false;
    });
    try {
      final coordinator = scope.notificationCoordinator;
      var outcome = await coordinator.apply(
        method,
        previous: scope.notificationMethod.value,
      );

      if (outcome == NotificationMethodOutcome.needsDistributor) {
        if (!mounted) return;
        final distributor = await showDistributorPickerSheet(
          context: context,
          distributors: coordinator.pendingDistributors,
        );
        if (distributor == null) return;
        if (!await coordinator.selectDistributor(distributor)) {
          if (mounted) {
            setState(() {
              _error =
                  'UnifiedPush konnte nicht eingerichtet werden. Bitte wähle '
                  'eine andere Option.';
            });
          }
          return;
        }
        outcome = NotificationMethodOutcome.applied;
      }
      if (!mounted) return;

      switch (outcome) {
        case NotificationMethodOutcome.applied:
          await _commit(scope, method);
        case NotificationMethodOutcome.permissionDenied:
          setState(() => _needsPermission = true);
        case NotificationMethodOutcome.noDistributor:
          setState(() {
            _error =
                'Kein UnifiedPush-Distributor gefunden. Installiere einen '
                'Distributor oder wähle eine andere Option.';
          });
        case NotificationMethodOutcome.needsDistributor:
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
    await (await SharedPreferences.getInstance()).setBool(
      'notification_setup_completed',
      true,
    );
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
        floatingActionButton: DesignFab(
          icon: Icons.arrow_forward_rounded,
          tooltip: 'Einrichtung abschließen',
          loading: _working,
          onPressed: _submit,
        ),
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
                      'Wähle eine Option und tippe dann auf den Pfeil unten '
                      'rechts. Die Einrichtung prüft automatisch, ob sie auf '
                      'deinem Gerät funktioniert. Über das Info-Symbol '
                      'erfährst du Vor- und Nachteile.',
                      style: DesignTextStyle.body,
                      color: tokens.textLow,
                    ),
                    SizedBox(height: tokens.spaceLg),
                    NotificationMethodSelector(
                      selected:
                          _selected ?? NotificationPreference.defaultMethod(),
                      onSelect: _select,
                    ),
                    if (_needsPermission) ...[
                      SizedBox(height: tokens.spaceMd),
                      _InfoBox(
                        icon: Icons.notifications_off_rounded,
                        color: tokens.warning,
                        text:
                            'Benachrichtigungen sind nicht erlaubt. Öffne die '
                            'Einstellungen deines Smartphones (Apps → Beyond → '
                            'Benachrichtigungen), erlaube sie und tippe danach '
                            'erneut auf Weiter.',
                      ),
                    ],
                    if (_error != null) ...[
                      SizedBox(height: tokens.spaceMd),
                      _InfoBox(
                        icon: Icons.error_outline_rounded,
                        color: tokens.danger,
                        text: _error!,
                      ),
                    ],
                    const SizedBox(height: 80),
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

/// Hinweis-Box im Setup: Icon + erklärender Text, token-farbig.
class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return DesignCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          SizedBox(width: tokens.spaceSm),
          Expanded(
            child: DesignText(
              text,
              style: DesignTextStyle.body,
              color: tokens.textHigh,
            ),
          ),
        ],
      ),
    );
  }
}
