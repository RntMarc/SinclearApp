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

class AccommodationDetailScreen extends StatefulWidget {
  final String tripId;
  final String accommodationId;

  const AccommodationDetailScreen({
    super.key,
    required this.tripId,
    required this.accommodationId,
  });

  @override
  State<AccommodationDetailScreen> createState() =>
      _AccommodationDetailScreenState();
}

class _AccommodationDetailScreenState
    extends State<AccommodationDetailScreen> {
  TravelService get _service => AppScope.of(context).travel;

  TravelAccommodation? _accommodation;
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
      final acc = await _service.getAccommodationDetail(
        widget.tripId,
        widget.accommodationId,
      );
      if (!mounted) return;
      setState(() {
        _accommodation = acc;
        _loading = false;
      });
    } catch (e, st) {
      developer.log('Failed to load accommodation', error: e, stackTrace: st);
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
            title: _accommodation?.name ?? 'Unterkunft',
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
                    'Fehler beim Laden der Unterkunft',
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

    final acc = _accommodation!;
    final auth = AppScope.of(context).auth;
    final currentUserId = auth.userId;
    final isMine =
        currentUserId != null && acc.users.any((u) => u.id == currentUserId);
    final hasCoords = acc.latitude != null && acc.longitude != null;

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(tokens.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  acc.ishotel == 1
                      ? Icons.hotel_rounded
                      : Icons.home_rounded,
                  color: isMine ? tokens.primary : tokens.textHigh,
                  size: 28,
                ),
                SizedBox(width: tokens.spaceSm),
                Expanded(
                  child: DesignText(
                    acc.name,
                    style: DesignTextStyle.title,
                    color: tokens.textHigh,
                  ),
                ),
              ],
            ),
            if (acc.description != null &&
                acc.description!.isNotEmpty) ...[
              SizedBox(height: tokens.spaceSm),
              DesignText(
                acc.description!,
                style: DesignTextStyle.body,
                color: tokens.textHigh,
              ),
            ],
            SizedBox(height: tokens.spaceLg),
            if (acc.address != null) ...[
              _infoRow(tokens, Icons.location_on_rounded, acc.address!),
              SizedBox(height: tokens.spaceXs),
            ],
            if (acc.phone != null) ...[
              _infoRow(tokens, Icons.phone_rounded, acc.phone!),
              SizedBox(height: tokens.spaceXs),
            ],
            if (acc.mail != null) ...[
              _infoRow(tokens, Icons.mail_rounded, acc.mail!),
              SizedBox(height: tokens.spaceXs),
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
                        acc.latitude!,
                        acc.longitude!,
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
                              acc.latitude!,
                              acc.longitude!,
                            ),
                            child: Icon(
                              Icons.location_on,
                              color:
                                  isMine ? tokens.primary : Colors.red,
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
            if (acc.users.isNotEmpty) ...[
              SizedBox(height: tokens.spaceXl),
              DesignText(
                'Zugeordnete Nutzer (${acc.users.length})',
                style: DesignTextStyle.subtitle,
                color: tokens.textHigh,
              ),
              SizedBox(height: tokens.spaceSm),
              Wrap(
                spacing: tokens.spaceSm,
                runSpacing: tokens.spaceSm,
                children: acc.users.map((u) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DesignAvatar(
                        imageUrl: u.image,
                        name: u.displayName,
                        size: 32,
                      ),
                      SizedBox(width: tokens.spaceXs),
                      DesignText(
                        u.displayName,
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
