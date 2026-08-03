import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/utils/date_utils.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/composite/design_list_tile.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../../design/widgets/primitives/design_text_field.dart';
import '../models/mcp_key_models.dart';

/// Verwaltung der MCP-API-Keys: zeigt die MCP-Endpunkt-URL und erlaubt das
/// Erstellen und Löschen von Keys für die Nutzung des MCP-Servers.
class McpKeysScreen extends StatefulWidget {
  const McpKeysScreen({super.key});

  @override
  State<McpKeysScreen> createState() => _McpKeysScreenState();
}

class _McpKeysScreenState extends State<McpKeysScreen> {
  List<McpApiKey>? _keys;
  bool _loading = true;
  String? _error;
  bool _creating = false;
  bool _didLoad = false;

  String get _mcpUrl => '${AppScope.of(context).apiBaseUrl}/mcp';

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
      final keys = await AppScope.of(context).mcpKeys.list();
      if (!mounted) return;
      setState(() {
        _keys = keys;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'API-Keys konnten nicht geladen werden.';
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

  Future<void> _createKey() async {
    final label = await showDesignSheet<String>(
      context: context,
      child: const _LabelSheet(),
    );
    if (label == null || !mounted) return;

    setState(() => _creating = true);
    try {
      final created = await AppScope.of(context).mcpKeys.create(label);
      if (!mounted) return;
      setState(() => _creating = false);
      await _showCreatedKey(created);
      if (!mounted) return;
      _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _creating = false);
      final message = e.toString().contains('409')
          ? 'Maximale Anzahl an Keys erreicht (3).'
          : 'Key konnte nicht erstellt werden.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _showCreatedKey(McpApiKeyCreateResult created) async {
    final tokens = DesignTheme.of(context);
    await showDesignSheet<void>(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DesignText('API-Key erstellt', style: DesignTextStyle.title),
            const SizedBox(height: 8),
            DesignText(
              'Der Key wird aus Sicherheitsgründen nur einmal angezeigt. '
              'Kopiere ihn jetzt – später ist er nicht mehr abrufbar.',
              style: DesignTextStyle.body,
              color: tokens.textLow,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tokens.surface,
                borderRadius: BorderRadius.circular(tokens.radiusMd),
                border: Border.all(
                  color: tokens.border.withValues(alpha: 0.8),
                  width: 1.5,
                ),
              ),
              child: SelectableText(
                created.key,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: tokens.textHigh,
                ),
              ),
            ),
            const SizedBox(height: 16),
            DesignButton(
              variant: DesignButtonVariant.filled,
              icon: Icons.copy_rounded,
              label: 'Key kopieren',
              fullWidth: true,
              onPressed: () => _copy(created.key),
            ),
            const SizedBox(height: 8),
            DesignButton(
              variant: DesignButtonVariant.text,
              label: 'Schließen',
              fullWidth: true,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(McpApiKey key) async {
    final tokens = DesignTheme.of(context);
    final confirm = await showDesignSheet<bool>(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DesignText('Key löschen', style: DesignTextStyle.title),
            const SizedBox(height: 8),
            DesignText(
              '„${key.label}" wird gelöscht und kann danach nicht mehr '
              'verwendet werden.',
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
                    label: 'Löschen',
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

    try {
      await AppScope.of(context).mcpKeys.delete(key.id);
      if (!mounted) return;
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Key konnte nicht gelöscht werden.')),
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
            title: 'MCP-API-Keys',
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(vertical: tokens.spaceMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _endpointCard(),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: DesignText(
                        'Keys',
                        style: DesignTextStyle.label,
                        color: tokens.primary,
                      ),
                    ),
                    _keyList(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _endpointCard() {
    final tokens = DesignTheme.of(context);
    return DesignCard(
      padding: EdgeInsets.all(tokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DesignText('MCP-Endpunkt', style: DesignTextStyle.title),
          const SizedBox(height: 4),
          DesignText(
            'Diese URL wird in OpenCode oder anderen MCP-Clients als '
            'Remote-Server konfiguriert. Ohne API-Key ist die Dokumentation '
            'lesbar; mit Key zusätzlich das Tool „create_recipe_draft".',
            style: DesignTextStyle.label,
            color: tokens.textLow,
          ),
          const SizedBox(height: 12),
          Container(
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
                    _mcpUrl,
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
                  onPressed: () => _copy(_mcpUrl),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          DesignText(
            'Keys sind 90 Tage gültig, maximal 3 gleichzeitig. Der vollständige '
            'Key wird nur bei der Erstellung angezeigt.',
            style: DesignTextStyle.label,
            color: tokens.textLow,
          ),
        ],
      ),
    );
  }

  Widget _keyList() {
    final tokens = DesignTheme.of(context);

    if (_loading) {
      return Padding(
        padding: EdgeInsets.all(tokens.spaceXl),
        child: Center(child: CircularProgressIndicator(color: tokens.primary)),
      );
    }
    if (_error != null) {
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

    final keys = _keys ?? <McpApiKey>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (keys.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spaceLg,
              vertical: tokens.spaceMd,
            ),
            child: DesignText(
              'Noch keine Keys erstellt.',
              style: DesignTextStyle.body,
              color: tokens.textLow,
            ),
          )
        else
          DesignCard.list(
            children: [
              for (final key in keys)
                DesignListTile(
                  leading: const Icon(Icons.key_rounded),
                  title: key.label,
                  subtitle:
                      'Gültig bis ${formatDate(parseApiDate(key.expiresAt))}',
                  trailing: DesignIconButton(
                    icon: Icons.delete_rounded,
                    onPressed: () => _confirmDelete(key),
                  ),
                ),
            ],
          ),
        SizedBox(height: tokens.spaceLg),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
          child: DesignButton(
            variant: DesignButtonVariant.filled,
            icon: Icons.add_rounded,
            label: 'Neuen Key erstellen',
            fullWidth: true,
            loading: _creating,
            onPressed: _creating ? null : _createKey,
          ),
        ),
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
                  'Neuen Key erstellen',
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
            'Gib eine Bezeichnung an, z.B. „OpenCode".',
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
            label: 'Erstellen',
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
