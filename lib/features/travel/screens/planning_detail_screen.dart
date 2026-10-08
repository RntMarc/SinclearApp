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
import '../../../design/widgets/primitives/design_chip.dart';
import '../../../design/widgets/primitives/design_divider.dart';
import '../../../design/widgets/primitives/design_fab.dart';
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

  Future<bool> _run(Future<void> Function() action) async {
    if (_busy) return false;
    setState(() => _busy = true);
    try {
      await action();
      await _reload();
      return true;
    } on ApiException catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(planningErrorMessage(e))));
      return false;
    } catch (e, st) {
      _log.warning('Planning action failed', e, st);
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Aktion fehlgeschlagen.')));
      return false;
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
        accommodationId: draft.accommodationId,
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
        allDay: draft.allDay,
        timezone: draft.timezone,
        startDate: draft.startDate,
        endDate: draft.endDate,
        startAt: draft.startAt,
        endAt: draft.endAt,
        address: draft.address,
        latitude: draft.latitude,
        longitude: draft.longitude,
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
        allDay: draft.allDay,
        timezone: draft.timezone,
        startDate: draft.startDate,
        endDate: draft.endDate,
        startAt: draft.startAt,
        endAt: draft.endAt,
        address: draft.address,
        latitude: draft.latitude,
        longitude: draft.longitude,
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

  Future<void> _editTrip() async {
    final detail = _detail;
    if (detail == null) return;
    final draft = await showDesignSheet<_PlanningEditDraft>(
      context: context,
      child: _PlanningEditSheet(detail: detail, onActivate: _activateWithDraft),
    );
    if (draft == null || !mounted) return;
    await _saveDraft(draft);
  }

  /// Persistiert Name/Beschreibung und alle geänderten Phasen.
  Future<void> _persist(_PlanningEditDraft draft) async {
    await _service.update(
      widget.id,
      name: draft.name,
      description: draft.description,
    );
    for (final entry in draft.changedStatuses.entries) {
      await _service.setTopicStatus(widget.id, entry.key, entry.value);
    }
  }

  /// Speichert die Änderungen aus dem Sheet und bestätigt mit Feedback.
  Future<void> _saveDraft(_PlanningEditDraft draft) async {
    final saved = await _run(() => _persist(draft));
    if (saved && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Planung gespeichert')));
    }
  }

  /// Speichert die Änderungen aus dem Sheet und aktiviert die Reise.
  Future<void> _activateWithDraft(_PlanningEditDraft draft) async {
    final confirmed = await _confirm(
      'Reise aktivieren?',
      'Die Planung wird abgeschlossen und die Reise wird für alle '
          'zugesagten Teilnehmenden aktiv. Das kann nicht rückgängig gemacht '
          'werden.',
      'Aktivieren',
    );
    if (confirmed != true || !mounted) return;
    await _run(() async {
      await _persist(draft);
      await _service.activate(widget.id);
      if (mounted) context.go('/reisen/${widget.id}');
    });
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
    final tokens = DesignTheme.of(context);
    final conversationId = _detail?.conversationId;
    return DesignSurface(
      child: Stack(
        children: [
          Column(
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
          if (conversationId != null)
            Positioned(
              right: tokens.spaceLg,
              bottom: tokens.spaceLg,
              child: DesignFab(
                icon: Icons.forum_rounded,
                tooltip: 'Reisechat öffnen',
                onPressed: () => context.push('/chat/$conversationId'),
              ),
            ),
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
            Padding(
              padding: EdgeInsets.only(bottom: tokens.spaceMd),
              child: PlanningInviteBanner(
                busy: _busy,
                onAccept: () => _respond('accepted'),
                onDecline: () => _respond('declined'),
              ),
            ),
          Padding(
            padding: EdgeInsets.only(bottom: tokens.spaceMd),
            child: DesignPlanPhaseProgress(phases: planningPhases(detail)),
          ),
          PlanningPhaseSection(
            label: PlanningPhase.label(PlanningPhase.participants),
            status: detail.topicStatusFor(PlanningPhase.participants),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: tokens.spaceMd),
                  child: PlanningMembersSection(
                    members: detail.members,
                    canManage: detail.canManage,
                    onInvite: _invite,
                    onManageMember: _manageMember,
                  ),
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
              ],
            ),
          ),
          PlanningPhaseSection(
            label: PlanningPhase.label(PlanningPhase.travel),
            status: detail.topicStatusFor(PlanningPhase.travel),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: tokens.spaceMd),
                  child: PlanningTransportSection(
                    transports: detail.transport,
                    onEdit: _editTransport,
                  ),
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
              ],
            ),
          ),
          PlanningPhaseSection(
            label: PlanningPhase.label(PlanningPhase.program),
            status: detail.topicStatusFor(PlanningPhase.program),
            child: PlanningEventsSection(
              suggestions: detail.eventSuggestions,
              canManage: detail.canManage,
              currentUserId: _currentUserId,
              onCreate: _createEvent,
              onEdit: _editEvent,
              onDelete: _deleteEvent,
              onConfirm: _confirmEvent,
              onInterest: _setEventInterest,
            ),
          ),
          SizedBox(height: tokens.spaceXxl + 80),
        ],
      ),
    );
  }
}

/// Die vier einstellbaren Phasen-Zustände der Planung.
const _phaseStatusOptions = [
  (value: 'pending', label: 'Ausstehend'),
  (value: 'in_progress', label: 'Begonnen'),
  (value: 'completed', label: 'Abgeschlossen'),
  (value: 'skipped', label: 'Übersprungen'),
];

/// Gesammelte Änderungen aus dem „Planung bearbeiten"-Sheet.
class _PlanningEditDraft {
  const _PlanningEditDraft({
    required this.name,
    required this.description,
    required this.changedStatuses,
  });

  final String name;
  final String? description;

  /// Nur die Phasen, deren Status vom geladenen Serverstand abweicht.
  final Map<String, String> changedStatuses;
}

/// Gemeinsames Bearbeiten-Sheet: Details, Phasenstatus und Aktivierung.
///
/// Ersetzt das frühere getrennte „Planung bearbeiten"/„Leitung steuern".
/// Änderungen werden gesammelt und erst mit „Speichern" persistiert; „Reise
/// aktivieren" ist erst freigeschaltet, wenn alle Phasen abgeschlossen oder
/// übersprungen sind.
class _PlanningEditSheet extends StatefulWidget {
  const _PlanningEditSheet({required this.detail, required this.onActivate});

  final PlanningTripDetail detail;

  /// Wird nach dem Schließen aufgerufen, um die Reise zu aktivieren.
  final Future<void> Function(_PlanningEditDraft draft) onActivate;

  @override
  State<_PlanningEditSheet> createState() => _PlanningEditSheetState();
}

class _PlanningEditSheetState extends State<_PlanningEditSheet> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final Map<String, String> _statuses = {
    for (final topic in PlanningPhase.order)
      topic: widget.detail.topicStatusFor(topic),
  };

  /// Phasen und Aktivierung sind nur in der Planungsphase verfügbar.
  bool get _showPlanning => widget.detail.state == 'planning';

  bool get _canActivate => PlanningPhase.allResolved(_statuses);

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

  _PlanningEditDraft _draft() {
    final changed = <String, String>{};
    for (final topic in PlanningPhase.order) {
      if (_statuses[topic] != widget.detail.topicStatusFor(topic)) {
        changed[topic] = _statuses[topic]!;
      }
    }
    return _PlanningEditDraft(
      name: _name.text.trim(),
      description: _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
      changedStatuses: changed,
    );
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
        SizedBox(height: tokens.spaceXs),
        DesignText(
          'Details und Phasen der Reise',
          style: DesignTextStyle.body,
          color: tokens.textLow,
        ),
        SizedBox(height: tokens.spaceLg),
        DesignTextField(
          hint: 'Name',
          controller: _name,
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(height: tokens.spaceMd),
        DesignTextField(
          hint: 'Beschreibung (optional)',
          controller: _description,
          maxLines: 3,
        ),
        if (_showPlanning) ...[
          SizedBox(height: tokens.spaceXl),
          DesignText(
            'Phasen',
            style: DesignTextStyle.subtitle,
            color: tokens.textHigh,
          ),
          SizedBox(height: tokens.spaceXs),
          DesignText(
            'Abgeschlossene oder übersprungene Phasen geben die Reise zur '
            'Aktivierung frei.',
            style: DesignTextStyle.label,
            color: tokens.textLow,
          ),
          SizedBox(height: tokens.spaceMd),
          for (final topic in PlanningPhase.order) ...[
            DesignText(
              PlanningPhase.label(topic),
              style: DesignTextStyle.body,
              color: tokens.textHigh,
            ),
            SizedBox(height: tokens.spaceSm),
            Wrap(
              spacing: tokens.spaceSm,
              runSpacing: tokens.spaceSm,
              children: [
                for (final option in _phaseStatusOptions)
                  DesignChip(
                    label: option.label,
                    selected: _statuses[topic] == option.value,
                    onTap: () =>
                        setState(() => _statuses[topic] = option.value),
                  ),
              ],
            ),
            SizedBox(height: tokens.spaceMd),
          ],
        ],
        SizedBox(height: tokens.spaceXl),
        DesignButton(
          label: 'Speichern',
          fullWidth: true,
          onPressed: _name.text.trim().isEmpty
              ? null
              : () => Navigator.pop(context, _draft()),
        ),
        if (_showPlanning) ...[
          SizedBox(height: tokens.spaceXl),
          const DesignDivider(),
          SizedBox(height: tokens.spaceLg),
          DesignButton(
            label: 'Reise aktivieren',
            fullWidth: true,
            onPressed: _canActivate
                ? () {
                    final draft = _draft();
                    Navigator.pop(context);
                    widget.onActivate(draft);
                  }
                : null,
          ),
          if (!_canActivate) ...[
            SizedBox(height: tokens.spaceSm),
            DesignText(
              'Erst alle Phasen abschließen oder überspringen.',
              style: DesignTextStyle.label,
              color: tokens.textLow,
            ),
          ],
        ],
      ],
    );
  }
}
