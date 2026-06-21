import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/app_scope.dart';
import '../models/travel_models.dart';
import '../services/travel_service.dart';

class TravelScreen extends StatefulWidget {
  const TravelScreen({super.key});

  @override
  State<TravelScreen> createState() => _TravelScreenState();
}

class _TravelScreenState extends State<TravelScreen> {
  TravelService get _service => AppScope.of(context).travel;

  bool _loading = true;
  String? _error;
  List<TimelineEntry> _current = [];
  List<TimelineEntry> _future = [];
  List<TimelineEntry> _past = [];
  bool _hasLoaded = false;

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
      final tripsFuture = _service.list(limit: 100);
      final standaloneFuture = _service.getStandaloneEvents(limit: 100);
      final results = await Future.wait([tripsFuture, standaloneFuture]);

      final trips = results[0] as TravelTripListResponse;
      final standalone = results[1] as TravelStandaloneEventListResponse;

      final entries = <TimelineEntry>[
        for (final t in trips.data)
          TimelineEntry(
            id: t.id,
            name: t.name,
            description: t.description,
            start: t.start,
            end: t.end,
            isTrip: true,
          ),
        for (final e in standalone.data)
          TimelineEntry(
            id: e.id,
            name: e.name,
            description: e.description,
            start: e.start,
            end: e.end,
            isTrip: false,
          ),
      ];

      final now = DateTime.now();
      final current = <TimelineEntry>[];
      final future = <TimelineEntry>[];
      final past = <TimelineEntry>[];

      for (final entry in entries) {
        if (entry.start.isBefore(now) && entry.end.isAfter(now)) {
          current.add(entry);
        } else if (entry.start.isAfter(now)) {
          future.add(entry);
        } else {
          past.add(entry);
        }
      }

      current.sort((a, b) => a.start.compareTo(b.start));
      future.sort((a, b) => a.start.compareTo(b.start));
      past.sort((a, b) => b.end.compareTo(a.end));

      setState(() {
        _current = current;
        _future = future;
        _past = past;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Fehler beim Laden der Reisen'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _load,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    final hasEntries =
        _current.isNotEmpty || _future.isNotEmpty || _past.isNotEmpty;

    if (!hasEntries) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_rounded, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Keine Reisen oder Events gefunden',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        if (_current.isNotEmpty) ..._buildSection('Aktuelle Reisen', _current),
        if (_future.isNotEmpty) ..._buildSection('Kommende Reisen', _future),
        if (_past.isNotEmpty) ..._buildSection('Vergangene Reisen', _past),
      ],
    );
  }

  List<Widget> _buildSection(String title, List<TimelineEntry> entries) {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ),
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _TimelineCard(
            entry: entries[index],
            onTap: entries[index].isTrip
                ? () => context.go('/reisen/${entries[index].id}')
                : null,
          ),
          childCount: entries.length,
        ),
      ),
    ];
  }
}

class _TimelineCard extends StatelessWidget {
  final TimelineEntry entry;
  final VoidCallback? onTap;

  const _TimelineCard({required this.entry, this.onTap});

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: entry.isTrip
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.secondaryContainer,
          child: Icon(
            entry.isTrip ? Icons.flight_rounded : Icons.event_rounded,
            color: entry.isTrip
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSecondaryContainer,
          ),
        ),
        title: Text(
          entry.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${_formatDate(entry.start)} – ${_formatDate(entry.end)}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: entry.isTrip ? const Icon(Icons.chevron_right_rounded) : null,
        onTap: onTap,
      ),
    );
  }
}
