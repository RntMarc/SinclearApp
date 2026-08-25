import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/config/osm_config.dart';
import '../../../core/di/app_scope.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_list_tile.dart';
import '../../../design/widgets/composite/design_map_marker.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_avatar.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../models/location_sharing_models.dart';

/// Ein Eintrag auf der gemeinsamen Karte: entweder ein Kontakt, der seinen
/// Standort teilt, oder eine eigene (von der App verwaltete) Session.
class _SharedEntry {
  final String sessionId;
  final SharingMode sharingMode;
  final String displayName;
  final String? image;
  final LocationSharingLocation? lastLocation;
  final bool isOwn;

  const _SharedEntry({
    required this.sessionId,
    required this.sharingMode,
    required this.displayName,
    this.image,
    this.lastLocation,
    this.isOwn = false,
  });
}

/// Zeigt alle geteilten Standorte auf einer gemeinsamen Karte: die Standorte
/// der Kontakte (`GET /location-sharing/active`) und die eigene Position
/// (`GET /location-sharing/sessions` + Detail).
class LocationSharingScreen extends StatefulWidget {
  const LocationSharingScreen({super.key});

  @override
  State<LocationSharingScreen> createState() => _LocationSharingScreenState();
}

class _LocationSharingScreenState extends State<LocationSharingScreen>
    with WidgetsBindingObserver {
  static const _pollInterval = Duration(seconds: 30);

  List<_SharedEntry> _entries = const [];
  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  bool _didLoad = false;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoad) {
      _didLoad = true;
      WidgetsBinding.instance.addObserver(this);
      _refresh();
      _startPolling();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(_pollInterval, (_) => _refresh());
  }

  Future<void> _refresh() async {
    setState(() {
      _refreshing = true;
      _error = null;
    });
    try {
      final service = AppScope.of(context).locationSharing;
      final results = await Future.wait([
        service.listActiveContacts(),
        service.listOwnSessionsWithLocation(),
      ]);
      if (!mounted) return;
      final incoming = results[0] as List<ActiveLocationSharing>;
      final own = results[1] as List<LocationSharingSession>;
      setState(() {
        _entries = [
          ...incoming.map(
            (a) => _SharedEntry(
              sessionId: a.session.id,
              sharingMode: a.session.sharingMode,
              displayName: a.ownerDisplayName,
              image: a.ownerImage,
              lastLocation: a.lastLocation,
            ),
          ),
          ...own.map(
            (s) => _SharedEntry(
              sessionId: s.id,
              sharingMode: s.sharingMode,
              displayName: 'Du',
              lastLocation: s.lastLocation,
              isOwn: true,
            ),
          ),
        ];
        _loading = false;
        _refreshing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _refreshing = false;
        if (_entries.isEmpty) {
          _error = 'Standorte konnten nicht geladen werden.';
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    if (_loading) {
      return DesignSurface(
        child: Center(child: CircularProgressIndicator(color: tokens.primary)),
      );
    }

    if (_error != null) {
      return DesignSurface(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: tokens.danger),
              const SizedBox(height: 8),
              DesignText(_error!),
              const SizedBox(height: 16),
              DesignButton(
                label: 'Erneut versuchen',
                variant: DesignButtonVariant.outlined,
                onPressed: _refresh,
              ),
            ],
          ),
        ),
      );
    }

    return DesignSurface(
      child: Column(
        children: [
          _toolbar(context),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: _entries.isEmpty
                  ? _emptyState(context)
                  : _content(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolbar(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLg,
        tokens.spaceSm,
        tokens.spaceLg,
        tokens.spaceXs,
      ),
      child: Row(
        children: [
          Expanded(
            child: DesignText(
              _entries.isEmpty
                  ? 'Keine geteilten Standorte'
                  : '${_entries.length} ${_entries.length == 1 ? 'Standort' : 'Standorte'} geteilt',
              style: DesignTextStyle.label,
              color: tokens.textLow,
            ),
          ),
          DesignIconButton(
            icon: Icons.settings_rounded,
            onPressed: () => context.push('/einstellungen/standort'),
          ),
          const SizedBox(width: 4),
          DesignIconButton(
            icon: _refreshing
                ? Icons.hourglass_top_rounded
                : Icons.refresh_rounded,
            onPressed: _refreshing ? null : _refresh,
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: tokens.spaceXl * 2),
        const Icon(Icons.location_off_rounded, size: 48),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: DesignText(
            'Noch niemand teilt seinen Standort mit dir. Du kannst in den '
            'Einstellungen eine eigene Session erstellen und deinen Standort '
            'mit Kontakten teilen.',
            style: DesignTextStyle.body,
            color: tokens.textLow,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: DesignButton(
            label: 'Zu den Einstellungen',
            variant: DesignButtonVariant.outlined,
            icon: Icons.settings_rounded,
            onPressed: () => context.push('/einstellungen/standort'),
          ),
        ),
      ],
    );
  }

  Widget _content(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _bundledMap(context),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: DesignText(
            'Standorte',
            style: DesignTextStyle.label,
            color: tokens.primary,
          ),
        ),
        DesignCard.list(
          children: [for (final e in _entries) _entryTile(context, e)],
        ),
      ],
    );
  }

  Widget _bundledMap(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final located = _entries.where((e) => e.lastLocation != null).toList();

    if (located.isEmpty) {
      return DesignCard(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: SizedBox(
          height: 220,
          child: Center(
            child: DesignText(
              'Noch keine Standorte verfügbar',
              style: DesignTextStyle.label,
              color: tokens.textLow,
            ),
          ),
        ),
      );
    }

    final points = located
        .map((e) => LatLng(e.lastLocation!.latitude, e.lastLocation!.longitude))
        .toList();

    final markers = located.map((e) {
      final point = LatLng(e.lastLocation!.latitude, e.lastLocation!.longitude);
      return designMapMarker(
        point: point,
        icon: e.isOwn
            ? Icons.my_location_rounded
            : Icons.person_pin_circle_rounded,
        color: e.isOwn ? tokens.accentA : tokens.primary,
        onTap: () =>
            context.push('/standort/${e.sessionId}', extra: e.displayName),
      );
    }).toList();

    final circles = located
        .where(
          (e) =>
              e.lastLocation!.accuracy != null && e.lastLocation!.accuracy! > 0,
        )
        .map(
          (e) => CircleMarker(
            point: LatLng(e.lastLocation!.latitude, e.lastLocation!.longitude),
            radius: e.lastLocation!.accuracy!,
            useRadiusInMeter: true,
            color: tokens.primary.withValues(alpha: 0.12),
            borderStrokeWidth: 1.5,
            borderColor: tokens.primary.withValues(alpha: 0.35),
          ),
        )
        .toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        boxShadow: tokens.surfaceShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        child: SizedBox(
          height: 240,
          child: FlutterMap(
            options: MapOptions(
              initialCameraFit: CameraFit.bounds(
                bounds: LatLngBounds.fromPoints(points),
                padding: const EdgeInsets.all(40),
                maxZoom: 16,
              ),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: OsmConfig.tileUrlTemplate,
                userAgentPackageName: OsmConfig.tileUserAgent,
                tileProvider: osmTileProvider(),
              ),
              if (circles.isNotEmpty) CircleLayer(circles: circles),
              MarkerLayer(markers: markers),
            ],
          ),
        ),
      ),
    );
  }

  Widget _entryTile(BuildContext context, _SharedEntry entry) {
    final tokens = DesignTheme.of(context);
    final loc = entry.lastLocation;
    return DesignListTile(
      leading: DesignAvatar(
        imageUrl: entry.image,
        name: entry.displayName,
        size: 40,
      ),
      title: entry.isOwn ? 'Du' : entry.displayName,
      subtitle: loc != null
          ? 'Zuletzt ${_relative(loc.recordedAt)}'
          : 'Noch kein Standort gesendet',
      trailing: Icon(Icons.chevron_right_rounded, color: tokens.textLow),
      onTap: () => context.push(
        '/standort/${entry.sessionId}',
        extra: entry.displayName,
      ),
    );
  }

  String _relative(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.isNegative) return 'gerade eben';
    if (diff.inMinutes < 1) return 'gerade eben';
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} Min.';
    if (diff.inHours < 24) return 'vor ${diff.inHours} Std.';
    return 'vor ${diff.inDays} Tagen';
  }
}
