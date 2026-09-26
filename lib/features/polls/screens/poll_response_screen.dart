import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/date_utils.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../models/poll_models.dart';
import '../poll_error_messages.dart';
import '../widgets/question_field.dart';

/// Antwortformular für `form`-Umfragen (Anlegen und Bearbeiten).
class PollResponseScreen extends StatefulWidget {
  const PollResponseScreen({required this.pollId, this.detail, super.key});

  final String pollId;

  /// Bereits geladenes Detail (aus dem Detail-Screen); wird sonst selbst
  /// nachgeladen.
  final PollDetail? detail;

  @override
  State<PollResponseScreen> createState() => _PollResponseScreenState();
}

class _PollResponseScreenState extends State<PollResponseScreen> {
  PollDetail? _detail;
  PollResponse? _existing;
  final Map<String, Object?> _values = {};
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final scope = AppScope.of(context);
      final detail = widget.detail ?? await scope.polls.get(widget.pollId);
      final existing = await scope.polls.myResponse(widget.pollId);
      if (!mounted) return;
      _prefill(existing, detail);
      setState(() {
        _detail = detail;
        _existing = existing;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = pollErrorMessage(e);
      });
    } catch (e, st) {
      developer.log('Failed to load response', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Das Formular konnte nicht geladen werden.';
      });
    }
  }

  void _prefill(PollResponse? response, PollDetail detail) {
    _values.clear();
    final answers = response?.answers ?? const {};
    for (final question in detail.questions) {
      _values[question.id] = _toUiValue(question.type, answers[question.id]);
    }
  }

  Object? _toUiValue(PollQuestionType type, Object? raw) {
    if (raw == null) return null;
    switch (type) {
      case PollQuestionType.boolean:
        return parseBooleanAnswer(raw);
      case PollQuestionType.coordinates:
        return raw.toString();
      case PollQuestionType.date:
        return raw is String ? parseApiDateOnly(raw) : null;
      case PollQuestionType.datetime:
        if (raw is String) {
          final instant = parseApiInstant(raw);
          return instantToWallTime(
            instant,
            AppScope.of(context).timeZones.effective,
          );
        }
        return null;
      case PollQuestionType.multipleChoice:
        return parseMultipleChoiceAnswer(raw);
      case PollQuestionType.number:
      case PollQuestionType.rating:
        return raw is num ? raw : num.tryParse(raw.toString());
      default:
        return raw.toString();
    }
  }

  Object? _toApiValue(PollQuestionType type, Object? value) {
    if (value == null) return null;
    switch (type) {
      case PollQuestionType.boolean:
        return value is bool ? encodeBooleanAnswer(value) : null;
      case PollQuestionType.date:
        return value is DateTime ? toApiDateOnly(value) : null;
      case PollQuestionType.datetime:
        if (value is DateTime) {
          final zone = AppScope.of(context).timeZones.effective;
          return toApiInstant(wallTimeToInstant(value, zone), zone);
        }
        return null;
      case PollQuestionType.multipleChoice:
        final list = parseMultipleChoiceAnswer(value);
        return list.isEmpty ? null : list;
      case PollQuestionType.coordinates:
      case PollQuestionType.number:
      case PollQuestionType.rating:
      case PollQuestionType.singleChoice:
      case PollQuestionType.text:
      case PollQuestionType.textarea:
      case PollQuestionType.email:
      case PollQuestionType.url:
      case PollQuestionType.phone:
        return value;
    }
  }

  bool _isFilled(Object? value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    if (value is List) return value.isNotEmpty;
    return true;
  }

  Future<void> _submit() async {
    final detail = _detail!;
    for (final question in detail.questions) {
      if (question.isRequired && !_isFilled(_values[question.id])) {
        _showMessage('Bitte beantworte die Pflichtfrage „${question.title}“.');
        return;
      }
    }

    final answers = <PollAnswerInput>[
      for (final question in detail.questions)
        PollAnswerInput(
          questionId: question.id,
          value: _toApiValue(question.type, _values[question.id]),
        ),
    ];
    final request = PollResponseSubmitRequest(answers: answers);

    setState(() => _saving = true);
    try {
      final scope = AppScope.of(context);
      final existing = _existing;
      if (existing != null) {
        await scope.polls.updateResponse(widget.pollId, existing.id, request);
      } else {
        await scope.polls.submitResponse(widget.pollId, request);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      _showMessage(pollErrorMessage(e));
    } catch (e, st) {
      developer.log('Failed to submit response', error: e, stackTrace: st);
      _showMessage('Die Antwort konnte nicht gespeichert werden.');
    } finally {
      if (mounted) setState(() => _saving = false);
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
    return DesignSurface(
      child: Column(
        children: <Widget>[
          DesignSubpageHeader(
            leading: DesignIconButton(
              icon: Icons.close_rounded,
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: _existing == null ? 'Antworten' : 'Antwort bearbeiten',
          ),
          Expanded(child: _buildBody(tokens)),
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
    final detail = _detail!;
    return ListView(
      padding: EdgeInsets.only(bottom: tokens.spaceXxl),
      children: <Widget>[
        for (final question in detail.questions)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spaceLg,
              vertical: tokens.spaceSm,
            ),
            child: QuestionField(
              question: question,
              options: detail.optionsFor(question.id),
              value: _values[question.id],
              onChanged: (value) =>
                  setState(() => _values[question.id] = value),
            ),
          ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spaceLg,
            vertical: tokens.spaceSm,
          ),
          child: DesignButton(
            label: 'Absenden',
            icon: Icons.send_rounded,
            fullWidth: true,
            loading: _saving,
            onPressed: _saving ? null : _submit,
          ),
        ),
      ],
    );
  }
}
