import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/osm_config.dart';
import '../../../core/di/app_scope.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_avatar.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../models/travel_models.dart';
import '../services/travel_service.dart';

class TravelEventDetailScreen extends StatefulWidget {
  final String id;

  const TravelEventDetailScreen({super.key, required this.id});

  @override
  State<TravelEventDetailScreen> createState() =>
      _TravelEventDetailScreenState();
}

class _TravelEventDetailScreenState extends State<TravelEventDetailScreen> {
  TravelService get _service => AppScope.of(context).travel;

  TravelEvent? _event;
  bool _loading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final event = await _service.getEventUnified(widget.id);
      if (!mounted) return;
      setState(() {
        _event = event;
        _loading = false;
      });
    } catch (e, st) {
      developer.log('Failed to load event', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DesignSurface(
      child: Column(
        children: [
          DesignSubpageHeader(
            leading: DesignIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => context.pop(),
            ),
            title: _event?.name ?? 'Event',
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final tokens = DesignTheme.of(context);
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: tokens.primary));
    }

    if (_error != null) {
      return RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(tokens.spaceXl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DesignText(
                    'Fehler beim Laden des Events',
                    style: DesignTextStyle.body,
                    color: tokens.textHigh,
                  ),
                  SizedBox(height: tokens.spaceMd),
                  DesignButton(
                    variant: DesignButtonVariant.outlined,
                    label: 'Erneut versuchen',
                    onPressed: _load,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final event = _event!;
    final localStart = event.start.toLocal();
    final localEnd = event.end.toLocal();

    String fmt(DateTime dt) {
      final d =
          '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
      final t =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      return '$d $t';
    }

    final hasCoords =
        event.latitude != null && event.longitude != null;

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(tokens.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DesignText(
              event.name,
              style: DesignTextStyle.title,
              color: tokens.textHigh,
            ),
            if (event.description != null && event.description!.isNotEmpty) ...[
              SizedBox(height: tokens.spaceSm),
              DesignText(
                event.description!,
                style: DesignTextStyle.body,
                color: tokens.textHigh,
              ),
            ],
            SizedBox(height: tokens.spaceLg),
            _infoRow(tokens, Icons.schedule_rounded, fmt(localStart)),
            SizedBox(height: tokens.spaceXs),
            _infoRow(tokens, Icons.schedule_rounded, 'bis ${fmt(localEnd)}'),
            if (event.organizer != null) ...[
              SizedBox(height: tokens.spaceXs),
              _infoRow(tokens, Icons.person_rounded, event.organizer!),
            ],
            if (event.address != null) ...[
              SizedBox(height: tokens.spaceXs),
              _infoRow(
                tokens,
                Icons.location_on_rounded,
                event.address!,
              ),
            ],
            if (hasCoords) ...[
              SizedBox(height: tokens.spaceLg),
              ClipRRect(
                borderRadius: BorderRadius.circular(tokens.radiusLg),
                child: SizedBox(
                  height: 180,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(
                        event.latitude!,
                        event.longitude!,
                      ),
                      initialZoom: 14,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all &
                            ~InteractiveFlag.rotate,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: OsmConfig.tileUrlTemplate,
                        userAgentPackageName: OsmConfig.tileUserAgent,
                        tileProvider: osmTileProvider(),
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(
                              event.latitude!,
                              event.longitude!,
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 36,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (event.participants.isNotEmpty) ...[
              SizedBox(height: tokens.spaceXl),
              DesignText(
                'Teilnehmer (${event.participants.length})',
                style: DesignTextStyle.subtitle,
                color: tokens.textHigh,
              ),
              SizedBox(height: tokens.spaceSm),
              Wrap(
                spacing: tokens.spaceSm,
                runSpacing: tokens.spaceSm,
                children: event.participants.map((p) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DesignAvatar(
                        imageUrl: p.image,
                        name: p.displayName,
                        size: 32,
                      ),
                      SizedBox(width: tokens.spaceXs),
                      DesignText(
                        p.displayName,
                        style: DesignTextStyle.label,
                        color: tokens.textHigh,
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(DesignTokens tokens, IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: tokens.textLow),
        SizedBox(width: tokens.spaceSm),
        Expanded(
          child: DesignText(
            text,
            style: DesignTextStyle.body,
            color: tokens.textHigh,
          ),
        ),
      ],
    );
  }
}
