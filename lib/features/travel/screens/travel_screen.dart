import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/app_scope.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_card.dart';
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
  List<TimelineEntry> _current = [];
  List<TimelineEntry> _future = [];
  List<TimelineEntry> _past = [];
  bool _hasLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      _hasLoaded = true;
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final tripsFuture = _service.list(limit: 100);
      final standaloneFuture = _service.getStandaloneEvents(limit: 100);
      final results = await Future.wait([tripsFuture, standaloneFuture]);

      final trips = results[0] as TravelTripListResponse;
      final standalone = results[1] as TravelStandaloneEventListResponse;

      final entries = <TimelineEntry>[
        for (final t in trips.data)
          TimelineEntry(
            id: t.id,
            name: t.name,
            description: t.description,
            start: t.start,
            end: t.end,
            isTrip: true,
          ),
        for (final e in standalone.data)
          TimelineEntry(
            id: e.id,
            name: e.name,
            description: e.description,
            start: e.start,
            end: e.end,
            isTrip: false,
          ),
      ];

      final now = DateTime.now();
      final current = <TimelineEntry>[];
      final future = <TimelineEntry>[];
      final past = <TimelineEntry>[];

      for (final entry in entries) {
        if (entry.start.isBefore(now) && entry.end.isAfter(now)) {
          current.add(entry);
        } else if (entry.start.isAfter(now)) {
          future.add(entry);
        } else {
          past.add(entry);
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
    } catch (e, st) {
      developer.log('Failed to load travel', error: e, stackTrace: st);
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    return DesignSurface(child: _buildBody());
  }

  Widget _buildBody() {
    final tokens = DesignTheme.of(context);

    if (_loading) {
      return Center(child: CircularProgressIndicator(color: tokens.primary));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DesignText(
              'Fehler beim Laden der Reisen',
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

    final hasEntries =
        _current.isNotEmpty || _future.isNotEmpty || _past.isNotEmpty;

    if (!hasEntries) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_rounded, size: 64, color: tokens.textLow),
            SizedBox(height: tokens.spaceLg),
            DesignText(
              'Keine Reisen oder Events gefunden',
              style: DesignTextStyle.body,
              color: tokens.textLow,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_current.isNotEmpty)
            ..._buildSection('Aktuelle Reisen', _current),
          if (_future.isNotEmpty)
            ..._buildSection('Kommende Reisen', _future),
          if (_past.isNotEmpty) ..._buildSection('Vergangene Reisen', _past),
          SizedBox(height: tokens.spaceXl),
        ],
      ),
    );
  }

  List<Widget> _buildSection(String title, List<TimelineEntry> entries) {
    final tokens = DesignTheme.of(context);
    return [
      Padding(
        padding: EdgeInsets.fromLTRB(
          tokens.spaceLg,
          tokens.spaceXl,
          tokens.spaceLg,
          tokens.spaceXs,
        ),
        child: DesignText(
          title,
          style: DesignTextStyle.subtitle,
          color: tokens.textHigh,
        ),
      ),
      ...entries.map((entry) {
        return DesignCard(
          margin: EdgeInsets.fromLTRB(
            tokens.spaceLg,
            0,
            tokens.spaceLg,
            tokens.spaceXs,
          ),
          padding: EdgeInsets.all(tokens.spaceMd),
          onTap: entry.isTrip
              ? () => context.go('/reisen/${entry.id}')
              : null,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tokens.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  entry.isTrip ? Icons.flight_rounded : Icons.event_rounded,
                  color: tokens.primary,
                  size: 20,
                ),
              ),
              SizedBox(width: tokens.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DesignText(
                      entry.name,
                      style: DesignTextStyle.body,
                      color: tokens.textHigh,
                    ),
                    SizedBox(height: tokens.spaceXs),
                    DesignText(
                      '${_formatDate(entry.start)} \u2013 ${_formatDate(entry.end)}',
                      style: DesignTextStyle.label,
                      color: tokens.textLow,
                    ),
                  ],
                ),
              ),
              if (entry.isTrip)
                Padding(
                  padding: EdgeInsets.only(left: tokens.spaceMd),
                  child: Icon(Icons.chevron_right_rounded, color: tokens.textLow),
                ),
            ],
          ),
        );
      }),
    ];
  }
}
