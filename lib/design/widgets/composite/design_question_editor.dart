import 'package:flutter/material.dart';

import '../../theme/design_theme.dart';
import '../foundation/design_text.dart';
import '../primitives/design_button.dart';
import '../primitives/design_chip.dart';
import '../primitives/design_icon_button.dart';
import '../primitives/design_text_field.dart';
import 'design_picker_field.dart';
import 'design_question_field.dart';

/// Autoren-Entwurf einer Frage. Wird vom [DesignQuestionEditor] bearbeitet
/// und über `onChanged` als neue Instanz gemeldet.
class DesignQuestionDraft {
  const DesignQuestionDraft({
    required this.kind,
    this.title = '',
    this.description = '',
    this.isRequired = false,
    this.config = const {},
    this.optionLabels = const [],
  });

  final DesignQuestionKind kind;
  final String title;
  final String description;
  final bool isRequired;
  final Map<String, dynamic> config;
  final List<String> optionLabels;

  DesignQuestionDraft copyWith({
    DesignQuestionKind? kind,
    String? title,
    String? description,
    bool? isRequired,
    Map<String, dynamic>? config,
    List<String>? optionLabels,
  }) {
    return DesignQuestionDraft(
      kind: kind ?? this.kind,
      title: title ?? this.title,
      description: description ?? this.description,
      isRequired: isRequired ?? this.isRequired,
      config: config ?? this.config,
      optionLabels: optionLabels ?? this.optionLabels,
    );
  }
}

/// Autoren-Pendant zu [DesignQuestionField]: bearbeitet Titel, Pflicht,
/// typspezifische `config` und die Optionsliste einer Frage.
class DesignQuestionEditor extends StatefulWidget {
  const DesignQuestionEditor({
    required this.draft,
    required this.onChanged,
    this.onRemove,
    this.timezoneOptions = const [],
    super.key,
  });

  final DesignQuestionDraft draft;
  final ValueChanged<DesignQuestionDraft> onChanged;
  final VoidCallback? onRemove;

  /// IANA-Zeitzonen für `datetime`-Konfiguration (leer = kein Feld).
  final List<String> timezoneOptions;

  @override
  State<DesignQuestionEditor> createState() => _DesignQuestionEditorState();
}

class _DesignQuestionEditorState extends State<DesignQuestionEditor> {
  late DesignQuestionKind _kind;
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _labels;

  final Map<String, TextEditingController> _configControllers = {};
  final List<TextEditingController> _optionControllers = [];

  @override
  void initState() {
    super.initState();
    _kind = widget.draft.kind;
    _title = TextEditingController(text: widget.draft.title);
    _description = TextEditingController(text: widget.draft.description);
    _labels = TextEditingController(
      text: widget.draft.config['labels'] is List
          ? (widget.draft.config['labels'] as List).join(', ')
          : '',
    );
    _resetOptionControllers(widget.draft.optionLabels);
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _labels.dispose();
    for (final controller in _configControllers.values) {
      controller.dispose();
    }
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _resetOptionControllers(List<String> labels) {
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    _optionControllers
      ..clear()
      ..addAll(labels.map((label) => TextEditingController(text: label)));
  }

  TextEditingController _configController(String key) {
    return _configControllers.putIfAbsent(key, () {
      final value = widget.draft.config[key];
      return TextEditingController(text: value?.toString() ?? '');
    });
  }

  void _emit() {
    widget.onChanged(
      DesignQuestionDraft(
        kind: _kind,
        title: _title.text.trim(),
        description: _description.text.trim(),
        isRequired: widget.draft.isRequired,
        config: _buildConfig(),
        optionLabels: _optionControllers
            .map((c) => c.text.trim())
            .where((l) => l.isNotEmpty)
            .toList(),
      ),
    );
  }

  Map<String, dynamic> _buildConfig() {
    final config = <String, dynamic>{};
    void number(String key) {
      final text = _configController(key).text.trim();
      if (text.isEmpty) return;
      final value = int.tryParse(text) ?? double.tryParse(text);
      if (value != null) config[key] = value;
    }

    switch (_kind) {
      case DesignQuestionKind.text || DesignQuestionKind.textarea:
        number('minLength');
        number('maxLength');
      case DesignQuestionKind.number:
        number('min');
        number('max');
        if (widget.draft.config['integerOnly'] == true) {
          config['integerOnly'] = true;
        }
      case DesignQuestionKind.rating:
        number('min');
        number('max');
        number('step');
        final labels = _labels.text
            .split(',')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList();
        if (labels.isNotEmpty) config['labels'] = labels;
      case DesignQuestionKind.singleChoice:
        if (widget.draft.config['allowOther'] == true) {
          config['allowOther'] = true;
        }
      case DesignQuestionKind.multipleChoice:
        number('minSelected');
        number('maxSelected');
      case DesignQuestionKind.datetime:
        if (widget.draft.config['timezone'] is String) {
          config['timezone'] = widget.draft.config['timezone'];
        }
      default:
        break;
    }
    return config;
  }

  void _setConfigFlag(String key, bool value) {
    final config = Map<String, dynamic>.from(widget.draft.config);
    if (value) {
      config[key] = true;
    } else {
      config.remove(key);
    }
    widget.onChanged(widget.draft.copyWith(config: config));
  }

  void _addOption() {
    setState(() => _optionControllers.add(TextEditingController()));
    _emit();
  }

  void _removeOption(int index) {
    setState(() {
      _optionControllers.removeAt(index).dispose();
    });
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: DesignPickerField(
                hint: 'Fragetyp',
                value: _kind.name,
                prefixIcon: Icons.category_rounded,
                items: DesignQuestionKind.values
                    .map(
                      (kind) =>
                          DesignPickerItem(value: kind.name, label: kind.label),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _kind = DesignQuestionKind.values.firstWhere(
                      (k) => k.name == value,
                    );
                  });
                  _emit();
                },
              ),
            ),
            if (widget.onRemove != null) ...<Widget>[
              SizedBox(width: tokens.spaceSm),
              DesignIconButton(
                icon: Icons.delete_outline_rounded,
                onPressed: widget.onRemove,
              ),
            ],
          ],
        ),
        SizedBox(height: tokens.spaceSm),
        DesignTextField(
          hint: 'Frage',
          controller: _title,
          onChanged: (_) => _emit(),
        ),
        SizedBox(height: tokens.spaceSm),
        DesignTextField(
          hint: 'Beschreibung (optional)',
          controller: _description,
          onChanged: (_) => _emit(),
        ),
        SizedBox(height: tokens.spaceSm),
        Wrap(
          spacing: tokens.spaceSm,
          children: <Widget>[
            DesignChip(
              label: 'Pflicht',
              selected: widget.draft.isRequired,
              onTap: () => widget.onChanged(
                widget.draft.copyWith(isRequired: !widget.draft.isRequired),
              ),
            ),
            if (_kind == DesignQuestionKind.number)
              DesignChip(
                label: 'Nur ganze Zahlen',
                selected: widget.draft.config['integerOnly'] == true,
                onTap: () => _setConfigFlag(
                  'integerOnly',
                  widget.draft.config['integerOnly'] != true,
                ),
              ),
            if (_kind == DesignQuestionKind.singleChoice)
              DesignChip(
                label: 'Sonstiges erlauben',
                selected: widget.draft.config['allowOther'] == true,
                onTap: () => _setConfigFlag(
                  'allowOther',
                  widget.draft.config['allowOther'] != true,
                ),
              ),
          ],
        ),
        ..._buildConfigFields(tokens),
        if (_kind == DesignQuestionKind.singleChoice ||
            _kind == DesignQuestionKind.multipleChoice) ...<Widget>[
          SizedBox(height: tokens.spaceMd),
          DesignText(
            'Optionen',
            style: DesignTextStyle.label,
            color: tokens.textHigh,
          ),
          SizedBox(height: tokens.spaceSm),
          ..._optionControllers.asMap().entries.map(
            (entry) => Padding(
              padding: EdgeInsets.only(bottom: tokens.spaceSm),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: DesignTextField(
                      hint: 'Option ${entry.key + 1}',
                      controller: entry.value,
                      onChanged: (_) => _emit(),
                    ),
                  ),
                  SizedBox(width: tokens.spaceSm),
                  DesignIconButton(
                    icon: Icons.remove_circle_outline_rounded,
                    onPressed: () => _removeOption(entry.key),
                  ),
                ],
              ),
            ),
          ),
          DesignButton(
            label: 'Option hinzufügen',
            icon: Icons.add_rounded,
            variant: DesignButtonVariant.ghost,
            onPressed: _addOption,
          ),
        ],
      ],
    );
  }

  List<Widget> _buildConfigFields(DesignTokens tokens) {
    final fields = <Widget>[];
    void addNumber(String key, String label) {
      fields.add(
        Padding(
          padding: EdgeInsets.only(top: tokens.spaceSm),
          child: DesignTextField(
            hint: label,
            controller: _configController(key),
            keyboardType: TextInputType.number,
            onChanged: (_) => _emit(),
          ),
        ),
      );
    }

    switch (_kind) {
      case DesignQuestionKind.text || DesignQuestionKind.textarea:
        addNumber('minLength', 'Min. Länge');
        addNumber('maxLength', 'Max. Länge');
      case DesignQuestionKind.number:
        addNumber('min', 'Minimum');
        addNumber('max', 'Maximum');
      case DesignQuestionKind.rating:
        addNumber('min', 'Minimum (Standard 1)');
        addNumber('max', 'Maximum (Standard 5)');
        addNumber('step', 'Schrittweite (Standard 1)');
        fields.add(
          Padding(
            padding: EdgeInsets.only(top: tokens.spaceSm),
            child: DesignTextField(
              hint: 'Labels (kommagetrennt, optional)',
              controller: _labels,
              onChanged: (_) => _emit(),
            ),
          ),
        );
      case DesignQuestionKind.multipleChoice:
        addNumber('minSelected', 'Min. Auswahl');
        addNumber('maxSelected', 'Max. Auswahl');
      case DesignQuestionKind.datetime:
        if (widget.timezoneOptions.isNotEmpty) {
          fields.add(
            Padding(
              padding: EdgeInsets.only(top: tokens.spaceSm),
              child: DesignPickerField(
                hint: 'Zeitzone (optional)',
                value: widget.draft.config['timezone'] as String?,
                prefixIcon: Icons.public_rounded,
                items: widget.timezoneOptions
                    .map((tz) => DesignPickerItem(value: tz, label: tz))
                    .toList(),
                onChanged: (value) {
                  final config = Map<String, dynamic>.from(widget.draft.config);
                  config['timezone'] = value;
                  widget.onChanged(widget.draft.copyWith(config: config));
                },
              ),
            ),
          );
        }
      default:
        break;
    }
    return fields;
  }
}
