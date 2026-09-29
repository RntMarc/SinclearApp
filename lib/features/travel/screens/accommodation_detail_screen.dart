import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/network/api_client.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/composite/design_map_card.dart';
import '../../../design/widgets/composite/design_map_marker.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_avatar.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../../core/widgets/open_in_map_button.dart';
import '../../../core/utils/map_helper.dart';
import '../../moderation/models/moderation_models.dart';
import '../../moderation/widgets/moderation_request_sheet.dart';
import '../models/travel_models.dart';
import '../services/travel_service.dart';
import '../travel_error_messages.dart';

class AccommodationDetailScreen extends StatefulWidget {
  final String tripId;
  final String accommodationId;
  final bool canEdit;

  const AccommodationDetailScreen({
    super.key,
    required this.tripId,
    required this.accommodationId,
    this.canEdit = false,
  });

  @override
  State<AccommodationDetailScreen> createState() =>
      _AccommodationDetailScreenState();
}

class _AccommodationDetailScreenState extends State<AccommodationDetailScreen> {
  TravelService get _service => AppScope.of(context).travel;

  TravelAccommodation? _accommodation;
  bool _loading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading) _load();
  }

  /// Ob der aktuelle Nutzer die Katalog-Unterkunft angelegt hat.
  bool get _isCreator {
    final acc = _accommodation;
    final userId = AppScope.of(context).auth.userId;
    return acc?.createdBy != null && acc!.createdBy == userId;
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
            actions: [
              if (widget.canEdit || _isCreator)
                DesignIconButton(
                  icon: Icons.more_vert_rounded,
                  onPressed: _openMenu,
                ),
              if (_accommodation != null)
                DesignIconButton(icon: Icons.flag_rounded, onPressed: _report),
            ],
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  void _openMenu() {
    final acc = _accommodation;
    if (acc == null) return;
    final currentUserId = AppScope.of(context).auth.userId;
    final isCreator = acc.createdBy != null && acc.createdBy == currentUserId;
    final tokens = DesignTheme.of(context);
    showDesignSheet(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DesignText(
            acc.name,
            style: DesignTextStyle.subtitle,
            color: tokens.textHigh,
          ),
          SizedBox(height: tokens.spaceMd),
          Padding(
            padding: EdgeInsets.symmetric(vertical: tokens.spaceXs),
            child: DesignButton(
              label: 'Bearbeiten',
              variant: DesignButtonVariant.text,
              icon: Icons.edit_rounded,
              fullWidth: true,
              onPressed: () async {
                Navigator.of(context).pop();
                final changed = await context.push<bool>(
                  '/reisen/${widget.tripId}/unterkunft/${widget.accommodationId}/bearbeiten',
                );
                if (changed == true && mounted) _load();
              },
            ),
          ),
          if (widget.canEdit)
            Padding(
              padding: EdgeInsets.symmetric(vertical: tokens.spaceXs),
              child: DesignButton(
                label: 'Von Reise entfernen',
                variant: DesignButtonVariant.text,
                icon: Icons.link_off_rounded,
                fullWidth: true,
                onPressed: () {
                  Navigator.of(context).pop();
                  _confirmDelete();
                },
              ),
            ),
          if (isCreator)
            Padding(
              padding: EdgeInsets.symmetric(vertical: tokens.spaceXs),
              child: DesignButton(
                label: 'Aus Katalog löschen',
                variant: DesignButtonVariant.ghost,
                icon: Icons.delete_outline_rounded,
                fullWidth: true,
                onPressed: () {
                  Navigator.of(context).pop();
                  _confirmDeleteGlobal();
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteGlobal() async {
    final tokens = DesignTheme.of(context);
    final confirmed = await showDesignSheet<bool>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DesignText(
            'Unterkunft endgültig löschen?',
            style: DesignTextStyle.subtitle,
            color: tokens.textHigh,
          ),
          SizedBox(height: tokens.spaceSm),
          DesignText(
            'Die Unterkunft wird aus dem Katalog entfernt und ist für alle '
            'Reisen nicht mehr verfügbar.',
            style: DesignTextStyle.body,
            color: tokens.textLow,
          ),
          SizedBox(height: tokens.spaceMd),
          Row(
            children: [
              Expanded(
                child: DesignButton(
                  label: 'Abbrechen',
                  variant: DesignButtonVariant.outlined,
                  onPressed: () => Navigator.pop(context, false),
                ),
              ),
              SizedBox(width: tokens.spaceMd),
              Expanded(
                child: DesignButton(
                  label: 'Löschen',
                  onPressed: () => Navigator.pop(context, true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _service.deleteAccommodationGlobal(widget.accommodationId);
      if (mounted) context.pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(travelErrorMessage(e))));
    } catch (e, st) {
      developer.log(
        'Failed to delete accommodation globally',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fehler beim Löschen.')));
    }
  }

  Future<void> _confirmDelete() async {
    final tokens = DesignTheme.of(context);
    final confirmed = await showDesignSheet<bool>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DesignText(
            'Unterkunft von der Reise entfernen?',
            style: DesignTextStyle.subtitle,
            color: tokens.textHigh,
          ),
          SizedBox(height: tokens.spaceSm),
          DesignText(
            'Der Eintrag bleibt im Katalog und kann in anderen Reisen '
            'weiterverwendet werden.',
            style: DesignTextStyle.body,
            color: tokens.textLow,
          ),
          SizedBox(height: tokens.spaceMd),
          Row(
            children: [
              Expanded(
                child: DesignButton(
                  label: 'Abbrechen',
                  variant: DesignButtonVariant.outlined,
                  onPressed: () => Navigator.pop(context, false),
                ),
              ),
              SizedBox(width: tokens.spaceMd),
              Expanded(
                child: DesignButton(
                  label: 'Entfernen',
                  onPressed: () => Navigator.pop(context, true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _service.deleteAccommodation(widget.tripId, widget.accommodationId);
      if (mounted) context.pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(travelErrorMessage(e))));
    } catch (e, st) {
      developer.log('Failed to delete accommodation', error: e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fehler beim Löschen.')));
    }
  }

  Future<void> _report() async {
    final acc = _accommodation;
    if (acc == null) return;
    await showModerationRequestSheet(
      context,
      objectType: ModerationObjectType.travelAccommodation,
      objectId: acc.id,
      objectName: acc.name,
      isOwn: widget.canEdit || _isCreator,
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
            if (acc.description != null && acc.description!.isNotEmpty) ...[
              DesignText(
                acc.description!,
                style: DesignTextStyle.body,
                color: tokens.textHigh,
              ),
              _infoRow(tokens, Icons.location_on_rounded, acc.address!),
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
              Stack(
                children: [
                  DesignMapCard(
                    center: LatLng(acc.latitude!, acc.longitude!),
                    initialZoom: 14,
                    markers: [
                      designMapMarker(
                        point: LatLng(acc.latitude!, acc.longitude!),
                        icon: Icons.location_on_rounded,
                        color: isMine ? tokens.primary : tokens.danger,
                      ),
                    ],
                    height: 180,
                    interactive: true,
                  ),
                  OpenInMapButton(
                    target: MapTarget(
                      latitude: acc.latitude!,
                      longitude: acc.longitude!,
                      osmId: acc.osmId,
                      label: acc.name,
                    ),
                  ),
                ],
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
