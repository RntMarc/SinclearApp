import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/date_utils.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_poll_result_bar.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../models/poll_models.dart';
import '../poll_error_messages.dart';

/// Ergebnisansicht: Rohantworten (`form`) bzw. Stimmenzählung (`vote`).
class PollResultsScreen extends StatefulWidget {
  const PollResultsScreen({required this.pollId, super.key});

  final String pollId;

  @override
  State<PollResultsScreen> createState() => _PollResultsScreenState();
}

class _PollResultsScreenState extends State<PollResultsScreen> {
  PollDetail? _detail;
  List<PollResponse> _responses = [];
  List<PollResultEntry> _results = [];
  int _totalParticipants = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final scope = AppScope.of(context);
      final detail = await scope.polls.get(widget.pollId);
      if (detail.poll.type == PollType.vote) {
        final response = await scope.polls.results(widget.pollId);
        if (!mounted) return;
        setState(() {
          _detail = detail;
          _results = response.data;
          _totalParticipants = response.totalParticipants;
          _loading = false;
        });
        return;
      }
      final response = await scope.polls.listResponses(widget.pollId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _responses = response.data;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = pollErrorMessage(e);
      });
    } catch (e, st) {
      developer.log('Failed to load results', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Ergebnisse konnten nicht geladen werden.';
      });
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
              icon: Icons.arrow_back_rounded,
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: 'Ergebnisse',
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.lock_outline_rounded, size: 48, color: tokens.textLow),
            SizedBox(height: tokens.spaceSm),
            DesignText(
              _error!,
              style: DesignTextStyle.body,
              color: tokens.textHigh,
            ),
          ],
        ),
      );
    }
    final detail = _detail!;
    if (detail.poll.type == PollType.vote) {
      return _buildVoteResults(tokens);
    }
    return _buildFormResponses(tokens, detail);
  }

  Widget _buildVoteResults(DesignTokens tokens) {
    if (_results.isEmpty) {
      return Center(
        child: DesignText(
          'Noch keine Stimmen.',
          style: DesignTextStyle.body,
          color: tokens.textLow,
        ),
      );
    }
    return ListView(
      padding: EdgeInsets.only(bottom: tokens.spaceXxl),
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spaceLg,
            vertical: tokens.spaceSm,
          ),
          child: DesignText(
            '$_totalParticipants Teilnehmer',
            style: DesignTextStyle.label,
            color: tokens.textLow,
          ),
        ),
        for (final entry in _results)
          DesignPollResultBar(
            label: entry.label ?? 'Option',
            votes: entry.votes,
            percentage: entry.percentage,
          ),
      ],
    );
  }

  Widget _buildFormResponses(DesignTokens tokens, PollDetail detail) {
    if (_responses.isEmpty) {
      return Center(
        child: DesignText(
          'Noch keine Antworten.',
          style: DesignTextStyle.body,
          color: tokens.textLow,
        ),
      );
    }
    return ListView(
      padding: EdgeInsets.only(bottom: tokens.spaceXxl),
      children: <Widget>[
        for (final response in _responses)
          DesignCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DesignText(
                  response.userDisplayName ?? 'Unbekannt',
                  style: DesignTextStyle.subtitle,
                  color: tokens.textHigh,
                ),
                SizedBox(height: tokens.spaceSm),
                for (final question in detail.questions)
                  _answerRow(tokens, detail, question, response),
              ],
            ),
          ),
      ],
    );
  }

  Widget _answerRow(
    DesignTokens tokens,
    PollDetail detail,
    PollQuestion question,
    PollResponse response,
  ) {
    return Padding(
      padding: EdgeInsets.only(top: tokens.spaceSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DesignText(
            question.title,
            style: DesignTextStyle.label,
            color: tokens.textLow,
          ),
          SizedBox(height: tokens.spaceXs),
          DesignText(
            _formatAnswer(detail, question, response.answers[question.id]),
            style: DesignTextStyle.body,
            color: tokens.textHigh,
          ),
        ],
      ),
    );
  }

  String _formatAnswer(PollDetail detail, PollQuestion question, Object? raw) {
    if (raw == null || (raw is String && raw.isEmpty)) return '–';
    switch (question.type) {
      case PollQuestionType.boolean:
        return parseBooleanAnswer(raw) == true ? 'Ja' : 'Nein';
      case PollQuestionType.multipleChoice:
        final options = detail.optionsFor(question.id);
        final labels = parseMultipleChoiceAnswer(
          raw,
        ).map((id) => _optionLabel(options, id));
        return labels.isEmpty ? '–' : labels.join(', ');
      case PollQuestionType.singleChoice:
        return _optionLabel(detail.optionsFor(question.id), raw.toString());
      case PollQuestionType.date:
        return _parsedDate(raw) ?? raw.toString();
      case PollQuestionType.datetime:
        if (raw is String) {
          final instant = parseApiInstant(raw);
          return formatDateTimeInZone(
            instant,
            AppScope.of(context).timeZones.effective,
          );
        }
        return raw.toString();
      default:
        return raw.toString();
    }
  }

  String _optionLabel(List<PollOption> options, String id) {
    for (final option in options) {
      if (option.id == id) return option.label ?? option.displayLabel;
    }
    return id;
  }

  String? _parsedDate(Object raw) {
    if (raw is! String) return null;
    try {
      return formatDate(parseApiDateOnly(raw));
    } catch (_) {
      return null;
    }
  }
}
