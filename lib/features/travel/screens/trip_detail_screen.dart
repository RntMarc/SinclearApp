import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/app_scope.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../models/travel_models.dart';
import '../services/travel_service.dart';
import '../widgets/trip_detail_widgets.dart';

class TripDetailScreen extends StatefulWidget {
  final String id;

  const TripDetailScreen({super.key, required this.id});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen>
    with SingleTickerProviderStateMixin {
  TravelService get _service => AppScope.of(context).travel;

  bool _loading = true;
  String? _error;

  TravelTrip? _trip;
  List<TravelEvent> _events = [];
  List<TravelAccommodation> _accommodations = [];
  List<TravelParticipant> _participants = [];
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
      final results = await Future.wait([
        _service.getTrip(widget.id),
        _service.getEvents(widget.id),
        _service.getAccommodations(widget.id),
        _service.getParticipants(widget.id),
      ]);

      if (!mounted) return;

      setState(() {
        _trip = results[0] as TravelTrip;
        _events = (results[1] as TravelEventListResponse).data;
        _accommodations = (results[2] as TravelAccommodationListResponse).data;
        _participants = (results[3] as TravelParticipantListResponse).data;
        _loading = false;
      });
    } catch (e, st) {
      developer.log('Failed to load trip detail', error: e, stackTrace: st);
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
            title: _trip?.name ?? 'Reise',
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DesignText(
                  'Fehler beim Laden der Reisedetails',
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
      );
    }

    final trip = _trip;
    if (trip == null) {
      return Center(
        child: DesignText(
          'Reise nicht gefunden',
          style: DesignTextStyle.body,
          color: tokens.textLow,
        ),
      );
    }

    final auth = AppScope.of(context).auth;
    final currentUserId = auth.userId;

    return RefreshIndicator(
      onRefresh: _load,
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            TabBar(
              indicatorColor: tokens.primary,
              labelColor: tokens.textHigh,
              unselectedLabelColor: tokens.textLow,
              labelStyle: tokens.bodyStyle(tokens.textHigh),
              unselectedLabelStyle: tokens.labelStyle(tokens.textLow),
              tabs: const [
                Tab(text: 'Übersicht'),
                Tab(text: 'Events'),
                Tab(text: 'Karte'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  TripOverviewTab(
                    trip: trip,
                    accommodations: _accommodations,
                    participants: _participants,
                    currentUserId: currentUserId,
                  ),
                  TripEventsTab(events: _events, currentUserId: currentUserId),
                  TripMapTab(
                    accommodations: _accommodations,
                    events: _events,
                    currentUserId: currentUserId,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
