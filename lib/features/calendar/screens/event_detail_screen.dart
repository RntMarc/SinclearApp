import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/utils/date_utils.dart';
import '../models/calendar_models.dart';
import '../services/calendar_service.dart';
import '../widgets/event_form_sheet.dart';

class EventDetailScreen extends StatefulWidget {
  final String id;

  const EventDetailScreen({super.key, required this.id});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  CalendarService get _service => AppScope.of(context).calendar;

  CalendarEvent? _event;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final event = await _service.get(widget.id);
      if (mounted) {
        setState(() {
          _event = event;
          _loading = false;
        });
      }
    } catch (e, st) {
      developer.log('Failed to load event', error: e, stackTrace: st);
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _edit() async {
    if (_event == null) return;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => EventFormSheet(event: _event),
    );

    if (result == null || !mounted) return;

    try {
      await _service.update(
        _event!.id,
        title: result['title'] as String,
        description: result['description'] as String?,
        startTime: result['startTime'] as DateTime,
        endTime: result['endTime'] as DateTime,
        visibility: result['visibility'] as int,
      );
      _load();
    } catch (e, st) {
      developer.log('Failed to update event', error: e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Fehler beim Speichern')));
      }
    }
  }

  Future<void> _delete() async {
    if (_event == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Termin löschen'),
        content: Text('"${_event!.title}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _service.delete(_event!.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e, st) {
      developer.log('Failed to delete event', error: e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Fehler beim Löschen')));
      }
    }
  }

  String _visibilityLabel(int visibility) {
    switch (visibility) {
      case 0:
        return 'Privat';
      case 1:
        return 'Öffentlich';
      case 2:
        return 'Enge Freunde';
      default:
        return 'Unbekannt';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Termin')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _event == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Termin')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Fehler beim Laden des Termins'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _load,
                child: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
      );
    }

    final event = _event!;

    return Scaffold(
      appBar: AppBar(
        title: Text(event.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: _edit,
            tooltip: 'Bearbeiten',
          ),
          IconButton(
            icon: const Icon(Icons.delete_rounded),
            onPressed: _delete,
            tooltip: 'Löschen',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            event.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (event.description != null && event.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(event.description!, style: theme.textTheme.bodyLarge),
          ],
          const SizedBox(height: 24),
          _InfoRow(
            icon: Icons.access_time_rounded,
            label: 'Zeitraum',
            value: formatDateRange(event.startTime, event.endTime),
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.visibility_rounded,
            label: 'Sichtbarkeit',
            value: _visibilityLabel(event.visibility),
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.person_rounded,
            label: 'Erstellt von',
            value: event.creatorId,
          ),
          if (event.participants.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Teilnehmer (${event.participants.length})',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...event.participants.map(
              (p) => ListTile(
                leading: CircleAvatar(
                  child: Text(p.displayName[0].toUpperCase()),
                ),
                title: Text(p.displayName),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(value, style: theme.textTheme.bodyMedium),
          ],
        ),
      ],
    );
  }
}
