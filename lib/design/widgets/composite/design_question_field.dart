import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../theme/design_theme.dart';
import '../foundation/design_text.dart';
import '../primitives/design_chip.dart';
import '../primitives/design_slider.dart';
import '../primitives/design_text_field.dart';
import '../primitives/press_scale.dart';

/// Fragetyp eines [DesignQuestionField] — model-freies Spiegelbild der 13
/// API-Fragetypen.
enum DesignQuestionKind {
  text('Text'),
  textarea('Mehrzeiliger Text'),
  number('Zahl'),
  email('E-Mail'),
  coordinates('Koordinaten'),
  date('Datum'),
  datetime('Datum & Uhrzeit'),
  url('URL'),
  phone('Telefon'),
  singleChoice('Einfachauswahl'),
  multipleChoice('Mehrfachauswahl'),
  boolean('Ja/Nein'),
  rating('Bewertung');

  const DesignQuestionKind(this.label);

  final String label;
}

/// Eine Auswahloption (Wert + Anzeigelabel) für Auswahl-Fragetypen.
class DesignQuestionOption {
  const DesignQuestionOption({required this.value, required this.label});

  final String value;
  final String label;
}

/// Model-freie Beschreibung einer Frage inkl. typspezifischer `config`.
///
/// Die Feature-Ebene mappt `PollQuestion` auf diese Spec; Anzeige (Teilnahme)
/// und Editor (Autoren) nutzen dieselbe Spezifikation.
class DesignQuestionSpec {
  const DesignQuestionSpec({
    required this.kind,
    required this.title,
    this.description,
    this.isRequired = false,
    this.config = const {},
    this.options = const [],
  });

  final DesignQuestionKind kind;
  final String title;
  final String? description;
  final bool isRequired;
  final Map<String, dynamic> config;
  final List<DesignQuestionOption> options;

  int? intConfig(String key) {
    final value = config[key];
    return value is num ? value.toInt() : null;
  }

  double? doubleConfig(String key) {
    final value = config[key];
    return value is num ? value.toDouble() : null;
  }

  bool boolConfig(String key, {bool fallback = false}) {
    final value = config[key];
    return value is bool ? value : fallback;
  }

  List<String> labelsConfig() {
    final value = config['labels'];
    if (value is! List) return const [];
    return value.map((e) => e.toString()).toList();
  }
}

/// Rendert genau einen der 13 Fragetypen aus einer [DesignQuestionSpec].
///
/// `value`/`onChanged` verwenden UI-Werte: Text-artige Typen `String`,
/// `number`/`rating` `num`, `boolean` `bool`, Auswahl `String` bzw.
/// `List<String>`, `coordinates` `"lat,lon"`, `date`/`datetime` eine zivile
/// Wandzeit ([DateTime]).
class DesignQuestionField extends StatefulWidget {
  const DesignQuestionField({
    required this.spec,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final DesignQuestionSpec spec;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  /// Sperrt die Eingabe (z. B. geschlossene Umfrage oder bereits abgestimmt).
  final bool enabled;

  @override
  State<DesignQuestionField> createState() => _DesignQuestionFieldState();
}

class _DesignQuestionFieldState extends State<DesignQuestionField> {
  late final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  bool _otherActive = false;

  DesignQuestionSpec get _spec => widget.spec;

  @override
  void initState() {
    super.initState();
    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant DesignQuestionField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value || oldWidget.spec != widget.spec) {
      _syncControllers();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  TextEditingController _controller(String key, String initial) {
    final existing = _controllers[key];
    if (existing != null) return existing;
    final controller = TextEditingController(text: initial);
    _controllers[key] = controller;
    return controller;
  }

  FocusNode _focusNode(String key) =>
      _focusNodes.putIfAbsent(key, FocusNode.new);

  void _syncControllers() {
    final value = widget.value;
    switch (_spec.kind) {
      case DesignQuestionKind.coordinates:
        final parts = _parseCoordinates(value);
        _setController('lat', parts?.latitude.toString() ?? '');
        _setController('lon', parts?.longitude.toString() ?? '');
      case DesignQuestionKind.boolean ||
          DesignQuestionKind.date ||
          DesignQuestionKind.datetime ||
          DesignQuestionKind.singleChoice ||
          DesignQuestionKind.multipleChoice ||
          DesignQuestionKind.rating:
        break;
      default:
        _setController('text', value?.toString() ?? '');
    }
  }

  void _setController(String key, String text) {
    final controller = _controller(key, '');
    if (controller.text != text) controller.text = text;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DesignText(
          _spec.isRequired ? '${_spec.title} *' : _spec.title,
          style: DesignTextStyle.label,
          color: tokens.textHigh,
        ),
        if (_spec.description != null && _spec.description!.isNotEmpty) ...[
          SizedBox(height: tokens.spaceXs),
          DesignText(
            _spec.description!,
            style: DesignTextStyle.body,
            color: tokens.textLow,
          ),
        ],
        SizedBox(height: tokens.spaceSm),
        _buildInput(tokens),
      ],
    );
  }

  Widget _buildInput(DesignTokens tokens) {
    switch (_spec.kind) {
      case DesignQuestionKind.textarea:
        return DesignTextField(
          hint: 'Antwort',
          controller: _controller('text', ''),
          focusNode: _focusNode('text'),
          maxLines: 5,
          maxLength: _spec.intConfig('maxLength'),
          onChanged: widget.enabled ? widget.onChanged : null,
        );
      case DesignQuestionKind.text:
        return DesignTextField(
          hint: 'Antwort',
          controller: _controller('text', ''),
          focusNode: _focusNode('text'),
          maxLength: _spec.intConfig('maxLength'),
          onChanged: widget.enabled ? widget.onChanged : null,
        );
      case DesignQuestionKind.number:
        return DesignTextField(
          hint: 'Zahl',
          controller: _controller('text', ''),
          focusNode: _focusNode('text'),
          keyboardType: TextInputType.numberWithOptions(
            decimal: !_spec.boolConfig('integerOnly'),
          ),
          onChanged: widget.enabled ? _onNumberChanged : null,
        );
      case DesignQuestionKind.email:
        return DesignTextField(
          hint: 'name@beispiel.de',
          controller: _controller('text', ''),
          focusNode: _focusNode('text'),
          keyboardType: TextInputType.emailAddress,
          onChanged: widget.enabled ? widget.onChanged : null,
        );
      case DesignQuestionKind.url:
        return DesignTextField(
          hint: 'https://…',
          controller: _controller('text', ''),
          focusNode: _focusNode('text'),
          keyboardType: TextInputType.url,
          onChanged: widget.enabled ? widget.onChanged : null,
        );
      case DesignQuestionKind.phone:
        return DesignTextField(
          hint: '+49 …',
          controller: _controller('text', ''),
          focusNode: _focusNode('text'),
          keyboardType: TextInputType.phone,
          onChanged: widget.enabled ? widget.onChanged : null,
        );
      case DesignQuestionKind.coordinates:
        return _buildCoordinates(tokens);
      case DesignQuestionKind.date:
        return _DateTrigger(
          label: 'Datum wählen',
          value: widget.value is DateTime ? widget.value as DateTime : null,
          dateOnly: true,
          onTap: widget.enabled ? () => _pickDateTime(dateOnly: true) : null,
        );
      case DesignQuestionKind.datetime:
        return _DateTrigger(
          label: 'Datum & Uhrzeit wählen',
          value: widget.value is DateTime ? widget.value as DateTime : null,
          dateOnly: false,
          onTap: widget.enabled ? () => _pickDateTime(dateOnly: false) : null,
        );
      case DesignQuestionKind.singleChoice:
        return _buildSingleChoice(tokens);
      case DesignQuestionKind.multipleChoice:
        return _buildMultipleChoice(tokens);
      case DesignQuestionKind.boolean:
        return _buildBoolean(tokens);
      case DesignQuestionKind.rating:
        return _buildRating(tokens);
    }
  }

  Widget _buildCoordinates(DesignTokens tokens) {
    return Column(
      children: <Widget>[
        DesignTextField(
          hint: 'Breitengrad',
          controller: _controller('lat', ''),
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          onChanged: widget.enabled ? (_) => _emitCoordinates() : null,
        ),
        SizedBox(height: tokens.spaceSm),
        DesignTextField(
          hint: 'Längengrad',
          controller: _controller('lon', ''),
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          onChanged: widget.enabled ? (_) => _emitCoordinates() : null,
        ),
      ],
    );
  }

  void _onNumberChanged(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      widget.onChanged(null);
      return;
    }
    if (_spec.boolConfig('integerOnly')) {
      widget.onChanged(int.tryParse(trimmed));
    } else {
      widget.onChanged(num.tryParse(trimmed));
    }
  }

  void _emitCoordinates() {
    final lat = _controllers['lat']?.text.trim() ?? '';
    final lon = _controllers['lon']?.text.trim() ?? '';
    if (lat.isEmpty && lon.isEmpty) {
      widget.onChanged(null);
    } else {
      widget.onChanged('$lat,$lon');
    }
  }

  Widget _buildSingleChoice(DesignTokens tokens) {
    final selected = widget.value is String ? widget.value as String : null;
    final isOption = _spec.options.any((o) => o.value == selected);
    final allowOther = _spec.boolConfig('allowOther');
    final otherSelected = allowOther && !isOption && selected != null;
    if (otherSelected && !_otherActive) _otherActive = true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: tokens.spaceSm,
          runSpacing: tokens.spaceSm,
          children: <Widget>[
            for (final option in _spec.options)
              DesignChip(
                label: option.label,
                selected: selected == option.value,
                onTap: widget.enabled
                    ? () {
                        _otherActive = false;
                        widget.onChanged(option.value);
                      }
                    : null,
              ),
            if (allowOther)
              DesignChip(
                label: 'Sonstiges',
                selected: _otherActive,
                onTap: widget.enabled
                    ? () {
                        setState(() => _otherActive = true);
                        widget.onChanged('');
                      }
                    : null,
              ),
          ],
        ),
        if (allowOther && _otherActive) ...<Widget>[
          SizedBox(height: tokens.spaceSm),
          DesignTextField(
            hint: 'Sonstige Antwort',
            controller: _controller('other', selected ?? ''),
            onChanged: widget.enabled ? widget.onChanged : null,
          ),
        ],
      ],
    );
  }

  Widget _buildMultipleChoice(DesignTokens tokens) {
    final selected = _parseMultipleChoice(widget.value);
    final max = _spec.intConfig('maxSelected');
    final min = _spec.intConfig('minSelected');

    void toggle(String value) {
      final next = List<String>.from(selected);
      if (next.contains(value)) {
        next.remove(value);
      } else {
        if (max != null && next.length >= max) return;
        next.add(value);
      }
      widget.onChanged(next);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: tokens.spaceSm,
          runSpacing: tokens.spaceSm,
          children: <Widget>[
            for (final option in _spec.options)
              DesignChip(
                label: option.label,
                selected: selected.contains(option.value),
                onTap: widget.enabled ? () => toggle(option.value) : null,
              ),
          ],
        ),
        if (min != null || max != null) ...<Widget>[
          SizedBox(height: tokens.spaceXs),
          DesignText(
            [
              if (min != null) 'mind. $min',
              if (max != null) 'höchstens $max',
            ].join(' · '),
            style: DesignTextStyle.label,
            color: tokens.textLow,
          ),
        ],
      ],
    );
  }

  Widget _buildBoolean(DesignTokens tokens) {
    final value = widget.value is bool ? widget.value as bool : null;
    return Wrap(
      spacing: tokens.spaceSm,
      children: <Widget>[
        DesignChip(
          label: 'Ja',
          selected: value == true,
          onTap: widget.enabled ? () => widget.onChanged(true) : null,
        ),
        DesignChip(
          label: 'Nein',
          selected: value == false,
          onTap: widget.enabled ? () => widget.onChanged(false) : null,
        ),
      ],
    );
  }

  Widget _buildRating(DesignTokens tokens) {
    final min = _spec.doubleConfig('min') ?? 1;
    final max = _spec.doubleConfig('max') ?? 5;
    final step = _spec.doubleConfig('step') ?? 1;
    final labels = _spec.labelsConfig();
    final value = widget.value is num ? (widget.value as num).toDouble() : min;
    final stepped = ((value - min) / step).round() * step + min;

    String valueText = stepped.toStringAsFixed(step < 1 ? 1 : 0);
    final at = stepped.round() - min.round();
    if (at >= 0 && at < labels.length) valueText = labels[at];

    return DesignSlider(
      label: _spec.title,
      value: value.clamp(min, max),
      min: min,
      max: max,
      valueText: valueText,
      onChanged: widget.enabled
          ? (raw) {
              final rounded = ((raw - min) / step).round() * step + min;
              widget.onChanged(rounded);
            }
          : (_) {},
    );
  }

  Future<void> _pickDateTime({required bool dateOnly}) async {
    final current = widget.value is DateTime
        ? widget.value as DateTime
        : DateTime.now();
    final minDate = _spec.config['minDate'] is String
        ? _parseIsoDate(_spec.config['minDate'] as String)
        : null;
    final maxDate = _spec.config['maxDate'] is String
        ? _parseIsoDate(_spec.config['maxDate'] as String)
        : null;

    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: minDate ?? DateTime(1900),
      lastDate: maxDate ?? DateTime(2100),
    );
    if (date == null || !mounted) return;
    if (dateOnly) {
      widget.onChanged(date);
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null) return;
    widget.onChanged(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }

  static DateTime? _parseIsoDate(String value) {
    try {
      return DateTime.parse(value);
    } on FormatException {
      return null;
    }
  }
}

/// Parst einen `multiple_choice`-Wert (Liste oder JSON-Array-String).
List<String> _parseMultipleChoice(Object? value) {
  if (value == null) return const [];
  if (value is List) return value.map((e) => e.toString()).toList();
  final text = value.toString().trim();
  if (text.isEmpty) return const [];
  if (text.startsWith('[') && text.endsWith(']')) {
    final stripped = text.substring(1, text.length - 1).trim();
    if (stripped.isEmpty) return const [];
    return stripped
        .split(',')
        .map((part) => part.trim().replaceAll('"', '').replaceAll("'", ''))
        .where((part) => part.isNotEmpty)
        .toList();
  }
  return [text];
}

/// Parst `"lat,lon"` zu einem Record oder `null`.
({double latitude, double longitude})? _parseCoordinates(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  final parts = text.split(',');
  if (parts.length != 2) return null;
  final lat = double.tryParse(parts[0].trim());
  final lon = double.tryParse(parts[1].trim());
  if (lat == null || lon == null) return null;
  return (latitude: lat, longitude: lon);
}

/// Read-only-Auswahlfeld für Datum/Uhrzeit im [DesignTextField]-Look.
class _DateTrigger extends StatelessWidget {
  const _DateTrigger({
    required this.label,
    required this.value,
    required this.dateOnly,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final bool dateOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final text = value == null
        ? label
        : dateOnly
        ? DateFormat('dd.MM.yyyy').format(value!)
        : DateFormat('dd.MM.yyyy HH:mm').format(value!);
    return PressScale(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceMd,
          vertical: tokens.spaceSm,
        ),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          border: Border.all(
            color: tokens.border.withValues(alpha: 0.8),
            width: 1.5,
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(Icons.event_rounded, size: 20, color: tokens.textLow),
            SizedBox(width: tokens.spaceSm),
            Expanded(
              child: DesignText(
                text,
                style: DesignTextStyle.body,
                color: value == null ? tokens.textLow : tokens.textHigh,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
