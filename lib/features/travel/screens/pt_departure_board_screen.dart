import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/utils/date_utils.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../models/pt_models.dart';

class PtDepartureBoardScreen extends StatefulWidget {
  final String stationId;
  final String stationName;

  const PtDepartureBoardScreen({
    required this.stationId,
    required this.stationName,
    super.key,
  });

  @override
  State<PtDepartureBoardScreen> createState() =>
      _PtDepartureBoardScreenState();
}

class _PtDepartureBoardScreenState extends State<PtDepartureBoardScreen> {
  List<PtDeparture> _departures = [];
  bool _loading = true;
  String? _error;
  bool _arriveBy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = AppScope.of(context).publicTransport;
      final departures = await service.getStationDepartures(
        widget.stationId,
        arriveBy: _arriveBy,
      );
      if (!mounted) return;
      setState(() {
        _departures = departures;
        _loading = false;
      });
    } catch (e, st) {
      developer.log('Failed to load departures', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    return DesignSurface(
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            DesignSubpageHeader(
              title: widget.stationName,
              leading: DesignIconButton(
                icon: Icons.arrow_back_rounded,
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                DesignIconButton(
                  icon: _arriveBy
                      ? Icons.login_rounded
                      : Icons.logout_rounded,
                  onPressed: () {
                    setState(() => _arriveBy = !_arriveBy);
                    _load();
                  },
                ),
                DesignIconButton(
                  icon: Icons.refresh_rounded,
                  onPressed: _load,
                ),
              ],
            ),
            Expanded(child: _buildBody(tokens)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(DesignTokens tokens) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: tokens.primary));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DesignText(
              'Fehler beim Laden',
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
      );
    }

    if (_departures.isEmpty) {
      return Center(
        child: DesignText(
          'Keine ${_arriveBy ? 'Ankünfte' : 'Abfahrten'} gefunden',
          style: DesignTextStyle.body,
          color: tokens.textLow,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(
          tokens.spaceLg,
          tokens.spaceSm,
          tokens.spaceLg,
          tokens.spaceXl,
        ),
        itemCount: _departures.length,
        separatorBuilder: (_, _) => SizedBox(height: tokens.spaceXs),
        itemBuilder: (context, index) {
          final dep = _departures[index];
          return _DepartureCard(dep: dep);
        },
      ),
    );
  }
}

class _DepartureCard extends StatelessWidget {
  const _DepartureCard({required this.dep});

  final PtDeparture dep;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final localTime = dep.departure?.toLocal();

    return DesignCard(
      child: Row(
        children: [
              Icon(ptModeIcon(dep.mode), color: tokens.primary, size: 24),
          SizedBox(width: tokens.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DesignText(
                  dep.lineName,
                  style: DesignTextStyle.body,
                  color: tokens.textHigh,
                ),
                SizedBox(height: tokens.spaceXs),
                Row(
                  children: [
                    if (localTime != null)
                      DesignText(
                        formatTime(localTime),
                        style: DesignTextStyle.label,
                        color: tokens.textLow,
                      ),
                    if (dep.platform != null) ...[
                      SizedBox(width: tokens.spaceSm),
                      DesignText(
                        'Gleis ${dep.platform}',
                        style: DesignTextStyle.label,
                        color: tokens.textLow,
                      ),
                    ],
                    if (dep.headsign != null) ...[
                      SizedBox(width: tokens.spaceSm),
                      DesignText(
                        '→ ${dep.headsign}',
                        style: DesignTextStyle.label,
                        color: tokens.textLow,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
