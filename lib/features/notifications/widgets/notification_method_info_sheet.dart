import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../settings/models/notification_preference.dart';
import '../screens/push_setup_screens.dart';

/// Offizielle Liste installierbarer UnifiedPush-Distributoren.
const unifiedPushDistributorsUrl =
    'https://unifiedpush.org/users/distributors/';

/// Erklärt Funktionsweise sowie Vor- und Nachteile einer Zustell-Methode.
Future<void> showNotificationMethodInfoSheet(
  BuildContext context,
  NotificationMethod method,
) {
  return showDesignSheet<void>(
    context: context,
    child: _NotificationMethodInfo(method: method),
  );
}

class _NotificationMethodInfo extends StatelessWidget {
  const _NotificationMethodInfo({required this.method});

  final NotificationMethod method;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final info = _infoFor(method);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesignText(
          '${method.label}: So funktioniert es',
          style: DesignTextStyle.subtitle,
        ),
        SizedBox(height: tokens.spaceSm),
        DesignText(
          info.how,
          style: DesignTextStyle.body,
          color: tokens.textLow,
        ),
        SizedBox(height: tokens.spaceMd),
        _BulletList(title: 'Vorteile', items: info.pros, color: tokens.success),
        SizedBox(height: tokens.spaceSm),
        _BulletList(
          title: 'Nachteile',
          items: info.cons,
          color: tokens.warning,
        ),
        if (method == NotificationMethod.unifiedPush) ...<Widget>[
          SizedBox(height: tokens.spaceMd),
          DesignButton(
            label: 'UnifiedPush-Distributoren finden',
            icon: Icons.open_in_new_rounded,
            variant: DesignButtonVariant.text,
            onPressed: () => launchUrl(
              Uri.parse(unifiedPushDistributorsUrl),
              mode: LaunchMode.externalApplication,
            ),
          ),
        ],
        if (method == NotificationMethod.polling) ...<Widget>[
          SizedBox(height: tokens.spaceMd),
          DesignButton(
            label: 'Akku-Hinweise für dein Gerät',
            icon: Icons.battery_saver_rounded,
            variant: DesignButtonVariant.text,
            onPressed: () {
              final navigator = Navigator.of(context, rootNavigator: true);
              navigator.pop();
              navigator.push(
                MaterialPageRoute(builder: (_) => const PollingHintScreen()),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({
    required this.title,
    required this.items,
    required this.color,
  });

  final String title;
  final List<String> items;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DesignText(title, style: DesignTextStyle.label, color: color),
        SizedBox(height: tokens.spaceXs),
        for (final item in items)
          Padding(
            padding: EdgeInsets.only(bottom: tokens.spaceXs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DesignText('• ', style: DesignTextStyle.body, color: color),
                Expanded(
                  child: DesignText(
                    item,
                    style: DesignTextStyle.body,
                    color: tokens.textLow,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

typedef _MethodInfo = ({String how, List<String> pros, List<String> cons});

_MethodInfo _infoFor(NotificationMethod method) {
  return switch (method) {
    NotificationMethod.polling => (
      how:
          'Beyond fragt selbst in regelmäßigen Abständen beim Server nach '
          'neuen Benachrichtigungen. Dafür läuft ein Hintergrund-Dienst mit '
          'einer dauerhaften, leisen Benachrichtigung. Ist das nicht möglich, '
          'prüft das System die App seltener (etwa alle 15 Minuten) im '
          'Hintergrund.',
      pros: [
        'Funktioniert ohne zusätzliche App und ohne Einrichtung.',
        'Zuverlässig, solange die dauerhafte Benachrichtigung sichtbar bleibt.',
      ],
      cons: [
        'Etwas höherer Akkuverbrauch durch den Hintergrund-Dienst.',
        'Neue Benachrichtigungen können einige Minuten später erscheinen.',
      ],
    ),
    NotificationMethod.unifiedPush => (
      how:
          'UnifiedPush verteilt Push-Nachrichten über eine von dir gewählte '
          'Distributor-App (z. B. ntfy, Gotify oder NextPush). Die App '
          'registriert sich bei diesem Distributor, der Server schickt neue '
          'Benachrichtigungen sofort dorthin.',
      pros: [
        'Sehr akkusparend und nahezu sofortige Zustellung.',
        'Dezentral und datenschutzfreundlich – ohne Google-Server.',
        'Keine dauerhafte Benachrichtigung in der Statusleiste nötig.',
      ],
      cons: [
        'Eine passende Distributor-App muss installiert und eingerichtet sein.',
        'Ohne Distributor kann diese Option nicht genutzt werden.',
      ],
    ),
    NotificationMethod.fcm => (
      how:
          'Google Firebase Cloud Messaging ist der Push-Dienst von Google. '
          'Die Integration ist in Beyond derzeit nicht verfügbar.',
      pros: ['Weit verbreiteter Standard-Dienst.'],
      cons: [
        'Aus Datenschutzgründen derzeit nicht aktiviert.',
        'Nachrichten würden über Google-Server laufen.',
      ],
    ),
  };
}
