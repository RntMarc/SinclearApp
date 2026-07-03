import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/di/app_scope.dart';
import '../models/location_sharing_models.dart';
import 'session_map_screen.dart';

class AllLocationsMapScreen extends StatefulWidget {
  const AllLocationsMapScreen({super.key});

  @override
  State<AllLocationsMapScreen> createState() => _AllLocationsMapScreenState();
}

class _AllLocationsMapScreenState extends State<AllLocationsMapScreen> {
  Timer? _pollTimer;
  bool _loading = true;
  bool _initialized = false;
  final List<_MapItem> _items = [];

  @override
  void initState() {
    super.initState();
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
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final manager = AppScope.of(context).locationSharingManager;
    await Future.wait([
      manager.loadMySessions(),
      manager.loadContactSessions(),
    ]);

    final items = <_MapItem>[];
    for (final s in manager.mySessions) {
      if (s.isActive && s.lastLocation != null) {
        items.add(_MapItem(
          sessionId: s.id,
          name: s.recipients.map((r) => r.displayName).join(', '),
          isOwn: true,
          location: s.lastLocation!,
        ));
      }
    }
    for (final s in manager.contactSessions) {
      if (s.lastLocation != null) {
        items.add(_MapItem(
          sessionId: s.session.id,
          name: s.owner.displayName,
          isOwn: false,
          location: s.lastLocation!,
        ));
      }
    }

    if (!mounted) return;
    setState(() {
      _items..clear()..addAll(items);
      _loading = false;
    });

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.map_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Keine aktiven Standort-Freigaben.',
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    final latAvg = _items
            .map((e) => e.location.latitude)
            .reduce((a, b) => a + b) /
        _items.length;
    final lngAvg = _items
            .map((e) => e.location.longitude)
            .reduce((a, b) => a + b) /
        _items.length;

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(latAvg, lngAvg),
            initialZoom: 12,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'de.sinclear.beyond',
            ),
            MarkerLayer(
              markers: _items
                  .map((item) => Marker(
                        point: LatLng(
                          item.location.latitude,
                          item.location.longitude,
                        ),
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () => _openSession(item),
                          child: Icon(
                            item.isOwn
                                ? Icons.my_location_rounded
                                : Icons.person_pin_circle_rounded,
                            color: item.isOwn ? Colors.blue : Colors.red,
                            size: 40,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_items.length} aktive Freigabe${_items.length == 1 ? '' : 'n'}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openSession(_MapItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SessionMapScreen(
          sessionId: item.sessionId,
          isOwner: item.isOwn,
        ),
      ),
    );
  }
}

class _MapItem {
  final String sessionId;
  final String name;
  final bool isOwn;
  final LocationSharingLocation location;

  const _MapItem({
    required this.sessionId,
    required this.name,
    required this.isOwn,
    required this.location,
  });
}
