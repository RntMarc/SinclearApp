import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/di/app_scope.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_list_tile.dart';
import '../../../design/widgets/composite/design_map_card.dart';
import '../../../design/widgets/composite/design_map_marker.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_avatar.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../models/location_sharing_models.dart';

/// Zeigt die Standorte der Kontakte an, die ihren Standort mit dem aktuellen
/// Nutzer teilen (`GET /location-sharing/active`).
class LocationSharingScreen extends StatefulWidget {
  const LocationSharingScreen({super.key});

  @override
  State<LocationSharingScreen> createState() => _LocationSharingScreenState();
}

class _LocationSharingScreenState extends State<LocationSharingScreen>
    with WidgetsBindingObserver {
  static const _pollInterval = Duration(seconds: 30);

  List<ActiveLocationSharing> _items = const [];
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
      final items = await AppScope.of(
        context,
      ).locationSharing.listActiveContacts();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
        _refreshing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _refreshing = false;
        if (_items.isEmpty) {
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
              child: _items.isEmpty ? _emptyState(context) : _content(context),
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
              _items.isEmpty
                  ? 'Keine geteilten Standorte'
                  : '${_items.length} ${_items.length == 1 ? 'Standort' : 'Standorte'} geteilt',
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
    final markers = _items
        .where((a) => a.lastLocation != null)
        .map(
          (a) => designMapMarker(
            point: LatLng(a.lastLocation!.latitude, a.lastLocation!.longitude),
            icon: Icons.person_pin_circle_rounded,
            color: tokens.primary,
            onTap: () => context.push('/standort/${a.session.id}', extra: a),
          ),
        )
        .toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (markers.isNotEmpty)
          DesignMapCard(
            markers: markers,
            height: 220,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: DesignText(
            'Kontakte',
            style: DesignTextStyle.label,
            color: tokens.primary,
          ),
        ),
        DesignCard.list(
          children: [for (final item in _items) _contactTile(context, item)],
        ),
      ],
    );
  }

  Widget _contactTile(BuildContext context, ActiveLocationSharing item) {
    final tokens = DesignTheme.of(context);
    final loc = item.lastLocation;
    return DesignListTile(
      leading: DesignAvatar(
        imageUrl: item.ownerImage,
        name: item.ownerDisplayName,
        size: 40,
      ),
      title: item.ownerDisplayName,
      subtitle: loc != null
          ? 'Zuletzt ${_relative(loc.recordedAt)}'
          : 'Noch kein Standort gesendet',
      trailing: Icon(Icons.chevron_right_rounded, color: tokens.textLow),
      onTap: () => context.push('/standort/${item.session.id}', extra: item),
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
