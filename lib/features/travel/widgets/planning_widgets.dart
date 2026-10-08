import 'package:flutter/material.dart';

import '../../../core/utils/date_utils.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_availability_matrix.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/composite/design_list_tile.dart';
import '../../../design/widgets/composite/design_plan_phase_progress.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_avatar.dart';
import '../../../design/widgets/primitives/design_badge.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_chip.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../../design/widgets/primitives/press_scale.dart';
import '../models/travel_planning_models.dart';

// ──────────────────────────── Adapter / Formatierung ────────────────────────────

/// Fortschrittsphasen für den Katalog-Widget.
///
/// Ist [onPhaseTap] gesetzt, wird jede Phase antippbar (z. B. für den
/// Statuswechsel durch die Leitung).
List<DesignPlanPhase> planningPhases(
  PlanningTrip trip, {
  void Function(String topic)? onPhaseTap,
}) {
  return [
    for (final topic in PlanningPhase.order)
      DesignPlanPhase(
        label: PlanningPhase.label(topic),
        status: _phaseStatus(trip.topicStatusFor(topic)),
        onTap: onPhaseTap == null ? null : () => onPhaseTap(topic),
      ),
  ];
}

DesignPlanPhaseStatus _phaseStatus(String status) => switch (status) {
  'in_progress' => DesignPlanPhaseStatus.inProgress,
  'completed' => DesignPlanPhaseStatus.completed,
  'skipped' => DesignPlanPhaseStatus.skipped,
  _ => DesignPlanPhaseStatus.pending,
};

/// Formatierter Zeitraum einer Terminoption (ohne Bezeichnung).
String planningDateRange(PlanDateOption option) {
  if (option.allDay && option.startDate != null) {
    return formatDayRange(
      option.startDate!,
      option.endDate ?? option.startDate!,
    );
  }
  if (!option.allDay && option.startAt != null) {
    return formatInstantRangeInZone(
      option.startAt!,
      option.endAt ?? option.startAt!,
      option.timezone,
    );
  }
  return 'Ohne Datum';
}

/// Anzeigelabel einer Terminoption: bevorzugt die Bezeichnung, sonst der
/// formatierte Zeitraum.
String planningDateLabel(PlanDateOption option) {
  final label = option.label;
  if (label != null && label.trim().isNotEmpty) return label.trim();
  return planningDateRange(option);
}

/// Zeit-/Ortszeile eines Eventvorschlags.
String planningEventWhen(PlanEventSuggestion suggestion) {
  if (suggestion.allDay && suggestion.startDate != null) {
    return formatDayRange(
      suggestion.startDate!,
      suggestion.endDate ?? suggestion.startDate!,
    );
  }
  if (!suggestion.allDay && suggestion.startAt != null) {
    return formatInstantRangeInZone(
      suggestion.startAt!,
      suggestion.endAt ?? suggestion.startAt!,
      suggestion.timezone,
    );
  }
  return 'Ohne Uhrzeit';
}

String memberStatusLabel(String status) => switch (status) {
  'accepted' => 'Zugesagt',
  'declined' => 'Abgelehnt',
  'inactive' => 'Inaktiv',
  _ => 'Eingeladen',
};

DesignAvailability? _availabilityFromApi(String value) => switch (value) {
  'yes' => DesignAvailability.yes,
  'maybe' => DesignAvailability.maybe,
  'no' => DesignAvailability.no,
  _ => null,
};

/// API-Wert einer Verfügbarkeit/Interesse (`yes`/`maybe`/`no`).
String planningAvailabilityValue(DesignAvailability value) => switch (value) {
  DesignAvailability.yes => 'yes',
  DesignAvailability.maybe => 'maybe',
  DesignAvailability.no => 'no',
};

DesignAvailability? planningAvailabilityFromApi(String? value) =>
    value == null ? null : _availabilityFromApi(value);

// ──────────────────────────── Abschnitts-Karte ────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, this.action, required this.child});

  final String title;
  final Widget? action;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return DesignCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DesignText(
                  title,
                  style: DesignTextStyle.subtitle,
                  color: tokens.textHigh,
                ),
              ),
              ?action,
            ],
          ),
          SizedBox(height: tokens.spaceMd),
          child,
        ],
      ),
    );
  }
}

// ──────────────────────────── Phasen-Abschnitt ────────────────────────────

/// Ausklappbarer Abschnitt einer Planungsphase.
///
/// Zeigt Phasenbezeichnung und Status als Kopfzeile. Nur die begonnenen und
/// abgeschlossenen Phasen lassen sich ausklappen; ausstehende und
/// übersprungene bleiben als inaktive Kopfzeile sichtbar (ausgeblendet, aber
/// nicht versteckt).
class PlanningPhaseSection extends StatefulWidget {
  const PlanningPhaseSection({
    required this.label,
    required this.status,
    required this.child,
    this.onHelp,
    super.key,
  });

  /// Deutsche Phasenbezeichnung, z. B. „Wann und wer?".
  final String label;

  /// API-Status der Phase (`pending`/`in_progress`/`completed`/`skipped`).
  final String status;

  /// Inhalt des Abschnitts (die zur Phase gehörenden Karten).
  final Widget child;

  /// Öffnet bei gesetzt die Info/Hilfe-Erklärung der Phase.
  final VoidCallback? onHelp;

  @override
  State<PlanningPhaseSection> createState() => _PlanningPhaseSectionState();
}

class _PlanningPhaseSectionState extends State<PlanningPhaseSection> {
  late bool _expanded;

  bool get _expandable =>
      widget.status == 'in_progress' || widget.status == 'completed';

  @override
  void initState() {
    super.initState();
    _expanded = widget.status == 'in_progress';
  }

  @override
  void didUpdateWidget(PlanningPhaseSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      _expanded = widget.status == 'in_progress';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final status = _phaseStatus(widget.status);
    final color = _statusColor(tokens, status);
    final header = Row(
      children: [
        Icon(status.icon, color: color, size: 20),
        SizedBox(width: tokens.spaceSm),
        Expanded(
          child: DesignText(
            widget.label,
            style: DesignTextStyle.subtitle,
            color: _expandable ? tokens.textHigh : tokens.textLow,
          ),
        ),
        SizedBox(width: tokens.spaceSm),
        DesignBadge(label: status.label, color: color),
        if (widget.onHelp != null)
          PressScale(
            onTap: widget.onHelp,
            child: Padding(
              padding: EdgeInsets.all(tokens.spaceXs),
              child: Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: tokens.textLow,
              ),
            ),
          ),
        if (_expandable)
          Padding(
            padding: EdgeInsets.only(left: tokens.spaceSm),
            child: Icon(
              _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              color: tokens.textLow,
            ),
          ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            tokens.spaceLg,
            tokens.spaceXl,
            tokens.spaceLg,
            0,
          ),
          child: _expandable
              ? PressScale(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: header,
                )
              : header,
        ),
        if (_expandable && _expanded)
          Padding(
            padding: EdgeInsets.only(top: tokens.spaceMd),
            child: widget.child,
          ),
      ],
    );
  }
}

Color _statusColor(DesignTokens tokens, DesignPlanPhaseStatus status) =>
    switch (status) {
      DesignPlanPhaseStatus.pending => tokens.textLow,
      DesignPlanPhaseStatus.inProgress => tokens.warning,
      DesignPlanPhaseStatus.completed => tokens.success,
      DesignPlanPhaseStatus.skipped => tokens.danger,
    };

// ──────────────────────────── Einladungs-Banner ────────────────────────────

class PlanningInviteBanner extends StatelessWidget {
  const PlanningInviteBanner({
    required this.busy,
    required this.onAccept,
    required this.onDecline,
    super.key,
  });

  final bool busy;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return DesignCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DesignText(
            'Du wurdest zur Planung eingeladen',
            style: DesignTextStyle.subtitle,
            color: tokens.textHigh,
          ),
          SizedBox(height: tokens.spaceSm),
          DesignText(
            'Sag zu, um Termine, Unterkunft und Programm mitzuplanen.',
            style: DesignTextStyle.body,
            color: tokens.textLow,
          ),
          SizedBox(height: tokens.spaceMd),
          Row(
            children: [
              Expanded(
                child: DesignButton(
                  label: 'Ablehnen',
                  variant: DesignButtonVariant.outlined,
                  loading: busy,
                  onPressed: onDecline,
                ),
              ),
              SizedBox(width: tokens.spaceMd),
              Expanded(
                child: DesignButton(
                  label: 'Zusagen',
                  loading: busy,
                  onPressed: onAccept,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────── Mitglieder ────────────────────────────

class PlanningMembersSection extends StatelessWidget {
  const PlanningMembersSection({
    required this.members,
    required this.canManage,
    required this.onInvite,
    required this.onManageMember,
    super.key,
  });

  final List<PlanMember> members;
  final bool canManage;
  final VoidCallback onInvite;
  final void Function(PlanMember member) onManageMember;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return _SectionCard(
      title: 'Teilnehmende',
      action: canManage
          ? DesignButton(
              label: 'Einladen',
              variant: DesignButtonVariant.text,
              icon: Icons.person_add_rounded,
              onPressed: onInvite,
            )
          : null,
      child: members.isEmpty
          ? DesignText(
              'Noch keine Teilnehmenden.',
              style: DesignTextStyle.body,
              color: tokens.textLow,
            )
          : Column(
              children: [
                for (var i = 0; i < members.length; i++) ...[
                  if (i > 0) SizedBox(height: tokens.spaceMd),
                  _MemberRow(
                    member: members[i],
                    canManage: canManage,
                    onTap: () => onManageMember(members[i]),
                  ),
                ],
              ],
            ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.canManage,
    required this.onTap,
  });

  final PlanMember member;
  final bool canManage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final name = member.displayName ?? member.email ?? 'Unbekannt';
    return InkWell(
      onTap: canManage ? onTap : null,
      borderRadius: BorderRadius.circular(tokens.radiusMd),
      child: Row(
        children: [
          DesignAvatar(imageUrl: member.image, name: name, size: 32),
          SizedBox(width: tokens.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DesignText(
                  name,
                  style: DesignTextStyle.body,
                  color: member.isInactive ? tokens.textLow : tokens.textHigh,
                ),
                SizedBox(height: tokens.spaceXs),
                Wrap(
                  spacing: tokens.spaceXs,
                  runSpacing: tokens.spaceXs,
                  children: [
                    if (member.isLeader)
                      DesignBadge(label: 'Leitung', color: tokens.accentA),
                    DesignBadge(label: memberStatusLabel(member.status)),
                  ],
                ),
              ],
            ),
          ),
          if (canManage)
            Icon(Icons.more_vert_rounded, color: tokens.textLow, size: 20),
        ],
      ),
    );
  }
}

// ──────────────────────────── Terminoptionen ────────────────────────────

class PlanningDateOptionsSection extends StatelessWidget {
  const PlanningDateOptionsSection({
    required this.options,
    required this.canManage,
    required this.currentUserId,
    required this.onRespond,
    required this.onCreate,
    required this.onEdit,
    required this.onDelete,
    required this.onFinalize,
    super.key,
  });

  final List<PlanDateOption> options;
  final bool canManage;
  final String? currentUserId;
  final void Function(String optionId, String availability) onRespond;
  final VoidCallback onCreate;
  final void Function(PlanDateOption option) onEdit;
  final void Function(PlanDateOption option) onDelete;
  final void Function(PlanDateOption option) onFinalize;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return _SectionCard(
      title: 'Termine',
      action: DesignButton(
        label: 'Vorschlag',
        variant: DesignButtonVariant.text,
        icon: Icons.add_rounded,
        onPressed: onCreate,
      ),
      child: options.isEmpty
          ? DesignText(
              'Noch keine Terminvorschläge.',
              style: DesignTextStyle.body,
              color: tokens.textLow,
            )
          : Column(
              children: [
                for (var i = 0; i < options.length; i++) ...[
                  if (i > 0) SizedBox(height: tokens.spaceMd),
                  _DateOptionCard(
                    option: options[i],
                    canEdit: _canManageOption(options[i]),
                    canFinalize: canManage && !options[i].isFinal,
                    ownAvailability: _ownAvailability(options[i]),
                    counts: _counts(options[i]),
                    onRespond: (availability) =>
                        onRespond(options[i].id, availability),
                    onEdit: () => onEdit(options[i]),
                    onDelete: () => onDelete(options[i]),
                    onFinalize: () => onFinalize(options[i]),
                  ),
                ],
              ],
            ),
    );
  }

  bool _canManageOption(PlanDateOption option) =>
      canManage ||
      (currentUserId != null && option.proposedBy == currentUserId);

  DesignAvailability? _ownAvailability(PlanDateOption option) {
    for (final response in option.responses) {
      if (response.userId == currentUserId) {
        return _availabilityFromApi(response.availability);
      }
    }
    return null;
  }

  Map<DesignAvailability, int> _counts(PlanDateOption option) {
    final counts = <DesignAvailability, int>{};
    for (final response in option.responses) {
      final availability = _availabilityFromApi(response.availability);
      if (availability == null) continue;
      counts[availability] = (counts[availability] ?? 0) + 1;
    }
    return counts;
  }
}

/// Vorschlagskarte einer Terminoption.
///
/// Der Zeitraum ist der Titel; die (weniger wichtige) Bezeichnung steht klein
/// darunter. Der festgelegte Termin ist direkt in der Karte markiert, die
/// Leitungsaktionen liegen in einem Drei-Punkte-Menü.
class _DateOptionCard extends StatelessWidget {
  const _DateOptionCard({
    required this.option,
    required this.canEdit,
    required this.canFinalize,
    required this.ownAvailability,
    required this.counts,
    required this.onRespond,
    required this.onEdit,
    required this.onDelete,
    required this.onFinalize,
  });

  final PlanDateOption option;
  final bool canEdit;
  final bool canFinalize;
  final DesignAvailability? ownAvailability;
  final Map<DesignAvailability, int> counts;
  final void Function(String availability) onRespond;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onFinalize;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final label = option.label?.trim();
    return Container(
      padding: EdgeInsets.all(tokens.spaceMd),
      decoration: BoxDecoration(
        color: tokens.surfaceVariant,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DesignText(
                      planningDateRange(option),
                      style: DesignTextStyle.body,
                      color: tokens.textHigh,
                    ),
                    if (label != null && label.isNotEmpty) ...[
                      SizedBox(height: tokens.spaceXs),
                      DesignText(
                        label,
                        style: DesignTextStyle.label,
                        color: tokens.textLow,
                      ),
                    ],
                  ],
                ),
              ),
              if (option.isFinal)
                DesignBadge(label: 'Festgelegt', color: tokens.success),
              if (canEdit || canFinalize)
                Padding(
                  padding: EdgeInsets.only(left: tokens.spaceSm),
                  child: DesignIconButton(
                    icon: Icons.more_vert_rounded,
                    onPressed: () => _openMenu(context),
                  ),
                ),
            ],
          ),
          SizedBox(height: tokens.spaceSm),
          Wrap(
            spacing: tokens.spaceSm,
            runSpacing: tokens.spaceSm,
            children: [
              for (final availability in DesignAvailability.values)
                DesignChip(
                  label: availability.label,
                  selected: ownAvailability == availability,
                  onTap: () =>
                      onRespond(planningAvailabilityValue(availability)),
                ),
            ],
          ),
          if (counts.isNotEmpty) ...[
            SizedBox(height: tokens.spaceXs),
            DesignText(
              _countsText(),
              style: DesignTextStyle.label,
              color: tokens.textLow,
            ),
          ],
        ],
      ),
    );
  }

  String _countsText() {
    final parts = <String>[
      for (final availability in DesignAvailability.values)
        if ((counts[availability] ?? 0) > 0)
          '${counts[availability]} ${availability.label}',
    ];
    return parts.join(' · ');
  }

  void _openMenu(BuildContext context) {
    final tokens = DesignTheme.of(context);
    showDesignSheet<void>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canEdit)
            DesignListTile(
              leading: Icon(
                Icons.edit_rounded,
                color: tokens.primary,
                size: 20,
              ),
              title: 'Bearbeiten',
              onTap: () {
                Navigator.pop(context);
                onEdit();
              },
            ),
          if (canFinalize)
            DesignListTile(
              leading: Icon(
                Icons.check_circle_rounded,
                color: tokens.success,
                size: 20,
              ),
              title: 'Festlegen',
              onTap: () {
                Navigator.pop(context);
                onFinalize();
              },
            ),
          if (canEdit)
            DesignListTile(
              leading: Icon(
                Icons.delete_rounded,
                color: tokens.danger,
                size: 20,
              ),
              title: 'Löschen',
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
        ],
      ),
    );
  }
}

// ──────────────────────────── Transport ────────────────────────────

class PlanningTransportSection extends StatelessWidget {
  const PlanningTransportSection({
    required this.transports,
    required this.onEdit,
    super.key,
  });

  final List<PlanTransport> transports;
  final void Function(String direction) onEdit;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return _SectionCard(
      title: 'An- und Abreise',
      action: DesignButton(
        label: 'Meine Angaben',
        variant: DesignButtonVariant.text,
        icon: Icons.edit_rounded,
        onPressed: () => onEdit('outbound'),
      ),
      child: transports.isEmpty
          ? DesignText(
              'Noch keine Angaben zur An- und Abreise.',
              style: DesignTextStyle.body,
              color: tokens.textLow,
            )
          : Column(
              children: [
                for (var i = 0; i < transports.length; i++) ...[
                  if (i > 0) SizedBox(height: tokens.spaceMd),
                  _TransportRow(transport: transports[i]),
                ],
              ],
            ),
    );
  }
}

class _TransportRow extends StatelessWidget {
  const _TransportRow({required this.transport});

  final PlanTransport transport;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final direction = transport.direction == 'return'
        ? 'Rückfahrt'
        : 'Hinfahrt';
    final parts = <String>[
      direction,
      if (transport.mode != null && transport.mode!.isNotEmpty) transport.mode!,
      if (transport.offersRide)
        transport.availableSeats != null
            ? 'bietet ${transport.availableSeats} Plätze'
            : 'bietet Mitfahrgelegenheit',
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DesignAvatar(
          imageUrl: transport.image,
          name: transport.displayName ?? '?',
          size: 32,
        ),
        SizedBox(width: tokens.spaceMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DesignText(
                transport.displayName ?? 'Unbekannt',
                style: DesignTextStyle.body,
                color: tokens.textHigh,
              ),
              SizedBox(height: tokens.spaceXs),
              DesignText(
                parts.join(' · '),
                style: DesignTextStyle.label,
                color: tokens.textLow,
              ),
              if (transport.notes != null && transport.notes!.isNotEmpty) ...[
                SizedBox(height: tokens.spaceXs),
                DesignText(
                  transport.notes!,
                  style: DesignTextStyle.label,
                  color: tokens.textLow,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────── Unterkünfte ────────────────────────────

class PlanningAccommodationSection extends StatelessWidget {
  const PlanningAccommodationSection({
    required this.options,
    required this.canManage,
    required this.currentUserId,
    required this.onCreate,
    required this.onEdit,
    required this.onDelete,
    required this.onSelect,
    super.key,
  });

  final List<PlanAccommodationOption> options;
  final bool canManage;
  final String? currentUserId;
  final VoidCallback onCreate;
  final void Function(PlanAccommodationOption option) onEdit;
  final void Function(PlanAccommodationOption option) onDelete;
  final void Function(PlanAccommodationOption option) onSelect;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return _SectionCard(
      title: 'Unterkunft',
      action: DesignButton(
        label: 'Vorschlag',
        variant: DesignButtonVariant.text,
        icon: Icons.add_rounded,
        onPressed: onCreate,
      ),
      child: options.isEmpty
          ? DesignText(
              'Noch keine Unterkunftsoptionen.',
              style: DesignTextStyle.body,
              color: tokens.textLow,
            )
          : Column(
              children: [
                for (var i = 0; i < options.length; i++) ...[
                  if (i > 0) SizedBox(height: tokens.spaceMd),
                  _AccommodationRow(
                    option: options[i],
                    canManage:
                        canManage ||
                        (currentUserId != null &&
                            options[i].proposedBy == currentUserId),
                    isLeader: canManage,
                    onEdit: () => onEdit(options[i]),
                    onDelete: () => onDelete(options[i]),
                    onSelect: () => onSelect(options[i]),
                  ),
                ],
              ],
            ),
    );
  }
}

class _AccommodationRow extends StatelessWidget {
  const _AccommodationRow({
    required this.option,
    required this.canManage,
    required this.isLeader,
    required this.onEdit,
    required this.onDelete,
    required this.onSelect,
  });

  final PlanAccommodationOption option;
  final bool canManage;
  final bool isLeader;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final price = _priceLine(option);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DesignText(
                option.name ?? 'Unterkunft',
                style: DesignTextStyle.body,
                color: tokens.textHigh,
              ),
            ),
            if (option.isSelected)
              DesignBadge(label: 'Gewählt', color: tokens.success),
          ],
        ),
        if (option.address != null && option.address!.isNotEmpty) ...[
          SizedBox(height: tokens.spaceXs),
          DesignText(
            option.address!,
            style: DesignTextStyle.label,
            color: tokens.textLow,
          ),
        ],
        if (price != null) ...[
          SizedBox(height: tokens.spaceXs),
          DesignText(
            price,
            style: DesignTextStyle.label,
            color: tokens.textLow,
          ),
        ],
        SizedBox(height: tokens.spaceSm),
        Wrap(
          spacing: tokens.spaceSm,
          children: [
            if (isLeader && !option.isSelected)
              DesignButton(
                label: 'Auswählen',
                variant: DesignButtonVariant.text,
                onPressed: onSelect,
              ),
            if (canManage)
              DesignButton(
                label: 'Bearbeiten',
                variant: DesignButtonVariant.text,
                onPressed: onEdit,
              ),
            if (canManage)
              DesignButton(
                label: 'Löschen',
                variant: DesignButtonVariant.text,
                onPressed: onDelete,
              ),
          ],
        ),
      ],
    );
  }

  String? _priceLine(PlanAccommodationOption option) {
    final price = option.pricePerPersonPerNight;
    if (price == null || price.isEmpty) return null;
    final currency = option.currency;
    final suffix = currency != null && currency.isNotEmpty ? ' $currency' : '';
    return '$price$suffix pro Person/Nacht';
  }
}

// ──────────────────────────── Tagesprogramm ────────────────────────────

class PlanningEventsSection extends StatelessWidget {
  const PlanningEventsSection({
    required this.suggestions,
    required this.canManage,
    required this.currentUserId,
    required this.onCreate,
    required this.onEdit,
    required this.onDelete,
    required this.onConfirm,
    required this.onInterest,
    super.key,
  });

  final List<PlanEventSuggestion> suggestions;
  final bool canManage;
  final String? currentUserId;
  final VoidCallback onCreate;
  final void Function(PlanEventSuggestion suggestion) onEdit;
  final void Function(PlanEventSuggestion suggestion) onDelete;
  final void Function(PlanEventSuggestion suggestion, bool confirmed) onConfirm;
  final void Function(PlanEventSuggestion suggestion, String interest)
  onInterest;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return _SectionCard(
      title: 'Tagesprogramm',
      action: DesignButton(
        label: 'Vorschlag',
        variant: DesignButtonVariant.text,
        icon: Icons.add_rounded,
        onPressed: onCreate,
      ),
      child: suggestions.isEmpty
          ? DesignText(
              'Noch keine Vorschläge für das Tagesprogramm.',
              style: DesignTextStyle.body,
              color: tokens.textLow,
            )
          : Column(
              children: [
                for (var i = 0; i < suggestions.length; i++) ...[
                  if (i > 0) SizedBox(height: tokens.spaceMd),
                  _EventRow(
                    suggestion: suggestions[i],
                    canManage:
                        canManage ||
                        (currentUserId != null &&
                            suggestions[i].proposedBy == currentUserId),
                    isLeader: canManage,
                    ownInterest: _ownInterest(suggestions[i]),
                    interestSummary: _interestSummary(suggestions[i]),
                    onEdit: () => onEdit(suggestions[i]),
                    onDelete: () => onDelete(suggestions[i]),
                    onConfirm: (confirmed) =>
                        onConfirm(suggestions[i], confirmed),
                    onInterest: (interest) =>
                        onInterest(suggestions[i], interest),
                  ),
                ],
              ],
            ),
    );
  }

  String? _ownInterest(PlanEventSuggestion suggestion) {
    for (final interest in suggestion.interests) {
      if (interest.userId == currentUserId) return interest.interest;
    }
    return null;
  }

  String? _interestSummary(PlanEventSuggestion suggestion) {
    if (suggestion.interests.isEmpty) return null;
    var yes = 0;
    var maybe = 0;
    var no = 0;
    for (final interest in suggestion.interests) {
      switch (interest.interest) {
        case 'yes':
          yes++;
        case 'maybe':
          maybe++;
        case 'no':
          no++;
      }
    }
    final parts = <String>[
      if (yes > 0) '$yes Ja',
      if (maybe > 0) '$maybe Vielleicht',
      if (no > 0) '$no Nein',
    ];
    return parts.join(' · ');
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.suggestion,
    required this.canManage,
    required this.isLeader,
    required this.ownInterest,
    required this.interestSummary,
    required this.onEdit,
    required this.onDelete,
    required this.onConfirm,
    required this.onInterest,
  });

  final PlanEventSuggestion suggestion;
  final bool canManage;
  final bool isLeader;
  final String? ownInterest;
  final String? interestSummary;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(bool confirmed) onConfirm;
  final void Function(String interest) onInterest;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DesignText(
                suggestion.name,
                style: DesignTextStyle.body,
                color: tokens.textHigh,
              ),
            ),
            if (suggestion.isConfirmed)
              DesignBadge(label: 'Bestätigt', color: tokens.success),
          ],
        ),
        SizedBox(height: tokens.spaceXs),
        DesignText(
          planningEventWhen(suggestion),
          style: DesignTextStyle.label,
          color: tokens.textLow,
        ),
        if (suggestion.address != null && suggestion.address!.isNotEmpty) ...[
          SizedBox(height: tokens.spaceXs),
          DesignText(
            suggestion.address!,
            style: DesignTextStyle.label,
            color: tokens.textLow,
          ),
        ],
        if (suggestion.description != null &&
            suggestion.description!.isNotEmpty) ...[
          SizedBox(height: tokens.spaceXs),
          DesignText(
            suggestion.description!,
            style: DesignTextStyle.label,
            color: tokens.textLow,
          ),
        ],
        SizedBox(height: tokens.spaceSm),
        Wrap(
          spacing: tokens.spaceSm,
          runSpacing: tokens.spaceSm,
          children: [
            DesignChip(
              label: 'Ja',
              selected: ownInterest == 'yes',
              onTap: () => onInterest('yes'),
            ),
            DesignChip(
              label: 'Vielleicht',
              selected: ownInterest == 'maybe',
              onTap: () => onInterest('maybe'),
            ),
            DesignChip(
              label: 'Nein',
              selected: ownInterest == 'no',
              onTap: () => onInterest('no'),
            ),
          ],
        ),
        if (interestSummary != null) ...[
          SizedBox(height: tokens.spaceXs),
          DesignText(
            interestSummary!,
            style: DesignTextStyle.label,
            color: tokens.textLow,
          ),
        ],
        SizedBox(height: tokens.spaceSm),
        Wrap(
          spacing: tokens.spaceSm,
          children: [
            if (isLeader)
              DesignButton(
                label: suggestion.isConfirmed ? 'Zurücknehmen' : 'Bestätigen',
                variant: DesignButtonVariant.text,
                onPressed: () => onConfirm(!suggestion.isConfirmed),
              ),
            if (canManage)
              DesignButton(
                label: 'Bearbeiten',
                variant: DesignButtonVariant.text,
                onPressed: onEdit,
              ),
            if (canManage)
              DesignButton(
                label: 'Löschen',
                variant: DesignButtonVariant.text,
                onPressed: onDelete,
              ),
          ],
        ),
      ],
    );
  }
}
