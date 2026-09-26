import 'package:flutter/material.dart';

import '../../../design/widgets/composite/design_question_field.dart';
import '../models/poll_models.dart';

/// Bildet einen API-Fragetyp auf den model-freien [DesignQuestionKind] ab.
DesignQuestionKind designKindFor(PollQuestionType type) => switch (type) {
  PollQuestionType.text => DesignQuestionKind.text,
  PollQuestionType.textarea => DesignQuestionKind.textarea,
  PollQuestionType.number => DesignQuestionKind.number,
  PollQuestionType.email => DesignQuestionKind.email,
  PollQuestionType.coordinates => DesignQuestionKind.coordinates,
  PollQuestionType.date => DesignQuestionKind.date,
  PollQuestionType.datetime => DesignQuestionKind.datetime,
  PollQuestionType.url => DesignQuestionKind.url,
  PollQuestionType.phone => DesignQuestionKind.phone,
  PollQuestionType.singleChoice => DesignQuestionKind.singleChoice,
  PollQuestionType.multipleChoice => DesignQuestionKind.multipleChoice,
  PollQuestionType.boolean => DesignQuestionKind.boolean,
  PollQuestionType.rating => DesignQuestionKind.rating,
};

/// Baut die model-freie Spezifikation aus Frage und ihren Optionen.
DesignQuestionSpec designSpecFor(
  PollQuestion question,
  List<PollOption> options,
) {
  return DesignQuestionSpec(
    kind: designKindFor(question.type),
    title: question.title,
    description: question.description,
    isRequired: question.isRequired,
    config: question.config,
    options: options
        .map(
          (option) => DesignQuestionOption(
            value: option.id,
            label: option.label ?? option.displayLabel,
          ),
        )
        .toList(),
  );
}

/// Dünner Feature-Adapter: [PollQuestion] → [DesignQuestionField].
class QuestionField extends StatelessWidget {
  const QuestionField({
    required this.question,
    required this.options,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final PollQuestion question;
  final List<PollOption> options;
  final Object? value;
  final ValueChanged<Object?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DesignQuestionField(
      spec: designSpecFor(question, options),
      value: value,
      onChanged: onChanged,
      enabled: enabled,
    );
  }
}
