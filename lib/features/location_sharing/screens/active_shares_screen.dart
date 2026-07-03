import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/app_scope.dart';

class ActiveSharesScreen extends StatefulWidget {
  const ActiveSharesScreen({super.key});

  @override
  State<ActiveSharesScreen> createState() => _ActiveSharesScreenState();
}

class _ActiveSharesScreenState extends State<ActiveSharesScreen> {
  Timer? _countdownTimer;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _load();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final manager = AppScope.of(context).locationSharingManager;
    await manager.loadMySessions();
    if (mounted) setState(() {});
  }

  Duration? _remaining(String expiresAt) {
    final dt = DateTime.tryParse(expiresAt);
    if (dt == null) return null;
    final remaining = dt.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  String _formatRemaining(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  Future<void> _stop(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Standort-Sharing beenden?'),
        content:
            const Text('Die Kontakte können deinen Standort dann nicht mehr sehen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Beenden'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await AppScope.of(context).locationSharingManager.stopSession(id);
      if (mounted) setState(() {});
    }
  }

  Future<void> _extend(String id) async {
    final minutes = await showDialog<int>(
      context: context,
      builder: (ctx) {
        int value = 30;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('Verlängern'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${value} Minuten'),
                Slider(
                  value: value.toDouble(),
                  min: 15,
                  max: 240,
                  divisions: 15,
                  label: '$value Min',
                  onChanged: (v) =>
                      setDialogState(() => value = v.round()),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Abbrechen'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, value),
                child: const Text('Verlängern'),
              ),
            ],
          ),
        );
      },
    );
    if (minutes != null && mounted) {
      await AppScope.of(context)
          .locationSharingManager
          .extendSession(id, minutes * 60);
    }
  }

  @override
  Widget build(BuildContext context) {
    final manager = AppScope.of(context).locationSharingManager;
    final sessions = manager.mySessions;
    final theme = Theme.of(context);

    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_off_rounded,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Du teilst gerade keinen Standort.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () => context.go('/standort-teilen/erstellen'),
              child: const Text('Standort teilen'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          final session = sessions[index];
          final remaining = _remaining(session.expiresAt);
          final recipients = session.recipients
              .map((r) => r.displayName)
              .join(', ');

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.circle,
                          size: 12, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Aktiv',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.green,
                        ),
                      ),
                      const Spacer(),
                      if (remaining != null)
                        Text(
                          _formatRemaining(remaining),
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Empfänger: $recipients',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Aktualisierung: alle ${session.frequencySeconds ~/ 60} Minuten',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _extend(session.id),
                        icon: const Icon(Icons.timer_outlined,
                            size: 18),
                        label: const Text('Verlängern'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonalIcon(
                        onPressed: () => _stop(session.id),
                        icon: const Icon(Icons.stop_rounded,
                            size: 18),
                        label: const Text('Beenden'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
