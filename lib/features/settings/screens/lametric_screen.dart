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
import '../models/lametric_token_models.dart';

/// Verwaltung des persönlichen LaMetric-Tokens: anzeigbar, ersetzbar und
/// widerrufbar. Alle LaMetric-Apps und Uhren teilen sich dieses eine Token.
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
    setState(() => _busy = true);
    try {
      final token = await AppScope.of(context).lametricToken.put();
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
                child: _error != null
                    ? _errorCard()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                      ),
              ),
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
      padding: EdgeInsets.all(tokens.spaceXl),
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
