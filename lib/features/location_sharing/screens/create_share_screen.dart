import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../user/models/user_models.dart';

class CreateShareScreen extends StatefulWidget {
  const CreateShareScreen({super.key});

  @override
  State<CreateShareScreen> createState() => _CreateShareScreenState();
}

class _CreateShareScreenState extends State<CreateShareScreen> {
  List<UserBasePublic>? _users;
  bool _loading = true;
  final Set<String> _selectedIds = {};
  double _durationHours = 1;
  double _frequencyMinutes = 10;
  bool _creating = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    if (_users != null) return;
    setState(() => _loading = true);
    try {
      final scope = AppScope.of(context);
      final userId = scope.auth.userId;
      await scope.auth.getAccessToken();
      final users = await scope.user.listAll();
      users.sort((a, b) {
        if (a.id == userId) return -1;
        if (b.id == userId) return 1;
        return a.displayName.compareTo(b.displayName);
      });
      if (!mounted) return;
      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (e, st) {
      developer.log('Failed to load users', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  int get _durationSeconds => (_durationHours * 3600).round().clamp(300, 86400);
  int get _frequencySeconds => (_frequencyMinutes * 60).round().clamp(300, 1200);

  Future<void> _create() async {
    if (_selectedIds.isEmpty) return;
    setState(() => _creating = true);
    try {
      final scope = AppScope.of(context);
      final session = await scope.locationSharingManager.createSession(
        recipientIds: _selectedIds.toList(),
        durationSeconds: _durationSeconds,
        frequencySeconds: _frequencySeconds,
      );
      if (!mounted) return;
      if (session != null) {
        context.go('/standort-teilen');
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleTextStyle: theme.textTheme.titleMedium,
        title: const Text('Standort teilen'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Kontakte auswählen',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...?_users
                    ?.where((u) => u.id != AppScope.of(context).auth.userId)
                    .map((user) => CheckboxListTile(
                          value: _selectedIds.contains(user.id),
                          onChanged: (v) {
                            setState(() {
                              if (v == true) {
                                _selectedIds.add(user.id);
                              } else {
                                _selectedIds.remove(user.id);
                              }
                            });
                          },
                          secondary: _buildAvatar(user),
                          title: Text(user.displayName),
                        )),
                const SizedBox(height: 24),
                Text('Dauer', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Slider(
                  value: _durationHours,
                  min: 5 / 60,
                  max: 24,
                  divisions: 48,
                  label: _formatDuration(_durationSeconds),
                  onChanged: (v) => setState(() => _durationHours = v),
                ),
                Text(
                  _formatDuration(_durationSeconds),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text('Aktualisierung', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Slider(
                  value: _frequencyMinutes,
                  min: 5,
                  max: 20,
                  divisions: 15,
                  label: '${_frequencyMinutes.round()} Min',
                  onChanged: (v) => setState(() => _frequencyMinutes = v),
                ),
                Text(
                  'Alle ${_frequencyMinutes.round()} Minuten',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (!kIsWeb &&
                    defaultTargetPlatform == TargetPlatform.android)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.battery_saver_rounded,
                              color: theme.colorScheme.tertiary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Der Standort wird nur zu den einge stellten Zeiten gesendet – '
                                'batterieschonend.',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (kIsWeb)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Card(
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
                                'Standort-Sharing im Browser funktioniert nur bei geöffnetem Tab. '
                                'Nutze die Android-App für zuverlässiges Hintergrund-Sharing.',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed:
                      _selectedIds.isEmpty || _creating ? null : _create,
                  icon: _creating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.share_location_rounded),
                  label: Text(
                    _selectedIds.isEmpty
                        ? 'Kontakte auswählen'
                        : 'Teilen mit ${_selectedIds.length} Kontakt${_selectedIds.length == 1 ? '' : 'en'}',
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAvatar(UserBasePublic user) => UserAvatar(
    imageUrl: user.image,
    displayName: user.displayName,
  );

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}min';
    return '${m}min';
  }
}
