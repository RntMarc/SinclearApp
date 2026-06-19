import 'package:flutter/material.dart';
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
  List<TravelTrip> _current = [];
  List<TravelTrip> _future = [];
  List<TravelTrip> _past = [];

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _service.list(limit: 100);
      final now = DateTime.now();
      final current = <TravelTrip>[];
      final future = <TravelTrip>[];
      final past = <TravelTrip>[];

      for (final trip in response.data) {
        if (trip.start.isBefore(now) && trip.end.isAfter(now)) {
          current.add(trip);
        } else if (trip.start.isAfter(now)) {
          future.add(trip);
        } else {
          past.add(trip);
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
            Text('Fehler beim Laden der Reisen'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadTrips,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    final hasTrips =
        _current.isNotEmpty || _future.isNotEmpty || _past.isNotEmpty;

    if (!hasTrips) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flight_rounded, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Keine Reisen gefunden',
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

  List<Widget> _buildSection(String title, List<TravelTrip> trips) {
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
          (context, index) => _TripCard(trip: trips[index]),
          childCount: trips.length,
        ),
      ),
    ];
  }
}

class _TripCard extends StatelessWidget {
  final TravelTrip trip;

  const _TripCard({required this.trip});

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  IconData _iconForCategory(String name) {
    if (name.contains('Urlaub') || name.contains('Strand')) {
      return Icons.beach_access_rounded;
    }
    if (name.contains('Stadt') || name.contains('City')) {
      return Icons.location_city_rounded;
    }
    if (name.contains('Wandern') || name.contains('Berg')) {
      return Icons.terrain_rounded;
    }
    if (name.contains('Camping') || name.contains('Zelten')) {
      return Icons.fireplace_rounded;
    }
    return Icons.flight_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = _iconForCategory(trip.name);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
        ),
        title: Text(trip.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${_formatDate(trip.start)} – ${_formatDate(trip.end)}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
