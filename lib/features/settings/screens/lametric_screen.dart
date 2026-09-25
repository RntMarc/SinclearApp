import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/utils/date_utils.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../../design/widgets/primitives/design_text_field.dart';
import '../models/lametric_token_models.dart';

/// Verwaltung der LaMetric-Time-Verknüpfung: zeigt die Poll-URL für die
/// Indicator-App und erlaubt das Erzeugen, Ersetzen und Widerrufen des
/// persönlichen LaMetric-Tokens.
class LaMetricScreen extends StatefulWidget {
  const LaMetricScreen({super.key});

  @override
  State<LaMetricScreen> createState() => _LaMetricScreenState();
}

class _LaMetricScreenState extends State<LaMetricScreen> {
  LaMetricToken? _token;
  bool _loading = true;
  String? _error;
  bool _busy = false;
  bool _didLoad = false;

  String get _pollUrl =>
      '${AppScope.of(context).apiBaseUrl}/lametric/notification';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoad) {
      _didLoad = true;
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await AppScope.of(context).lametricToken.get();
      if (!mounted) return;
      setState(() {
        _token = token;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Token konnte nicht geladen werden.';
      });
    }
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Kopiert')));
  }

  Future<void> _createOrReplace() async {
    final label = await showDesignSheet<String>(
      context: context,
      child: const _LabelSheet(),
    );
    if (label == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final token = await AppScope.of(context).lametricToken.put(label: label);
      if (!mounted) return;
      setState(() {
        _token = token;
        _busy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('LaMetric-Token gespeichert')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token konnte nicht gespeichert werden.')),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final tokens = DesignTheme.of(context);
    final confirm = await showDesignSheet<bool>(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DesignText('Token widerrufen', style: DesignTextStyle.title),
            const SizedBox(height: 8),
            DesignText(
              'Das Token wird widerrufen. Die LaMetric-Uhr zeigt danach einen '
              'Fehler, bis du in der LaMetric-App ein neues Token einträgst.',
              style: DesignTextStyle.body,
              color: tokens.textHigh,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DesignButton(
                    variant: DesignButtonVariant.text,
                    label: 'Abbrechen',
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DesignButton(
                    label: 'Widerrufen',
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await AppScope.of(context).lametricToken.delete();
      if (!mounted) return;
      setState(() {
        _token = null;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token konnte nicht widerrufen werden.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    return DesignSurface(
      child: Column(
        children: [
          DesignSubpageHeader(
            leading: DesignIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => context.pop(),
            ),
            title: 'LaMetric Time',
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(vertical: tokens.spaceMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _setupCard(),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      _errorCard(),
                    ] else ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                        child: DesignText(
                          'Token',
                          style: DesignTextStyle.label,
                          color: tokens.primary,
                        ),
                      ),
                      _tokenSection(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _setupCard() {
    final tokens = DesignTheme.of(context);
    return DesignCard(
      padding: EdgeInsets.all(tokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DesignText('Einrichtung', style: DesignTextStyle.title),
          const SizedBox(height: 4),
          DesignText(
            'Verknüpfe deine LaMetric Time über eine eigene Indicator-App. '
            'Die Uhr ruft die folgende URL regelmäßig ab und zeigt die Anzahl '
            'ungelesener Benachrichtigungen – es werden keine Inhalte '
            'übertragen.',
            style: DesignTextStyle.label,
            color: tokens.textLow,
          ),
          const SizedBox(height: 12),
          const DesignText('Poll-URL', style: DesignTextStyle.label),
          const SizedBox(height: 4),
          _copyRow(_pollUrl),
          const SizedBox(height: 12),
          _step(
            '1',
            'Auf developer.lametric.com eine Indicator-App erstellen.',
          ),
          _step(
            '2',
            'Kommunikationstyp „Poll" wählen und die Poll-URL oben '
                'eintragen.',
          ),
          _step('3', 'Benutzerdefiniertes Feld mit ID „token" hinzufügen.'),
          _step('4', 'App veröffentlichen und auf der Uhr installieren.'),
          _step(
            '5',
            'In den App-Einstellungen der LaMetric-App das unten '
                'erzeugte Token als „token" eintragen.',
          ),
        ],
      ),
    );
  }

  Widget _step(String number, String text) {
    final tokens = DesignTheme.of(context);
    return Padding(
      padding: EdgeInsets.only(top: tokens.spaceSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: DesignText(
              number,
              style: DesignTextStyle.label,
              color: tokens.primary,
            ),
          ),
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

  Widget _copyRow(String value) {
    final tokens = DesignTheme.of(context);
    return Container(
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
        children: [
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: tokens.textHigh,
              ),
            ),
          ),
          SizedBox(width: tokens.spaceSm),
          DesignIconButton(
            icon: Icons.copy_rounded,
            onPressed: () => _copy(value),
          ),
        ],
      ),
    );
  }

  Widget _errorCard() {
    final tokens = DesignTheme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tokens.spaceXl),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: tokens.danger),
            const SizedBox(height: 8),
            DesignText(_error!),
            const SizedBox(height: 16),
            DesignButton(
              label: 'Erneut versuchen',
              variant: DesignButtonVariant.outlined,
              onPressed: _load,
            ),
          ],
        ),
      ),
    );
  }

  Widget _tokenSection() {
    final tokens = DesignTheme.of(context);

    if (_loading) {
      return Padding(
        padding: EdgeInsets.all(tokens.spaceXl),
        child: Center(child: CircularProgressIndicator(color: tokens.primary)),
      );
    }

    final token = _token;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (token == null)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
            child: DesignText(
              'Noch kein Token erstellt. Erzeuge eines und trage es in der '
              'LaMetric-App ein.',
              style: DesignTextStyle.body,
              color: tokens.textLow,
            ),
          )
        else
          Padding(
            padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
            child: DesignCard(
              padding: EdgeInsets.all(tokens.spaceLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DesignText(token.label, style: DesignTextStyle.title),
                  const SizedBox(height: 4),
                  DesignText(
                    'Gültig bis ${formatDate(parseApiDate(token.expiresAt))}'
                    '${token.lastUsedAt != null ? ' · Zuletzt genutzt '
                              '${formatDateTime(parseApiDate(token.lastUsedAt!))}' : ''}',
                    style: DesignTextStyle.label,
                    color: tokens.textLow,
                  ),
                  const SizedBox(height: 12),
                  const DesignText('Token', style: DesignTextStyle.label),
                  const SizedBox(height: 4),
                  _copyRow(token.token),
                ],
              ),
            ),
          ),
        SizedBox(height: tokens.spaceLg),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
          child: DesignButton(
            variant: DesignButtonVariant.filled,
            icon: token == null ? Icons.add_rounded : Icons.refresh_rounded,
            label: token == null ? 'Token erzeugen' : 'Token ersetzen',
            fullWidth: true,
            loading: _busy,
            onPressed: _busy ? null : _createOrReplace,
          ),
        ),
        if (token != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
            child: DesignButton(
              variant: DesignButtonVariant.text,
              icon: Icons.delete_rounded,
              label: 'Token widerrufen',
              fullWidth: true,
              onPressed: _busy ? null : _confirmDelete,
            ),
          ),
        ],
      ],
    );
  }
}

class _LabelSheet extends StatefulWidget {
  const _LabelSheet();

  @override
  State<_LabelSheet> createState() => _LabelSheetState();
}

class _LabelSheetState extends State<_LabelSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: DesignText(
                  'Token erzeugen',
                  style: DesignTextStyle.title,
                  color: tokens.textHigh,
                ),
              ),
              DesignIconButton(
                icon: Icons.close_rounded,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DesignText(
            'Gib eine Bezeichnung an, z.B. „Wohnzimmer".',
            style: DesignTextStyle.body,
            color: tokens.textLow,
          ),
          const SizedBox(height: 16),
          DesignTextField(
            controller: _controller,
            hint: 'Bezeichnung',
            maxLength: 100,
            prefixIcon: Icons.label_rounded,
          ),
          const SizedBox(height: 16),
          DesignButton(
            variant: DesignButtonVariant.filled,
            label: 'Speichern',
            fullWidth: true,
            onPressed: _controller.text.trim().isEmpty
                ? null
                : () => Navigator.pop(context, _controller.text.trim()),
          ),
        ],
      ),
    );
  }
}
