import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/di/app_scope.dart';
import '../data/third_party_apps.dart';
import '../models/location_sharing_models.dart';

class IntegrationSetupScreen extends StatelessWidget {
  final LocationSharingSessionDetail session;

  const IntegrationSetupScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final manager = AppScope.of(context).locationSharingManager;
    final urls = session.integrationUrls;

    return Scaffold(
      appBar: AppBar(
        titleTextStyle: theme.textTheme.titleMedium,
        title: const Text('Einrichtung'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSuccessHeader(theme),
          const SizedBox(height: 16),
          _buildTokenCard(theme, context),
          const SizedBox(height: 16),
          _buildWarningBanner(theme),
          const SizedBox(height: 24),
          Text(
            'Empfohlene Apps',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...allThirdPartyApps.map(
            (app) => _buildAppCard(
              theme,
              context,
              app: app,
              url: urls[app.key],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Oder direkt aus der App teilen',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            color: theme.colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_rounded,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Die In-App-Funktion ist auf Android unzuverlässig '
                      '(Akkuverbrauch, AlarmManager-Einschränkungen) und '
                      'funktioniert auf iOS im Web nicht im Hintergrund. '
                      'Nutze wenn möglich eine der oben genannten Apps.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              manager.startSending(session);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('In-App-Sharing gestartet.'),
                ),
              );
              context.go('/standort-teilen');
            },
            icon: const Icon(Icons.share_location_rounded),
            label: const Text('Trotzdem direkt aus der App teilen'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.go('/standort-teilen'),
            child: const Text('Zur Übersicht'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSuccessHeader(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: theme.colorScheme.primary,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Standort-Sharing eingerichtet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Empfänger können deinen Standort nun sehen.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenCard(ThemeData theme, BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sitzungstoken',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      session.token,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: session.token),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Token kopiert.'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Dieses Token wird von den Drittanbieter-Apps verwendet.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningBanner(ThemeData theme) {
    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_rounded,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Drittanbieter-App empfohlen',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Die Standort-Übermittlung aus der App heraus ist technisch '
              'eingeschränkt:\n\n'
              '• iOS/Web: Keine Hintergrund-Übermittlung (PWA-Limitierung)\n'
              '• Android: Hoher Akkuverbrauch durch AlarmManager\n'
              '• Alle Plattformen: Unterbrechungen bei App-Wechsel\n\n'
              'Nutze eine dedizierte Tracking-App — diese senden deinen '
              'Standort zuverlässig auch im Hintergrund.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppCard(
    ThemeData theme,
    BuildContext context, {
    required ThirdPartyApp app,
    String? url,
  }) {
    if (url == null || url.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(app.icon, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            app.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (app.recommended) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Empfohlen',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color:
                                      theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        app.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: SelectableText(
                url,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: url));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('URL für ${app.name} kopiert.'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('URL kopieren'),
                  ),
                ),
                if (app.websiteUrl.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => launchUrl(
                        Uri.parse(app.websiteUrl),
                        mode: LaunchMode.externalApplication,
                      ),
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: const Text('App herunterladen'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
