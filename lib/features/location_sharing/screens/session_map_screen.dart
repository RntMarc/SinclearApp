import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/utils/date_utils.dart';
import '../models/location_sharing_models.dart';

class SessionMapScreen extends StatefulWidget {
  final String sessionId;
  final bool isOwner;

  const SessionMapScreen({
    super.key,
    required this.sessionId,
    this.isOwner = false,
  });

  @override
  State<SessionMapScreen> createState() => _SessionMapScreenState();
}

class _SessionMapScreenState extends State<SessionMapScreen> {
  LocationSharingSessionDetail? _session;
  List<LocationSharingLocation> _locations = [];
  Timer? _pollTimer;
  bool _loading = true;
  bool _initialized = false;

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
    try {
      final service = AppScope.of(context).locationSharing;
      final detail = await service.getSessionDetail(widget.sessionId);
      final locations = await service.getLocations(widget.sessionId);
      if (!mounted) return;
      setState(() {
        _session = detail;
        _locations = locations;
        _loading = false;
      });

      final freq = detail.frequencySeconds;
      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(
        Duration(seconds: freq),
        (_) => _poll(),
      );
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _poll() async {
    try {
      final since = _locations.isNotEmpty
          ? parseApiDate(_locations.last.createdAt)
          : null;
      final service = AppScope.of(context).locationSharing;
      final newLocations = await service.getLocations(
        widget.sessionId,
        since: since,
      );
      if (!mounted) return;
      if (newLocations.isNotEmpty) {
        setState(() => _locations.addAll(newLocations));
      }
    } catch (_) {}
  }

  LatLng? get _center {
    if (_locations.isNotEmpty) {
      final last = _locations.last;
      return LatLng(last.latitude, last.longitude);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final center = _center;

    return Scaffold(
      appBar: AppBar(
        titleTextStyle: theme.textTheme.titleMedium,
        title: Text(
          widget.isOwner ? 'Mein Standort' : (_session?.recipients.isNotEmpty == true
              ? 'Standort von ${_session!.recipients.first.displayName}'
              : 'Standort'),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : center == null
              ? Center(
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
                        'Noch keine Standortdaten verfügbar.',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCenter: center,
                        initialZoom: 15,
                        interactionOptions: InteractionOptions(
                          flags: InteractiveFlag.all &
                              ~InteractiveFlag.rotate,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'de.sinclear.beyond',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: center,
                              width: 40,
                              height: 40,
                              child: Icon(
                                widget.isOwner
                                    ? Icons.my_location_rounded
                                    : Icons.person_pin_circle_rounded,
                                color: widget.isOwner
                                    ? Colors.blue
                                    : Colors.red,
                                size: 40,
                              ),
                            ),
                            if (_locations.length > 1)
                              ..._buildPathMarkers(),
                          ],
                        ),
                        if (_locations.length > 1)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _locations
                                    .map((l) => LatLng(l.latitude, l.longitude))
                                    .toList(),
                                color: Colors.blue.withValues(alpha: 0.4),
                                strokeWidth: 3,
                              ),
                            ],
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
                              const Icon(Icons.update_rounded, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Aktualisiert: ${_timeAgo(_locations.last.recordedAt)}',
                                style: theme.textTheme.bodySmall,
                              ),
                              const Spacer(),
                              if (_locations.last.accuracy != null)
                                Text(
                                  '±${_locations.last.accuracy!.toStringAsFixed(0)}m',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  List<Marker> _buildPathMarkers() {
    return _locations.sublist(0, _locations.length - 1).map((loc) {
      return Marker(
        point: LatLng(loc.latitude, loc.longitude),
        width: 12,
        height: 12,
        child: Icon(
          Icons.circle,
          size: 12,
          color: Colors.blue.withValues(alpha: 0.3),
        ),
      );
    }).toList();
  }

  String _timeAgo(String dt) {
    final parsed = parseApiDate(dt);
    if (parsed == null) return 'unbekannt';
    final diff = DateTime.now().difference(parsed);
    if (diff.inSeconds < 60) return 'gerade eben';
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} Min';
    return 'vor ${diff.inHours}h';
  }
}
