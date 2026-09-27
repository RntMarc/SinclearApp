import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/date_utils.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_availability_matrix.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/composite/design_list_tile.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_badge.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_chip.dart';
import '../../../design/widgets/primitives/design_fab.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../models/poll_models.dart';
import '../poll_error_messages.dart';
import '../widgets/appointment_option_editor.dart';
import '../widgets/poll_card.dart';
import 'poll_response_screen.dart';

/// Detailansicht einer Umfrage; dispatcht Teilnahme und Aktionen nach `type`.
class PollDetailScreen extends StatefulWidget {
  const PollDetailScreen({required this.id, super.key});

  final String id;

  @override
  State<PollDetailScreen> createState() => _PollDetailScreenState();
}

class _PollDetailScreenState extends State<PollDetailScreen> {
  PollDetail? _detail;
  PollVoteStatus? _voteStatus;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  final Map<String, DesignAvailability> _availability = {};
  final Map<String, Map<DesignAvailability, int>> _availabilityCounts = {};
  final Map<String, DesignAvailability> _savedAvailability = {};
  final Set<String> _voteSelection = {};

  /// Ob die eigene Verfügbarkeit von der zuletzt gespeicherten abweicht.
  bool get _availabilityChanged {
    if (_availability.length != _savedAvailability.length) return true;
    for (final entry in _availability.entries) {
      if (_savedAvailability[entry.key] != entry.value) return true;
    }
    return false;
  }

  Poll? get _poll => _detail?.poll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final scope = AppScope.of(context);
      final detail = await scope.polls.get(widget.id);
      PollVoteStatus? voteStatus;
      if (detail.poll.type == PollType.vote) {
        voteStatus = await scope.polls.voteStatus(widget.id);
      }
      if (detail.poll.type == PollType.appointment) {
        await _loadAvailability();
      }
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _voteStatus = voteStatus;
        _loading = false;
      });
      _markRead();
    } on ApiException catch (e, st) {
      developer.log('Failed to load poll', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = pollErrorMessage(e);
      });
    } catch (e, st) {
      developer.log('Failed to load poll', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Die Umfrage konnte nicht geladen werden.';
      });
    }
  }

  Future<void> _markRead() async {
    final scope = AppScope.of(context);
    final ids = scope.notification.unreadIdsForPoll(widget.id);
    if (ids.isEmpty) return;
    try {
      await scope.notification.markRead(
        ids,
        token: await scope.auth.getAccessToken(),
      );
    } catch (_) {
      // Nächster refreshUnread korrigiert den Stand.
    }
  }

  Future<void> _loadAvailability() async {
    final scope = AppScope.of(context);
    final response = await scope.polls.listAvailability(widget.id);
    final ownId = scope.auth.userId;
    _availability.clear();
    _availabilityCounts.clear();
    for (final vote in response.data) {
      final availability = _designAvailability(vote.availability);
      final counts = _availabilityCounts.putIfAbsent(vote.optionId, () => {});
      counts[availability] = (counts[availability] ?? 0) + 1;
      if (vote.userId == ownId) {
        _availability[vote.optionId] = availability;
      }
    }
    _savedAvailability
      ..clear()
      ..addAll(_availability);
  }

  DesignAvailability _designAvailability(PollAvailability value) =>
      switch (value) {
        PollAvailability.yes => DesignAvailability.yes,
        PollAvailability.maybe => DesignAvailability.maybe,
        PollAvailability.no => DesignAvailability.no,
      };

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      await _load();
    } on ApiException catch (e) {
      _showMessage(pollErrorMessage(e));
    } catch (e, st) {
      developer.log('Poll action failed', error: e, stackTrace: st);
      _showMessage('Die Aktion ist fehlgeschlagen.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final poll = _poll;
    final showSaveFab =
        poll != null &&
        poll.type == PollType.appointment &&
        !poll.isClosed &&
        _availabilityChanged;
    return DesignSurface(
      child: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              DesignSubpageHeader(
                leading: DesignIconButton(
                  icon: Icons.arrow_back_rounded,
                  onPressed: () => context.go('/umfragen'),
                ),
                title: 'Umfrage',
                actions: <Widget>[
                  if (poll?.isCreator == true ||
                      AppScope.of(context).auth.isAdmin)
                    DesignIconButton(
                      icon: Icons.edit_rounded,
                      onPressed: () =>
                          context.go('/umfragen/${widget.id}/bearbeiten'),
                    ),
                ],
              ),
              Expanded(child: _buildBody(tokens)),
            ],
          ),
          if (showSaveFab)
            Positioned(
              bottom: tokens.spaceLg,
              right: tokens.spaceLg,
              child: DesignFab(
                icon: Icons.check_rounded,
                tooltip: 'Verfügbarkeit speichern',
                loading: _busy,
                onPressed: _saveAvailability,
              ),
            ),
        ],
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
          children: <Widget>[
            Icon(Icons.error_outline, size: 48, color: tokens.danger),
            SizedBox(height: tokens.spaceSm),
            DesignText(
              _error!,
              style: DesignTextStyle.body,
              color: tokens.textHigh,
            ),
            SizedBox(height: tokens.spaceLg),
            DesignButton(label: 'Erneut versuchen', onPressed: _load),
          ],
        ),
      );
    }
    final detail = _detail!;
    final poll = detail.poll;
    return ListView(
      padding: EdgeInsets.only(
        top: tokens.spaceXs,
        bottom: tokens.spaceXxl * 2,
      ),
      children: <Widget>[
        _buildHeader(tokens, poll),
        SizedBox(height: tokens.spaceSm),
        _switchSection(tokens, detail),
      ],
    );
  }

  Widget _buildHeader(DesignTokens tokens, Poll poll) {
    final closesAt = poll.closesAt;
    return DesignCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(pollTypeIcon(poll.type), size: 18, color: tokens.primary),
              SizedBox(width: tokens.spaceSm),
              DesignText(
                poll.type.label,
                style: DesignTextStyle.label,
                color: tokens.primary,
              ),
              const Spacer(),
              DesignBadge(
                label: poll.status.label,
                color: poll.isClosed ? tokens.textLow : tokens.success,
              ),
            ],
          ),
          SizedBox(height: tokens.spaceMd),
          DesignText(
            poll.title,
            style: DesignTextStyle.subtitle,
            color: tokens.textHigh,
          ),
          if (poll.description != null && poll.description!.isNotEmpty) ...[
            SizedBox(height: tokens.spaceSm),
            DesignText(
              poll.description!,
              style: DesignTextStyle.body,
              color: tokens.textHigh,
            ),
          ],
          SizedBox(height: tokens.spaceLg),
          _metaRow(
            tokens,
            Icons.person_rounded,
            poll.creatorDisplayName ?? 'Unbekannt',
          ),
          _metaRow(tokens, Icons.lock_rounded, poll.accessMode.label),
          if (closesAt != null)
            _metaRow(
              tokens,
              Icons.schedule_rounded,
              'Frist: ${formatDateTimeInZone(closesAt, AppScope.of(context).timeZones.effective)}',
            ),
          if (poll.type == PollType.form)
            _metaRow(
              tokens,
              Icons.visibility_rounded,
              poll.resultsVisibility.label,
            ),
        ],
      ),
    );
  }

  Widget _metaRow(DesignTokens tokens, IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(top: tokens.spaceSm),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 16, color: tokens.textLow),
          SizedBox(width: tokens.spaceSm),
          Expanded(
            child: DesignText(
              text,
              style: DesignTextStyle.label,
              color: tokens.textLow,
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchSection(DesignTokens tokens, PollDetail detail) {
    switch (detail.poll.type) {
      case PollType.form:
        return _buildFormSection(tokens, detail);
      case PollType.appointment:
        return _buildAppointmentSection(tokens, detail);
      case PollType.vote:
        return _buildVoteSection(tokens, detail);
    }
  }

  // --- Formular ---

  Widget _buildFormSection(DesignTokens tokens, PollDetail detail) {
    final poll = detail.poll;
    final canAnswer = !poll.isClosed;
    final status = detail.participantStatus;
    final canEdit =
        canAnswer &&
        status.hasResponded &&
        poll.submissionMode == PollSubmissionMode.single;
    final canSubmit = canAnswer && !status.hasResponded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DesignCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              DesignText(
                'Fragen',
                style: DesignTextStyle.subtitle,
                color: tokens.textHigh,
              ),
              SizedBox(height: tokens.spaceSm),
              if (detail.questions.isEmpty)
                DesignText(
                  'Keine Fragen.',
                  style: DesignTextStyle.body,
                  color: tokens.textLow,
                )
              else
                for (final question in detail.questions)
                  Padding(
                    padding: EdgeInsets.only(top: tokens.spaceSm),
                    child: DesignListTile(
                      leading: Icon(
                        Icons.help_outline_rounded,
                        color: tokens.textLow,
                      ),
                      title: question.title,
                      subtitle: question.isRequired ? 'Pflichtfrage' : null,
                    ),
                  ),
              SizedBox(height: tokens.spaceMd),
              if (status.hasResponded)
                DesignText(
                  'Du hast bereits geantwortet.',
                  style: DesignTextStyle.label,
                  color: tokens.success,
                ),
            ],
          ),
        ),
        if (canSubmit || canEdit)
          Padding(
            padding: EdgeInsets.only(
              top: tokens.spaceLg,
              left: tokens.spaceLg,
              right: tokens.spaceLg,
            ),
            child: DesignButton(
              label: status.hasResponded ? 'Antwort bearbeiten' : 'Antworten',
              icon: Icons.edit_note_rounded,
              fullWidth: true,
              onPressed: _busy
                  ? null
                  : () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PollResponseScreen(
                            pollId: widget.id,
                            detail: detail,
                          ),
                        ),
                      );
                      await _load();
                    },
            ),
          ),
        if (_canViewResults(detail))
          Padding(
            padding: EdgeInsets.only(
              top: tokens.spaceSm,
              left: tokens.spaceLg,
              right: tokens.spaceLg,
            ),
            child: DesignButton(
              label: 'Ergebnisse',
              icon: Icons.bar_chart_rounded,
              variant: DesignButtonVariant.text,
              fullWidth: true,
              onPressed: () => context.go('/umfragen/${widget.id}/ergebnisse'),
            ),
          ),
      ],
    );
  }

  bool _canViewResults(PollDetail detail) {
    if (detail.poll.type != PollType.form) return false;
    if (detail.poll.isCreator) return true;
    if (detail.poll.resultsVisibility != PollResultsVisibility.participants) {
      return false;
    }
    return detail.participantStatus.hasResponded;
  }

  // --- Terminfindung ---

  Widget _buildAppointmentSection(DesignTokens tokens, PollDetail detail) {
    final poll = detail.poll;
    final options = detail.appointmentOptions;
    final open = !poll.isClosed;
    final matrix = <DesignAvailabilityOption>[
      for (final option in options)
        DesignAvailabilityOption(
          id: option.id,
          label: option.displayLabel,
          selected: _availability[option.id],
          counts: _availabilityCounts[option.id] ?? const {},
          isCounterProposal: option.isCounterProposal,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (poll.finalizedOptionId != null) ...<Widget>[
          DesignCard(
            child: Row(
              children: <Widget>[
                Icon(Icons.event_available_rounded, color: tokens.success),
                SizedBox(width: tokens.spaceSm),
                Expanded(
                  child: DesignText(
                    'Festgelegter Termin: '
                    '${_finalizedLabel(options)}',
                    style: DesignTextStyle.body,
                    color: tokens.textHigh,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: tokens.spaceSm),
        ],
        if (options.isEmpty)
          DesignCard(
            child: DesignText(
              'Keine Terminvorschläge.',
              style: DesignTextStyle.body,
              color: tokens.textLow,
            ),
          )
        else
          DesignAvailabilityMatrix(
            options: matrix,
            readOnly: !open,
            onChanged: open
                ? (optionId, value) {
                    setState(() {
                      if (value == null) {
                        _availability.remove(optionId);
                      } else {
                        _availability[optionId] = value;
                      }
                    });
                  }
                : null,
          ),
        if (open && poll.allowCounterProposals)
          Padding(
            padding: EdgeInsets.only(
              top: tokens.spaceLg,
              left: tokens.spaceLg,
              right: tokens.spaceLg,
            ),
            child: DesignButton(
              label: 'Gegenvorschlag',
              icon: Icons.add_rounded,
              variant: DesignButtonVariant.ghost,
              fullWidth: true,
              onPressed: _busy ? null : _addCounterProposal,
            ),
          ),
      ],
    );
  }

  String _finalizedLabel(List<PollOption> options) {
    for (final option in options) {
      if (option.id == _poll?.finalizedOptionId) return option.displayLabel;
    }
    return '–';
  }

  Future<void> _saveAvailability() async {
    await _run(() async {
      final scope = AppScope.of(context);
      final inputs = _availability.entries
          .map(
            (entry) => PollAvailabilityInput(
              optionId: entry.key,
              availability: switch (entry.value) {
                DesignAvailability.yes => PollAvailability.yes,
                DesignAvailability.maybe => PollAvailability.maybe,
                DesignAvailability.no => PollAvailability.no,
              },
            ),
          )
          .toList();
      await scope.polls.setAvailability(
        widget.id,
        PollAvailabilitySetRequest(availability: inputs),
      );
    });
  }

  Future<void> _addCounterProposal() async {
    final effectiveZone = AppScope.of(context).timeZones.effective;
    final input = await showDesignSheet<PollOptionInput>(
      context: context,
      child: _CounterProposalSheet(timezone: effectiveZone),
    );
    if (input == null) return;
    await _run(() async {
      await AppScope.of(context).polls.addCounterProposal(widget.id, input);
    });
  }

  // --- Abstimmung ---

  Widget _buildVoteSection(DesignTokens tokens, PollDetail detail) {
    final poll = detail.poll;
    final options = detail.appointmentOptions;
    final status = _voteStatus;
    final hasVoted = status?.hasVoted ?? false;
    final open = !poll.isClosed;
    final canVote = open && !hasVoted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DesignCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              DesignText(
                canVote
                    ? (poll.allowMultiple
                          ? 'Wähle eine oder mehrere Optionen'
                          : 'Wähle eine Option')
                    : 'Optionen',
                style: DesignTextStyle.subtitle,
                color: tokens.textHigh,
              ),
              SizedBox(height: tokens.spaceMd),
              if (options.isEmpty)
                DesignText(
                  'Keine Optionen.',
                  style: DesignTextStyle.body,
                  color: tokens.textLow,
                )
              else
                Wrap(
                  spacing: tokens.spaceSm,
                  runSpacing: tokens.spaceSm,
                  children: <Widget>[
                    for (final option in options)
                      DesignChip(
                        label: option.displayLabel,
                        selected: canVote
                            ? _voteSelection.contains(option.id)
                            : hasVoted &&
                                  (status?.votedOptionIds.contains(option.id) ??
                                      false),
                        onTap: canVote
                            ? () => setState(() {
                                if (poll.allowMultiple) {
                                  if (!_voteSelection.add(option.id)) {
                                    _voteSelection.remove(option.id);
                                  }
                                } else if (_voteSelection.length == 1 &&
                                    _voteSelection.contains(option.id)) {
                                  _voteSelection.clear();
                                } else {
                                  _voteSelection
                                    ..clear()
                                    ..add(option.id);
                                }
                              })
                            : null,
                      ),
                  ],
                ),
              if (hasVoted) ...[
                SizedBox(height: tokens.spaceMd),
                DesignText(
                  'Du hast bereits abgestimmt.',
                  style: DesignTextStyle.label,
                  color: tokens.success,
                ),
              ] else if (!open) ...[
                SizedBox(height: tokens.spaceMd),
                DesignText(
                  'Die Abstimmung ist geschlossen.',
                  style: DesignTextStyle.label,
                  color: tokens.textLow,
                ),
              ],
            ],
          ),
        ),
        if (canVote)
          Padding(
            padding: EdgeInsets.only(
              top: tokens.spaceLg,
              left: tokens.spaceLg,
              right: tokens.spaceLg,
            ),
            child: DesignButton(
              label: 'Abstimmen',
              icon: Icons.how_to_vote_rounded,
              fullWidth: true,
              loading: _busy,
              onPressed: _busy || _voteSelection.isEmpty ? null : _vote,
            ),
          ),
        if (poll.isCreator && poll.isClosed)
          Padding(
            padding: EdgeInsets.only(
              top: tokens.spaceSm,
              left: tokens.spaceLg,
              right: tokens.spaceLg,
            ),
            child: DesignButton(
              label: 'Ergebnisse',
              icon: Icons.bar_chart_rounded,
              variant: DesignButtonVariant.text,
              fullWidth: true,
              onPressed: () => context.go('/umfragen/${widget.id}/ergebnisse'),
            ),
          ),
      ],
    );
  }

  Future<void> _vote() async {
    await _run(() async {
      await AppScope.of(context).polls.vote(widget.id, _voteSelection.toList());
      _voteSelection.clear();
    });
  }
}

/// Sheet zum Anlegen eines Gegenvorschlags (ganztägig oder getaktet).
class _CounterProposalSheet extends StatefulWidget {
  const _CounterProposalSheet({required this.timezone});

  final String timezone;

  @override
  State<_CounterProposalSheet> createState() => _CounterProposalSheetState();
}

class _CounterProposalSheetState extends State<_CounterProposalSheet> {
  PollOptionInput? _input;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DesignText(
          'Gegenvorschlag',
          style: DesignTextStyle.subtitle,
          color: tokens.textHigh,
        ),
        SizedBox(height: tokens.spaceMd),
        AppointmentOptionEditor(
          timezone: widget.timezone,
          onChanged: (value) => setState(() => _input = value),
        ),
        SizedBox(height: tokens.spaceLg),
        DesignButton(
          label: 'Vorschlagen',
          fullWidth: true,
          onPressed: _input == null
              ? null
              : () => Navigator.pop(context, _input),
        ),
      ],
    );
  }
}
