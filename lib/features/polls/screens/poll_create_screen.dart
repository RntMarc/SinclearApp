import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/date_utils.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/composite/design_question_editor.dart';
import '../../../design/widgets/composite/design_question_field.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_chip.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../../design/widgets/primitives/design_text_field.dart';
import '../models/poll_models.dart';
import '../poll_error_messages.dart';
import '../widgets/appointment_option_editor.dart';
import '../widgets/poll_user_picker_sheet.dart';

/// Wizard zum Anlegen einer Umfrage bzw. Formular zum Bearbeiten der
/// Metadaten (bei gesetzter [pollId]).
class PollCreateScreen extends StatefulWidget {
  const PollCreateScreen({this.pollId, super.key});

  final String? pollId;

  bool get isEditing => pollId != null;

  @override
  State<PollCreateScreen> createState() => _PollCreateScreenState();
}

class _OptionSlot {
  _OptionSlot() : key = Object();

  final Object key;
  PollOptionInput? value;
}

class _QuestionSlot {
  _QuestionSlot(this.draft) : key = Object();

  final Object key;
  DesignQuestionDraft draft;
}

class _PollCreateScreenState extends State<PollCreateScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();

  PollType _type = PollType.form;
  PollAccessMode _accessMode = PollAccessMode.invited;
  PollSubmissionMode _submissionMode = PollSubmissionMode.single;
  PollResultsVisibility _resultsVisibility = PollResultsVisibility.creator;
  bool _allowCounterProposals = false;
  DateTime? _closesAt;

  final List<_QuestionSlot> _questions = [];
  final List<_OptionSlot> _appointmentOptions = [];
  final List<TextEditingController> _voteOptions = [];
  final Set<String> _inviteUserIds = {};

  int _step = 0;
  bool _loading = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadForEdit());
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    for (final controller in _voteOptions) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadForEdit() async {
    setState(() => _loading = true);
    try {
      final detail = await AppScope.of(context).polls.get(widget.pollId!);
      final poll = detail.poll;
      if (!mounted) return;
      setState(() {
        _type = poll.type;
        _title.text = poll.title;
        _description.text = poll.description ?? '';
        _accessMode = poll.accessMode;
        _submissionMode = poll.submissionMode;
        _resultsVisibility = poll.resultsVisibility;
        _allowCounterProposals = poll.allowCounterProposals;
        _closesAt = poll.closesAt == null
            ? null
            : instantToWallTime(
                poll.closesAt!,
                AppScope.of(context).timeZones.effective,
              );
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = pollErrorMessage(e);
      });
    } catch (e, st) {
      developer.log('Failed to load poll for edit', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Die Umfrage konnte nicht geladen werden.';
      });
    }
  }

  int get _lastStep => widget.isEditing ? 0 : 3;

  String get _stepTitle => widget.isEditing
      ? 'Bearbeiten'
      : switch (_step) {
          0 => 'Typ',
          1 => 'Basisdaten',
          2 => _type == PollType.form ? 'Fragen' : 'Optionen',
          _ => 'Einladungen',
        };

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      _showMessage('Bitte gib einen Titel an.');
      return;
    }
    setState(() => _saving = true);
    try {
      final scope = AppScope.of(context);
      final zone = scope.timeZones.effective;
      if (widget.isEditing) {
        await scope.polls.update(
          widget.pollId!,
          PollUpdateRequest(
            title: _title.text.trim(),
            description: _description.text.trim(),
            closesAt: _closesAt == null
                ? null
                : wallTimeToInstant(_closesAt!, zone),
            closesAtTimezone: zone,
            accessMode: _accessMode,
            submissionMode: _type == PollType.form ? _submissionMode : null,
            resultsVisibility: _type == PollType.form
                ? _resultsVisibility
                : null,
            allowCounterProposals: _type == PollType.appointment
                ? _allowCounterProposals
                : null,
          ),
        );
        if (!mounted) return;
        context.go('/umfragen/${widget.pollId}');
        return;
      }

      final request = PollCreateRequest(
        type: _type,
        title: _title.text.trim(),
        description: _description.text.trim(),
        closesAt: _closesAt == null
            ? null
            : wallTimeToInstant(_closesAt!, zone),
        closesAtTimezone: zone,
        accessMode: _accessMode,
        submissionMode: _submissionMode,
        resultsVisibility: _resultsVisibility,
        allowCounterProposals: _allowCounterProposals,
        inviteUserIds: _inviteUserIds.toList(),
        questions: _type == PollType.form
            ? _questions
                  .map((slot) => slot.draft)
                  .where((q) => q.title.trim().isNotEmpty)
                  .map(
                    (q) => PollQuestionInput(
                      type: _questionType(q.kind),
                      title: q.title.trim(),
                      description: q.description,
                      isRequired: q.isRequired,
                      config: q.config,
                      optionLabels: q.optionLabels,
                    ),
                  )
                  .toList()
            : const [],
        options: switch (_type) {
          PollType.appointment =>
            _appointmentOptions
                .map((slot) => slot.value)
                .whereType<PollOptionInput>()
                .toList(),
          PollType.vote =>
            _voteOptions
                .map((c) => PollOptionInput(label: c.text.trim()))
                .where((o) => o.label!.isNotEmpty)
                .toList(),
          PollType.form => const [],
        },
      );
      final created = await scope.polls.create(request);
      if (!mounted) return;
      context.go('/umfragen/${created.poll.id}');
    } on ApiException catch (e) {
      _showMessage(pollErrorMessage(e));
    } catch (e, st) {
      developer.log('Failed to save poll', error: e, stackTrace: st);
      _showMessage('Die Umfrage konnte nicht gespeichert werden.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  PollQuestionType _questionType(DesignQuestionKind kind) => switch (kind) {
    DesignQuestionKind.text => PollQuestionType.text,
    DesignQuestionKind.textarea => PollQuestionType.textarea,
    DesignQuestionKind.number => PollQuestionType.number,
    DesignQuestionKind.email => PollQuestionType.email,
    DesignQuestionKind.coordinates => PollQuestionType.coordinates,
    DesignQuestionKind.date => PollQuestionType.date,
    DesignQuestionKind.datetime => PollQuestionType.datetime,
    DesignQuestionKind.url => PollQuestionType.url,
    DesignQuestionKind.phone => PollQuestionType.phone,
    DesignQuestionKind.singleChoice => PollQuestionType.singleChoice,
    DesignQuestionKind.multipleChoice => PollQuestionType.multipleChoice,
    DesignQuestionKind.boolean => PollQuestionType.boolean,
    DesignQuestionKind.rating => PollQuestionType.rating,
  };

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickInvitees() async {
    try {
      final scope = AppScope.of(context);
      final all = await scope.user.listAll();
      if (!mounted) return;
      final selected = await showDesignSheet<List<String>>(
        context: context,
        child: PollUserPickerSheet(users: all, excludedIds: const {}),
      );
      if (selected == null) return;
      setState(() {
        _inviteUserIds
          ..clear()
          ..addAll(selected);
      });
    } catch (e, st) {
      developer.log('Failed to load users', error: e, stackTrace: st);
      _showMessage('Nutzer konnten nicht geladen werden.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return DesignSurface(
      child: Column(
        children: <Widget>[
          DesignSubpageHeader(
            leading: DesignIconButton(
              icon: Icons.close_rounded,
              onPressed: () => context.go(
                widget.isEditing ? '/umfragen/${widget.pollId}' : '/umfragen',
              ),
            ),
            title: widget.isEditing ? 'Umfrage bearbeiten' : 'Neue Umfrage',
          ),
          if (!widget.isEditing)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
              child: DesignText(
                'Schritt ${_step + 1} von ${_lastStep + 1} · $_stepTitle',
                style: DesignTextStyle.label,
                color: tokens.textLow,
              ),
            ),
          Expanded(child: _buildBody(tokens)),
          _buildFooter(tokens),
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
        child: DesignText(
          _error!,
          style: DesignTextStyle.body,
          color: tokens.textHigh,
        ),
      );
    }
    if (widget.isEditing) return _buildBasics(tokens);
    return switch (_step) {
      0 => _buildTypeStep(tokens),
      1 => _buildBasics(tokens),
      2 => _buildOptionsStep(tokens),
      _ => _buildInvitesStep(tokens),
    };
  }

  Widget _buildTypeStep(DesignTokens tokens) {
    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceLg,
        vertical: tokens.spaceSm,
      ),
      children: <Widget>[
        for (final type in PollType.values)
          Padding(
            padding: EdgeInsets.only(bottom: tokens.spaceSm),
            child: DesignChip(
              label: type.label,
              selected: _type == type,
              onTap: () {
                setState(() => _type = type);
                _ensureOptions();
              },
            ),
          ),
      ],
    );
  }

  void _ensureOptions() {
    if (_appointmentOptions.isEmpty) {
      _appointmentOptions.add(_OptionSlot());
    }
    if (_voteOptions.isEmpty) {
      _voteOptions.add(TextEditingController());
    }
  }

  Widget _buildBasics(DesignTokens tokens) {
    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceLg,
        vertical: tokens.spaceSm,
      ),
      children: <Widget>[
        DesignTextField(
          hint: 'Titel',
          controller: _title,
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(height: tokens.spaceSm),
        DesignTextField(
          hint: 'Beschreibung (optional)',
          controller: _description,
          maxLines: 4,
        ),
        SizedBox(height: tokens.spaceMd),
        DesignQuestionField(
          spec: const DesignQuestionSpec(
            kind: DesignQuestionKind.datetime,
            title: 'Frist (optional)',
          ),
          value: _closesAt,
          onChanged: (value) =>
              setState(() => _closesAt = value is DateTime ? value : null),
        ),
        SizedBox(height: tokens.spaceMd),
        _label(tokens, 'Zugriff'),
        Wrap(
          spacing: tokens.spaceSm,
          children: <Widget>[
            for (final mode in PollAccessMode.values)
              DesignChip(
                label: mode.label,
                selected: _accessMode == mode,
                onTap: () => setState(() => _accessMode = mode),
              ),
          ],
        ),
        if (_type == PollType.form) ...<Widget>[
          SizedBox(height: tokens.spaceMd),
          _label(tokens, 'Einreichung'),
          Wrap(
            spacing: tokens.spaceSm,
            children: <Widget>[
              for (final mode in PollSubmissionMode.values)
                DesignChip(
                  label: mode.label,
                  selected: _submissionMode == mode,
                  onTap: () => setState(() => _submissionMode = mode),
                ),
            ],
          ),
          SizedBox(height: tokens.spaceMd),
          _label(tokens, 'Ergebnissichtbarkeit'),
          Wrap(
            spacing: tokens.spaceSm,
            children: <Widget>[
              for (final visibility in PollResultsVisibility.values)
                DesignChip(
                  label: visibility.label,
                  selected: _resultsVisibility == visibility,
                  onTap: () => setState(() => _resultsVisibility = visibility),
                ),
            ],
          ),
        ],
        if (_type == PollType.appointment) ...<Widget>[
          SizedBox(height: tokens.spaceMd),
          DesignChip(
            label: 'Gegenvorschläge erlauben',
            selected: _allowCounterProposals,
            onTap: () => setState(
              () => _allowCounterProposals = !_allowCounterProposals,
            ),
          ),
        ],
      ],
    );
  }

  Widget _label(DesignTokens tokens, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: tokens.spaceXs),
      child: DesignText(
        text,
        style: DesignTextStyle.label,
        color: tokens.textHigh,
      ),
    );
  }

  Widget _buildOptionsStep(DesignTokens tokens) {
    if (_type == PollType.form) {
      return ListView(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceLg,
          vertical: tokens.spaceSm,
        ),
        children: <Widget>[
          for (var i = 0; i < _questions.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: tokens.spaceLg),
              child: DesignQuestionEditor(
                key: ObjectKey(_questions[i].key),
                draft: _questions[i].draft,
                onChanged: (draft) =>
                    setState(() => _questions[i].draft = draft),
                onRemove: () => setState(() => _questions.removeAt(i)),
              ),
            ),
          DesignButton(
            label: 'Frage hinzufügen',
            icon: Icons.add_rounded,
            variant: DesignButtonVariant.ghost,
            onPressed: () => setState(
              () => _questions.add(
                _QuestionSlot(
                  const DesignQuestionDraft(kind: DesignQuestionKind.text),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (_type == PollType.appointment) {
      return ListView(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceLg,
          vertical: tokens.spaceSm,
        ),
        children: <Widget>[
          for (var i = 0; i < _appointmentOptions.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: tokens.spaceLg),
              child: AppointmentOptionEditor(
                key: ObjectKey(_appointmentOptions[i].key),
                timezone: AppScope.of(context).timeZones.effective,
                onChanged: (value) =>
                    setState(() => _appointmentOptions[i].value = value),
                onRemove: _appointmentOptions.length > 1
                    ? () => setState(() => _appointmentOptions.removeAt(i))
                    : null,
              ),
            ),
          DesignButton(
            label: 'Terminvorschlag hinzufügen',
            icon: Icons.add_rounded,
            variant: DesignButtonVariant.ghost,
            onPressed: () =>
                setState(() => _appointmentOptions.add(_OptionSlot())),
          ),
        ],
      );
    }

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceLg,
        vertical: tokens.spaceSm,
      ),
      children: <Widget>[
        for (var i = 0; i < _voteOptions.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: tokens.spaceSm),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: DesignTextField(
                    hint: 'Option ${i + 1}',
                    controller: _voteOptions[i],
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                SizedBox(width: tokens.spaceSm),
                DesignIconButton(
                  icon: Icons.remove_circle_outline_rounded,
                  onPressed: _voteOptions.length > 1
                      ? () => setState(() => _voteOptions.removeAt(i).dispose())
                      : null,
                ),
              ],
            ),
          ),
        DesignButton(
          label: 'Option hinzufügen',
          icon: Icons.add_rounded,
          variant: DesignButtonVariant.ghost,
          onPressed: () =>
              setState(() => _voteOptions.add(TextEditingController())),
        ),
      ],
    );
  }

  Widget _buildInvitesStep(DesignTokens tokens) {
    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceLg,
        vertical: tokens.spaceSm,
      ),
      children: <Widget>[
        DesignText(
          _inviteUserIds.isEmpty
              ? 'Noch niemand ausgewählt.'
              : '${_inviteUserIds.length} Nutzer ausgewählt.',
          style: DesignTextStyle.body,
          color: tokens.textLow,
        ),
        SizedBox(height: tokens.spaceMd),
        DesignButton(
          label: 'Nutzer auswählen',
          icon: Icons.person_add_rounded,
          variant: DesignButtonVariant.ghost,
          onPressed: _pickInvitees,
        ),
      ],
    );
  }

  Widget _buildFooter(DesignTokens tokens) {
    return Padding(
      padding: EdgeInsets.all(tokens.spaceLg),
      child: Row(
        children: <Widget>[
          if (!widget.isEditing && _step > 0)
            Expanded(
              child: DesignButton(
                label: 'Zurück',
                variant: DesignButtonVariant.ghost,
                onPressed: _saving ? null : () => setState(() => _step--),
              ),
            ),
          if (!widget.isEditing && _step > 0) SizedBox(width: tokens.spaceSm),
          Expanded(
            child: DesignButton(
              label: _isLast ? 'Speichern' : 'Weiter',
              icon: _isLast ? Icons.check_rounded : null,
              fullWidth: true,
              loading: _saving,
              onPressed: _saving
                  ? null
                  : _isLast
                  ? _save
                  : _next,
            ),
          ),
        ],
      ),
    );
  }

  bool get _isLast => widget.isEditing || _step >= _lastStep;

  void _next() {
    _ensureOptions();
    if (_step == 0 && _type == PollType.form && _questions.isEmpty) {
      _questions.add(
        _QuestionSlot(const DesignQuestionDraft(kind: DesignQuestionKind.text)),
      );
    }
    setState(() => _step++);
  }
}
