import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/di/app_scope.dart';
import '../data/third_party_apps.dart';
import '../models/location_sharing_models.dart';

class IntegrationSetupScreen extends StatefulWidget {
  final LocationSharingSessionDetail session;

  const IntegrationSetupScreen({super.key, required this.session});

  @override
  State<IntegrationSetupScreen> createState() => _IntegrationSetupScreenState();
}

class _IntegrationSetupScreenState extends State<IntegrationSetupScreen> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _customizeUrl(String url) {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      // Remove the /{name} segment (the last path segment before query params)
      final queryIndex = url.indexOf('?');
      final path = queryIndex >= 0 ? url.substring(0, queryIndex) : url;
      final query = queryIndex >= 0 ? url.substring(queryIndex) : '';
      final segments = path.split('/');
      if (segments.length >= 2) {
        segments.removeLast();
        return '${segments.join('/')}$query';
      }
      return url;
    }
    // Replace /yourname (the last path segment) with the entered name
    const placeholder = 'yourname';
    final lastSlash = url.lastIndexOf('/$placeholder');
    if (lastSlash >= 0) {
      return '${url.substring(0, lastSlash)}/$name${url.substring(lastSlash + 1 + placeholder.length)}';
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final urls = widget.session.integrationUrls;

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
          _buildNameField(theme),
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
            onPressed: () => _showInAppSettingsDialog(context),
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

  Widget _buildNameField(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gerätename (optional)',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Viele Tracking-Apps unterstützen einen Namen in der URL. '
              'Wenn du einen Namen vergibst, kannst du mehrere Geräte '
              'in deiner Session unterscheiden.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'z.B. mein-handy',
                prefixIcon: const Icon(Icons.phone_android_rounded, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
              ),
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }

  void _showInAppSettingsDialog(BuildContext context) {
    final manager = AppScope.of(context).locationSharingManager;
    int durationMinutes = widget.session.durationSeconds ~/ 60;
    int frequencyMinutes = widget.session.frequencySeconds ~/ 60;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('In-App-Sharing'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Dauer: $durationMinutes Minuten',
              ),
              Slider(
                value: durationMinutes.toDouble(),
                min: 5,
                max: 1440,
                divisions: 50,
                label: '$durationMinutes Min',
                onChanged: (v) =>
                    setDialogState(() => durationMinutes = v.round()),
              ),
              const SizedBox(height: 16),
              Text(
                'Aktualisierung: alle $frequencyMinutes Minuten',
              ),
              Slider(
                value: frequencyMinutes.toDouble(),
                min: 5,
                max: 20,
                divisions: 15,
                label: '$frequencyMinutes Min',
                onChanged: (v) =>
                    setDialogState(() => frequencyMinutes = v.round()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                manager.startSending(widget.session);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('In-App-Sharing gestartet.'),
                  ),
                );
                context.go('/standort-teilen');
              },
              child: const Text('Starten'),
            ),
          ],
        ),
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
                      widget.session.token,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: widget.session.token),
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

    final customizedUrl = _customizeUrl(url);

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
                customizedUrl,
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
                      Clipboard.setData(ClipboardData(text: customizedUrl));
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
