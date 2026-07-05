import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/user_avatar.dart';

class SharedLocationsScreen extends StatefulWidget {
  const SharedLocationsScreen({super.key});

  @override
  State<SharedLocationsScreen> createState() => _SharedLocationsScreenState();
}

class _SharedLocationsScreenState extends State<SharedLocationsScreen> {
  @override
  void initState() {
    super.initState();
    final manager = AppScope.of(context).locationSharingManager;
    manager.startContactPolling();
  }

  @override
  void dispose() {
    AppScope.of(context).locationSharingManager.stopContactPolling();
    super.dispose();
  }

  String _timeAgo(String? dt) {
    if (dt == null) return 'unbekannt';
    final parsed = parseApiDate(dt);
    if (parsed == null) return 'unbekannt';
    final diff = DateTime.now().difference(parsed);
    if (diff.inSeconds < 60) return 'gerade eben';
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} Min';
    if (diff.inHours < 24) return 'vor ${diff.inHours}h';
    return 'vor ${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final manager = AppScope.of(context).locationSharingManager;
    final sessions = manager.contactSessions;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleTextStyle: theme.textTheme.titleMedium,
        title: const Text('Geteilte Standorte'),
      ),
      body: sessions.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person_pin_circle_rounded,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Keine Kontakte teilen gerade ihren Standort.',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final active = sessions[index];
                final lastLoc = active.lastLocation;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: UserAvatar(
                      imageUrl: active.owner.image,
                      displayName: active.owner.displayName,
                    ),
                    title: Text(active.owner.displayName),
                    subtitle: Text(
                      'Zuletzt aktualisiert: ${_timeAgo(lastLoc?.recordedAt)}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go(
                      '/standort-teilen/${active.session.id}',
                    ),
                  ),
                );
              },
            ),
    );
  }
}
