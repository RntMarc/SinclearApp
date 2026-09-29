import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/network/api_client.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/composite/design_list_tile.dart';
import '../../../design/widgets/composite/design_plan_phase_progress.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_chip.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../../design/widgets/primitives/design_text_field.dart';
import '../models/travel_planning_models.dart';
import '../services/travel_planning_service.dart';
import '../travel_planning_error_messages.dart';
import '../widgets/planning_sheets.dart';
import '../widgets/planning_widgets.dart';

/// Planungsansicht einer Reise (`/reisen/planung/:id`).
///
/// Lädt die vollständigen Planungsdetails (`GET /trips/planning/{id}`) und
/// zeigt die drei festen Phasen, Mitglieder und Vorschläge. Leitungsaktionen
/// sind nur sichtbar, wenn der Server `canManage` meldet. Nach jeder Mutation
/// werden die Details neu geladen.
class PlanningDetailScreen extends StatefulWidget {
  final String id;

  const PlanningDetailScreen({super.key, required this.id});

  @override
  State<PlanningDetailScreen> createState() => _PlanningDetailScreenState();
}

class _PlanningDetailScreenState extends State<PlanningDetailScreen> {
  static final _log = Logger('planning_detail');

  TravelPlanningService get _service => AppScope.of(context).planning;
  String? get _currentUserId => AppScope.of(context).auth.userId;

  bool _loading = true;
  bool _busy = false;
  String? _error;
  PlanningTripDetail? _detail;
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
      final detail = await _service.getDetail(widget.id);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
      unawaited(_markRead());
    } catch (e, st) {
      _log.severe('Failed to load planning detail', e, st);
      if (!mounted) return;
      setState(() {
        _error = 'Die Planung konnte nicht geladen werden.';
        _loading = false;
      });
    }
  }

  /// Lädt still neu (ohne Vollbild-Spinner) nach einer Mutation.
  Future<void> _reload() async {
    try {
      final detail = await _service.getDetail(widget.id);
      if (mounted) setState(() => _detail = detail);
    } catch (e, st) {
      _log.warning('Planning reload failed', e, st);
    }
  }

  Future<void> _markRead() async {
    try {
      final scope = AppScope.of(context);
      final ids = scope.notification.unreadIdsForTrip(widget.id);
      if (ids.isEmpty) return;
      await scope.notification.markRead(
        ids,
        token: await scope.auth.getAccessToken(),
      );
    } catch (e, st) {
      _log.warning('markRead failed', e, st);
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      await _reload();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(planningErrorMessage(e))));
    } catch (e, st) {
      _log.warning('Planning action failed', e, st);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Aktion fehlgeschlagen.')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ──────────────────────────── Aktionen ────────────────────────────

  Future<void> _respond(String response) =>
      _run(() => _service.respond(widget.id, response));

  Future<void> _invite() async {
    final detail = _detail;
    if (detail == null) return;
    final existing = detail.members.map((m) => m.userId).toSet();
    final userId = await showPlanningInviteSheet(
      context: context,
      existingUserIds: existing,
    );
    if (userId == null || !mounted) return;
    await _run(() => _service.inviteMember(widget.id, userId));
  }

  void _manageMember(PlanMember member) {
    final tokens = DesignTheme.of(context);
    showDesignSheet(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DesignText(
            member.displayName ?? 'Mitglied',
            style: DesignTextStyle.subtitle,
            color: tokens.textHigh,
          ),
          SizedBox(height: tokens.spaceMd),
          if (member.status != 'accepted' && !member.isInactive)
            DesignListTile(
              leading: Icon(
                Icons.check_rounded,
                color: tokens.primary,
                size: 20,
              ),
              title: 'Als aktiv markieren',
              onTap: () {
                Navigator.pop(context);
                _run(
                  () => _service.setMemberStatus(
                    widget.id,
                    member.userId,
                    'accepted',
                  ),
                );
              },
            ),
          if (!member.isInactive)
            DesignListTile(
              leading: Icon(
                Icons.pause_circle_outline_rounded,
                color: tokens.warning,
                size: 20,
              ),
              title: 'Deaktivieren',
              onTap: () {
                Navigator.pop(context);
                _run(
                  () => _service.setMemberStatus(
                    widget.id,
                    member.userId,
                    'inactive',
                  ),
                );
              },
            ),
          DesignListTile(
            leading: Icon(
              Icons.person_remove_rounded,
              color: tokens.danger,
              size: 20,
            ),
            title: 'Entfernen',
            onTap: () {
              Navigator.pop(context);
              _run(() => _service.removeMember(widget.id, member.userId));
            },
          ),
        ],
      ),
    );
  }

  Future<void> _withdraw() async {
    final uid = _currentUserId;
    if (uid == null) return;
    final confirmed = await _confirm(
      'Teilnahme zurückziehen?',
      'Du verlierst den Zugriff auf Planung und Chat. Deine Beiträge bleiben erhalten.',
      'Zurückziehen',
    );
    if (confirmed != true || !mounted) return;
    await _run(() async {
      await _service.removeMember(widget.id, uid);
      if (mounted) context.go('/reisen');
    });
  }

  Future<void> _createDate() async {
    final draft = await showPlanningDateOptionSheet(
      context: context,
      initialTimezone: _detail?.timezone,
    );
    if (draft == null || !mounted) return;
    await _run(
      () => _service.createDateOption(
        widget.id,
        label: draft.label,
        allDay: draft.allDay,
        timezone: draft.timezone,
        startDate: draft.startDate,
        endDate: draft.endDate,
        startAt: draft.startAt,
        endAt: draft.endAt,
      ),
    );
  }

  Future<void> _editDate(PlanDateOption option) async {
    final draft = await showPlanningDateOptionSheet(
      context: context,
      initial: option,
    );
    if (draft == null || !mounted) return;
    await _run(
      () => _service.updateDateOption(
        widget.id,
        option.id,
        label: draft.label,
        allDay: draft.allDay,
        timezone: draft.timezone,
        startDate: draft.startDate,
        endDate: draft.endDate,
        startAt: draft.startAt,
        endAt: draft.endAt,
      ),
    );
  }

  Future<void> _deleteDate(PlanDateOption option) async {
    final confirmed = await _confirm(
      'Vorschlag löschen?',
      planningDateLabel(option),
      'Löschen',
    );
    if (confirmed != true || !mounted) return;
    await _run(() => _service.deleteDateOption(widget.id, option.id));
  }

  Future<void> _respondDate(String optionId, String availability) =>
      _run(() => _service.setDateResponse(widget.id, optionId, availability));

  Future<void> _finalizeDate(PlanDateOption option) =>
      _run(() => _service.finalizeDate(widget.id, option.id));

  Future<void> _editTransport(String direction) async {
    final uid = _currentUserId;
    PlanTransport? existing;
    for (final t in _detail?.transport ?? const <PlanTransport>[]) {
      if (t.userId == uid && t.direction == direction) {
        existing = t;
        break;
      }
    }
    final draft = await showPlanningTransportSheet(
      context: context,
      initialDirection: direction,
      initial: existing,
    );
    if (draft == null || !mounted) return;
    await _run(
      () => _service.setTransport(
        widget.id,
        direction: draft.direction,
        mode: draft.mode,
        offersRide: draft.offersRide,
        availableSeats: draft.availableSeats,
        notes: draft.notes,
      ),
    );
  }

  Future<void> _createAccommodation() async {
    final draft = await showPlanningAccommodationSheet(context: context);
    if (draft == null || !mounted) return;
    await _run(
      () => _service.createAccommodationOption(
        widget.id,
        name: draft.name,
        description: draft.description,
        address: draft.address,
        pricePerPersonPerNight: draft.pricePerPersonPerNight,
        currency: draft.currency,
      ),
    );
  }

  Future<void> _editAccommodation(PlanAccommodationOption option) async {
    final draft = await showPlanningAccommodationSheet(
      context: context,
      initial: option,
    );
    if (draft == null || !mounted) return;
    await _run(
      () => _service.updateAccommodationOption(
        widget.id,
        option.id,
        name: draft.name,
        description: draft.description,
        address: draft.address,
        pricePerPersonPerNight: draft.pricePerPersonPerNight,
        currency: draft.currency,
      ),
    );
  }

  Future<void> _deleteAccommodation(PlanAccommodationOption option) async {
    final confirmed = await _confirm(
      'Option löschen?',
      option.name ?? 'Unterkunft',
      'Löschen',
    );
    if (confirmed != true || !mounted) return;
    await _run(() => _service.deleteAccommodationOption(widget.id, option.id));
  }

  Future<void> _selectAccommodation(PlanAccommodationOption option) =>
      _run(() => _service.selectAccommodation(widget.id, option.id));

  Future<void> _createEvent() async {
    final draft = await showPlanningEventSheet(
      context: context,
      initialTimezone: _detail?.timezone,
    );
    if (draft == null || !mounted) return;
    await _run(
      () => _service.createEventSuggestion(
        widget.id,
        name: draft.name,
        description: draft.description,
        dayIndex: draft.dayIndex,
        allDay: draft.allDay,
        timezone: draft.timezone,
        startDate: draft.startDate,
        endDate: draft.endDate,
        startAt: draft.startAt,
        endAt: draft.endAt,
        address: draft.address,
      ),
    );
  }

  Future<void> _editEvent(PlanEventSuggestion suggestion) async {
    final draft = await showPlanningEventSheet(
      context: context,
      initial: suggestion,
    );
    if (draft == null || !mounted) return;
    await _run(
      () => _service.updateEventSuggestion(
        widget.id,
        suggestion.id,
        name: draft.name,
        description: draft.description,
        dayIndex: draft.dayIndex,
        allDay: draft.allDay,
        timezone: draft.timezone,
        startDate: draft.startDate,
        endDate: draft.endDate,
        startAt: draft.startAt,
        endAt: draft.endAt,
        address: draft.address,
      ),
    );
  }

  Future<void> _deleteEvent(PlanEventSuggestion suggestion) async {
    final confirmed = await _confirm(
      'Vorschlag löschen?',
      suggestion.name,
      'Löschen',
    );
    if (confirmed != true || !mounted) return;
    await _run(() => _service.deleteEventSuggestion(widget.id, suggestion.id));
  }

  Future<void> _confirmEvent(PlanEventSuggestion suggestion, bool confirmed) =>
      _run(
        () => _service.confirmEvent(
          widget.id,
          suggestion.id,
          confirmed: confirmed,
        ),
      );

  Future<void> _setEventInterest(
    PlanEventSuggestion suggestion,
    String interest,
  ) =>
      _run(() => _service.setEventInterest(widget.id, suggestion.id, interest));

  Future<void> _setTopicStatus(String topic, String status) =>
      _run(() => _service.setTopicStatus(widget.id, topic, status));

  Future<void> _activate() async {
    final confirmed = await _confirm(
      'Reise aktivieren?',
      'Die Planung wird abgeschlossen und die Reise wird für alle '
          'zugesagten Teilnehmenden aktiv. Das kann nicht rückgängig gemacht '
          'werden.',
      'Aktivieren',
    );
    if (confirmed != true || !mounted) return;
    await _run(() async {
      await _service.activate(widget.id);
      if (mounted) context.go('/reisen/${widget.id}');
    });
  }

  Future<void> _editTrip() async {
    final detail = _detail;
    if (detail == null) return;
    final result = await showDesignSheet<({String name, String? description})>(
      context: context,
      child: _EditTripSheet(detail: detail),
    );
    if (result == null || !mounted) return;
    await _run(
      () => _service.update(
        widget.id,
        name: result.name,
        description: result.description,
      ),
    );
  }

  Future<bool?> _confirm(String title, String body, String action) {
    final tokens = DesignTheme.of(context);
    return showDesignSheet<bool>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DesignText(
            title,
            style: DesignTextStyle.subtitle,
            color: tokens.textHigh,
          ),
          SizedBox(height: tokens.spaceSm),
          DesignText(body, style: DesignTextStyle.body, color: tokens.textLow),
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
                  label: action,
                  onPressed: () => Navigator.pop(context, true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openMenu() {
    final detail = _detail;
    if (detail == null) return;
    final tokens = DesignTheme.of(context);
    showDesignSheet(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DesignText(
            detail.name,
            style: DesignTextStyle.subtitle,
            color: tokens.textHigh,
          ),
          SizedBox(height: tokens.spaceMd),
          if (detail.canManage)
            DesignListTile(
              leading: Icon(
                Icons.edit_rounded,
                color: tokens.primary,
                size: 20,
              ),
              title: 'Planung bearbeiten',
              onTap: () {
                Navigator.pop(context);
                _editTrip();
              },
            ),
          if (!detail.canManage)
            DesignListTile(
              leading: Icon(
                Icons.logout_rounded,
                color: tokens.danger,
                size: 20,
              ),
              title: 'Teilnahme zurückziehen',
              onTap: () {
                Navigator.pop(context);
                _withdraw();
              },
            ),
        ],
      ),
    );
  }

  // ──────────────────────────── Aufbau ────────────────────────────

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
            title: _detail?.name ?? 'Planung',
            actions: [
              if (_detail != null)
                DesignIconButton(
                  icon: Icons.more_vert_rounded,
                  onPressed: _openMenu,
                ),
            ],
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
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DesignText(
              _error!,
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
    final detail = _detail;
    if (detail == null) {
      return Center(
        child: DesignText(
          'Planung nicht gefunden',
          style: DesignTextStyle.body,
          color: tokens.textLow,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (detail.memberStatus == 'invited')
            PlanningInviteBanner(
              busy: _busy,
              onAccept: () => _respond('accepted'),
              onDecline: () => _respond('declined'),
            ),
          DesignCard(
            child: DesignPlanPhaseProgress(phases: planningPhases(detail)),
          ),
          if (detail.conversationId != null)
            DesignCard(
              child: DesignButton(
                label: 'Reisechat öffnen',
                icon: Icons.forum_rounded,
                variant: DesignButtonVariant.outlined,
                fullWidth: true,
                onPressed: () => context.push('/chat/${detail.conversationId}'),
              ),
            ),
          PlanningMembersSection(
            members: detail.members,
            canManage: detail.canManage,
            onInvite: _invite,
            onManageMember: _manageMember,
          ),
          PlanningDateOptionsSection(
            options: detail.dateOptions,
            canManage: detail.canManage,
            currentUserId: _currentUserId,
            onRespond: _respondDate,
            onCreate: _createDate,
            onEdit: _editDate,
            onDelete: _deleteDate,
            onFinalize: _finalizeDate,
          ),
          PlanningTransportSection(
            transports: detail.transport,
            onEdit: _editTransport,
          ),
          PlanningAccommodationSection(
            options: detail.accommodationOptions,
            canManage: detail.canManage,
            currentUserId: _currentUserId,
            onCreate: _createAccommodation,
            onEdit: _editAccommodation,
            onDelete: _deleteAccommodation,
            onSelect: _selectAccommodation,
          ),
          PlanningEventsSection(
            suggestions: detail.eventSuggestions,
            canManage: detail.canManage,
            currentUserId: _currentUserId,
            onCreate: _createEvent,
            onEdit: _editEvent,
            onDelete: _deleteEvent,
            onConfirm: _confirmEvent,
            onInterest: _setEventInterest,
          ),
          if (detail.canManage)
            _LeadActionsCard(
              detail: detail,
              busy: _busy,
              onSetTopicStatus: _setTopicStatus,
              onActivate: _activate,
            ),
          SizedBox(height: tokens.spaceXxl),
        ],
      ),
    );
  }
}

/// Leitungsaktionen: Phasen abschließen/überspringen und Reise aktivieren.
class _LeadActionsCard extends StatelessWidget {
  const _LeadActionsCard({
    required this.detail,
    required this.busy,
    required this.onSetTopicStatus,
    required this.onActivate,
  });

  final PlanningTripDetail detail;
  final bool busy;
  final void Function(String topic, String status) onSetTopicStatus;
  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return DesignCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DesignText(
            'Leitung',
            style: DesignTextStyle.subtitle,
            color: tokens.textHigh,
          ),
          SizedBox(height: tokens.spaceSm),
          DesignText(
            'Phasen steuern',
            style: DesignTextStyle.label,
            color: tokens.textLow,
          ),
          SizedBox(height: tokens.spaceSm),
          for (final topic in PlanningPhase.order) ...[
            _PhaseControls(
              label: PlanningPhase.label(topic),
              status: detail.topicStatusFor(topic),
              onSet: (status) => onSetTopicStatus(topic, status),
            ),
            SizedBox(height: tokens.spaceSm),
          ],
          SizedBox(height: tokens.spaceSm),
          DesignButton(
            label: 'Reise aktivieren',
            fullWidth: true,
            loading: busy,
            onPressed: onActivate,
          ),
        ],
      ),
    );
  }
}

class _PhaseControls extends StatelessWidget {
  const _PhaseControls({
    required this.label,
    required this.status,
    required this.onSet,
  });

  final String label;
  final String status;
  final void Function(String status) onSet;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DesignText(label, style: DesignTextStyle.body, color: tokens.textHigh),
        SizedBox(height: tokens.spaceXs),
        Wrap(
          spacing: tokens.spaceSm,
          children: [
            DesignChip(
              label: 'Beginnen',
              selected: status == 'in_progress',
              onTap: () => onSet('in_progress'),
            ),
            DesignChip(
              label: 'Abschließen',
              selected: status == 'completed',
              onTap: () => onSet('completed'),
            ),
            DesignChip(
              label: 'Überspringen',
              selected: status == 'skipped',
              onTap: () => onSet('skipped'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Sheet zum Bearbeiten von Name und Beschreibung der Planung.
class _EditTripSheet extends StatefulWidget {
  const _EditTripSheet({required this.detail});

  final PlanningTripDetail detail;

  @override
  State<_EditTripSheet> createState() => _EditTripSheetState();
}

class _EditTripSheetState extends State<_EditTripSheet> {
  late final TextEditingController _name;
  late final TextEditingController _description;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.detail.name);
    _description = TextEditingController(text: widget.detail.description ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesignText(
          'Planung bearbeiten',
          style: DesignTextStyle.subtitle,
          color: tokens.textHigh,
        ),
        SizedBox(height: tokens.spaceMd),
        DesignTextField(hint: 'Name', controller: _name),
        SizedBox(height: tokens.spaceMd),
        DesignTextField(
          hint: 'Beschreibung (optional)',
          controller: _description,
          maxLines: 3,
        ),
        SizedBox(height: tokens.spaceXl),
        DesignButton(
          label: 'Speichern',
          fullWidth: true,
          onPressed: _name.text.trim().isEmpty
              ? null
              : () => Navigator.pop(context, (
                  name: _name.text.trim(),
                  description: _description.text.trim().isEmpty
                      ? null
                      : _description.text.trim(),
                )),
        ),
      ],
    );
  }
}
