import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/utils/date_utils.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/composite/design_list_tile.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../location_sharing/models/location_sharing_models.dart';

/// Verwaltung eigener Standort-Sharing-Sessions: auflisten, erstellen und
/// beenden. Die App selbst teilt keinen Standort — sie steuert nur die
/// Sessions für Drittanbieter-Tracking-Apps (OsmAnd, GPSLogger, OwnTracks …).
class LocationSharingSettingsScreen extends StatefulWidget {
  const LocationSharingSettingsScreen({super.key});

  @override
  State<LocationSharingSettingsScreen> createState() =>
      _LocationSharingSettingsScreenState();
}

class _LocationSharingSettingsScreenState
    extends State<LocationSharingSettingsScreen> {
  List<LocationSharingSession> _sessions = const [];
  bool _loading = true;
  String? _error;
  bool _didLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoad) {
      _didLoad = true;
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sessions = await AppScope.of(
        context,
      ).locationSharing.listOwnSessions();
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Sessions konnten nicht geladen werden.';
      });
    }
  }

  Future<void> _confirmDelete(LocationSharingSession session) async {
    final tokens = DesignTheme.of(context);
    final confirm = await showDesignSheet<bool>(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DesignText('Session beenden', style: DesignTextStyle.title),
            const SizedBox(height: 8),
            DesignText(
              'Die Session wird beendet. Kontakte können deinen Standort '
              'danach nicht mehr sehen.',
              style: DesignTextStyle.body,
              color: tokens.textHigh,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DesignButton(
                    variant: DesignButtonVariant.text,
                    label: 'Abbrechen',
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DesignButton(
                    label: 'Beenden',
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (confirm != true || !mounted) return;

    try {
      await AppScope.of(context).locationSharing.stopSession(session.id);
      if (!mounted) return;
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session konnte nicht beendet werden.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    return DesignSurface(
      child: Column(
        children: [
          DesignSubpageHeader(
            leading: DesignIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => context.pop(),
            ),
            title: 'Standort teilen',
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(vertical: tokens.spaceMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _explanationCard(),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: DesignText(
                        'Aktive Sessions',
                        style: DesignTextStyle.label,
                        color: tokens.primary,
                      ),
                    ),
                    _sessionList(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _explanationCard() {
    final tokens = DesignTheme.of(context);
    return DesignCard(
      padding: EdgeInsets.all(tokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DesignText('Standort teilen', style: DesignTextStyle.title),
          const SizedBox(height: 4),
          DesignText(
            'Die App teilt selbst keinen Standort. Erstelle eine Session und '
            'nutze eine Tracking-App wie OsmAnd, GPSLogger oder OwnTracks, um '
            'deine Position automatisch zu senden. Die passenden URLs erhältst '
            'du direkt nach dem Erstellen.',
            style: DesignTextStyle.label,
            color: tokens.textLow,
          ),
        ],
      ),
    );
  }

  Widget _sessionList() {
    final tokens = DesignTheme.of(context);

    if (_loading) {
      return Padding(
        padding: EdgeInsets.all(tokens.spaceXl),
        child: Center(child: CircularProgressIndicator(color: tokens.primary)),
      );
    }
    if (_error != null) {
      return Padding(
        padding: EdgeInsets.all(tokens.spaceXl),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 48, color: tokens.danger),
              const SizedBox(height: 8),
              DesignText(_error!),
              const SizedBox(height: 16),
              DesignButton(
                label: 'Erneut versuchen',
                variant: DesignButtonVariant.outlined,
                onPressed: _load,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_sessions.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spaceLg,
              vertical: tokens.spaceMd,
            ),
            child: DesignText(
              'Keine aktiven Sessions.',
              style: DesignTextStyle.body,
              color: tokens.textLow,
            ),
          )
        else
          DesignCard.list(
            children: [
              for (final session in _sessions)
                DesignListTile(
                  leading: Icon(
                    session.sharingMode == SharingMode.route
                        ? Icons.route_rounded
                        : Icons.location_on_rounded,
                  ),
                  title: session.sharingMode.label,
                  subtitle: _sessionSubtitle(session),
                  trailing: DesignIconButton(
                    icon: Icons.delete_rounded,
                    onPressed: () => _confirmDelete(session),
                  ),
                ),
            ],
          ),
        SizedBox(height: tokens.spaceLg),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
          child: DesignButton(
            variant: DesignButtonVariant.filled,
            icon: Icons.add_rounded,
            label: 'Neue Session erstellen',
            fullWidth: true,
            onPressed: () => context.push('/einstellungen/standort/neu'),
          ),
        ),
      ],
    );
  }

  String _sessionSubtitle(LocationSharingSession session) {
    return session.expiresAt == null
        ? 'unbegrenzt'
        : 'bis ${formatDateTime(session.expiresAt!)}';
  }
}
