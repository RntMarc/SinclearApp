import 'dart:developer' as developer;

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
  bool _creating = false;
  String _sharingMode = 'location';

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

  Future<void> _create() async {
    if (_selectedIds.isEmpty) return;
    setState(() => _creating = true);
    try {
      final scope = AppScope.of(context);
      final session = await scope.locationSharingManager.createSession(
        recipientIds: _selectedIds.toList(),
        frequencySeconds: 600,
        sharingMode: _sharingMode,
      );
      if (!mounted) return;
      if (session != null) {
        context.go('/standort-teilen/einrichten', extra: session);
      } else {
        final error = scope.locationSharingManager.error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Fehler beim Erstellen der Sitzung'),
          ),
        );
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
                Text(
                  'Teilen-Modus',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'location',
                      label: Text('Live-Standort'),
                      icon: Icon(Icons.my_location_rounded),
                    ),
                    ButtonSegment(
                      value: 'route',
                      label: Text('Route aufzeichnen'),
                      icon: Icon(Icons.route_rounded),
                    ),
                  ],
                  selected: {_sharingMode},
                  onSelectionChanged: (v) =>
                      setState(() => _sharingMode = v.first),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kann nach dem Erstellen nicht mehr geändert werden.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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
}
