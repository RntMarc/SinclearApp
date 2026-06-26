import 'dart:developer' as developer;
import 'package:flutter/cupertino.dart';
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
  bool _hasLoaded = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      _hasLoaded = true;
      _load();
    }
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

    final result = await showCupertinoModalPopup<Map<String, dynamic>>(
      context: context,
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
        showCupertinoDialog<void>(
          context: context,
          builder: (_) => const CupertinoAlertDialog(
            content: Text('Fehler beim Speichern'),
          ),
        );
      }
    }
  }

  Future<void> _delete() async {
    if (_event == null) return;

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Termin loschen'),
        content: Text('"${_event!.title}" wirklich loschen?'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Loschen'),
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
        showCupertinoDialog<void>(
          context: context,
          builder: (_) => const CupertinoAlertDialog(
            content: Text('Fehler beim Loschen'),
          ),
        );
      }
    }
  }

  String _visibilityLabel(int visibility) {
    switch (visibility) {
      case 0:
        return 'Privat';
      case 1:
        return 'Offentlich';
      case 2:
        return 'Enge Freunde';
      default:
        return 'Unbekannt';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    if (_loading) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Termin'),
        ),
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }

    if (_error != null || _event == null) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Termin'),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Fehler beim Laden des Termins'),
              const SizedBox(height: 8),
              CupertinoButton(
                onPressed: _load,
                child: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
      );
    }

    final event = _event!;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(event.title),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _edit,
              child: const Icon(CupertinoIcons.pencil, size: 20),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _delete,
              child: const Icon(
                CupertinoIcons.trash,
                size: 20,
                color: CupertinoColors.destructiveRed,
              ),
            ),
          ],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            event.title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.textStyle.color,
            ),
          ),
          if (event.description != null && event.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              event.description!,
              style: TextStyle(
                fontSize: 16,
                color: theme.textTheme.textStyle.color,
              ),
            ),
          ],
          const SizedBox(height: 24),
          _InfoRow(
            icon: CupertinoIcons.clock,
            label: 'Zeitraum',
            value: formatDateRange(event.startTime, event.endTime),
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: CupertinoIcons.eye,
            label: 'Sichtbarkeit',
            value: _visibilityLabel(event.visibility),
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: CupertinoIcons.person,
            label: 'Erstellt von',
            value: event.creatorId,
          ),
          if (event.participants.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Teilnehmer (${event.participants.length})',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.textStyle.color,
              ),
            ),
            const SizedBox(height: 8),
            ...event.participants.map(
              (p) => Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    ClipOval(
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            p.displayName[0].toUpperCase(),
                            style: TextStyle(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      p.displayName,
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.textTheme.textStyle.color,
                      ),
                    ),
                  ],
                ),
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
    final theme = CupertinoTheme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: CupertinoColors.systemGrey),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: CupertinoColors.systemGrey,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                color: theme.textTheme.textStyle.color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
