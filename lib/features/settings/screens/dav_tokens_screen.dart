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
import '../models/dav_token_models.dart';
import '../services/dav_sync_service.dart';

/// Verwaltung der DAV-Tokens: zeigt die DAV-Zugangsdaten (Basis-URL,
/// Benutzername, Passwort) und erlaubt das Erstellen und Widerrufen von
/// Tokens für die CalDAV-/CardDAV-Synchronisation.
class DavTokensScreen extends StatefulWidget {
  const DavTokensScreen({super.key});

  @override
  State<DavTokensScreen> createState() => _DavTokensScreenState();
}

class _DavTokensScreenState extends State<DavTokensScreen> {
  List<DavToken>? _tokens;
  String? _email;
  bool _loading = true;
  String? _error;
  bool _creating = false;
  bool _didLoad = false;
  bool _nativeSyncEnabled = false;
  bool _nativeSyncBusy = false;
  String? _nativeSyncStatus;
  List<String> _enabledSegments = [];

  String get _davUrl =>
      '${AppScope.of(context).apiBaseUrl.replaceFirst('/api/v2', '/api/dav')}/';

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
      final scope = AppScope.of(context);
      final tokens = await scope.davTokens.list();
      final user = await scope.user.getMe();
      final nativeEnabled = await scope.davSync.isEnabled();
      final nativeStatus = nativeEnabled
          ? await scope.davSync.lastSyncStatus()
          : null;
      final segments = await scope.davSync.enabledSegments();
      if (!mounted) return;
      setState(() {
        _tokens = tokens;
        _email = user.base.email;
        _nativeSyncEnabled = nativeEnabled;
        _nativeSyncStatus = nativeStatus;
        _enabledSegments = segments;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Tokens konnten nicht geladen werden.';
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

  Future<void> _createToken() async {
    final label = await showDesignSheet<String>(
      context: context,
      child: const _LabelSheet(),
    );
    if (label == null || !mounted) return;

    setState(() => _creating = true);
    try {
      final created = await AppScope.of(context).davTokens.create(label);
      if (!mounted) return;
      setState(() => _creating = false);
      await _showCreatedToken(created);
      if (!mounted) return;
      _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _creating = false);
      final message = e.toString().contains('409')
          ? 'Maximale Anzahl an Tokens erreicht (5).'
          : 'Token konnte nicht erstellt werden.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _showCreatedToken(DavTokenCreateResult created) async {
    final tokens = DesignTheme.of(context);
    await showDesignSheet<void>(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DesignText('Token erstellt', style: DesignTextStyle.title),
            const SizedBox(height: 8),
            DesignText(
              'Das Token wird aus Sicherheitsgründen nur einmal angezeigt. '
              'Kopiere es jetzt – später ist es nicht mehr abrufbar.',
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
                created.token,
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
              label: 'Token kopieren',
              fullWidth: true,
              onPressed: () => _copy(created.token),
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

  Future<void> _confirmDelete(DavToken token) async {
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
              '„${token.label}" wird widerrufen und kann danach nicht mehr '
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

    try {
      await AppScope.of(context).davTokens.delete(token.id);
      if (!mounted) return;
      _load();
    } catch (e) {
      if (!mounted) return;
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
            title: 'DAV-Tokens',
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
                    if (AppScope.of(context).davSync.isSupported) ...[
                      const SizedBox(height: 16),
                      _nativeSyncCard(),
                    ],
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: DesignText(
                        'Tokens',
                        style: DesignTextStyle.label,
                        color: tokens.primary,
                      ),
                    ),
                    _tokenList(),
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
            'Mit diesen Zugangsdaten kannst du den Beyond Kalender und die '
            'Beyond Kontakte in DAV-Clients wie DAVx5, Apple Kalender oder '
            'Thunderbird synchronisieren (nur lesend).',
            style: DesignTextStyle.label,
            color: tokens.textLow,
          ),
          const SizedBox(height: 12),
          const DesignText('Basis-URL', style: DesignTextStyle.label),
          const SizedBox(height: 4),
          _copyRow(_davUrl),
          const SizedBox(height: 12),
          const DesignText('Benutzername', style: DesignTextStyle.label),
          const SizedBox(height: 4),
          _copyRow(_email ?? ''),
          const SizedBox(height: 12),
          const DesignText('Passwort', style: DesignTextStyle.label),
          const SizedBox(height: 4),
          DesignText(
            'Ein unten erstelltes DAV-Token.',
            style: DesignTextStyle.body,
            color: tokens.textLow,
          ),
          const SizedBox(height: 12),
          DesignText(
            'Tokens sind 365 Tage gültig, maximal 5 gleichzeitig. Das '
            'vollständige Token wird nur bei der Erstellung angezeigt.',
            style: DesignTextStyle.label,
            color: tokens.textLow,
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

  Widget _nativeSyncCard() {
    final tokens = DesignTheme.of(context);
    return DesignCard(
      padding: EdgeInsets.all(tokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DesignText(
            'Kalender-Synchronisation',
            style: DesignTextStyle.title,
          ),
          const SizedBox(height: 4),
          DesignText(
            'Spiegelt die Beyond-Kalender automatisch in den Systemkalender '
            'auf diesem Gerät (wie DAVx5). Standard: aktiviert.',
            style: DesignTextStyle.label,
            color: tokens.textLow,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DesignText(
                  _nativeSyncBusy
                      ? 'Wird eingerichtet…'
                      : _nativeSyncEnabled
                      ? 'Aktiv'
                      : 'Deaktiviert',
                  style: DesignTextStyle.body,
                  color: _nativeSyncEnabled ? tokens.success : tokens.textLow,
                ),
              ),
              _nativeSyncBusy
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: tokens.primary,
                      ),
                    )
                  : Material(
                      type: MaterialType.transparency,
                      child: Switch(
                        value: _nativeSyncEnabled,
                        onChanged: _toggleNativeSync,
                        activeThumbColor: tokens.primary,
                      ),
                    ),
            ],
          ),
          if (_nativeSyncEnabled) ...[
            const SizedBox(height: 16),
            DesignText(
              'Sichtbare Kalender',
              style: DesignTextStyle.label,
              color: tokens.textLow,
            ),
            const SizedBox(height: 4),
            for (final type in DavSyncService.calendarTypes) _segmentTile(type),
          ],
          if (_nativeSyncEnabled && _nativeSyncStatus != null) ...[
            const SizedBox(height: 8),
            DesignText(
              'Letzte Synchronisation: ${_statusLabel(_nativeSyncStatus!)}',
              style: DesignTextStyle.label,
              color: tokens.textLow,
            ),
          ],
        ],
      ),
    );
  }

  Widget _segmentTile(DavCalendarType type) {
    final tokens = DesignTheme.of(context);
    final enabled = _enabledSegments.contains(type.segment);
    return Padding(
      padding: EdgeInsets.only(top: tokens.spaceXs),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: Color(type.color),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: tokens.spaceSm),
          Expanded(
            child: DesignText(
              type.label,
              style: DesignTextStyle.body,
              color: tokens.textHigh,
            ),
          ),
          Material(
            type: MaterialType.transparency,
            child: Switch(
              value: enabled,
              onChanged: (v) => _toggleSegment(type, v),
              activeThumbColor: Color(type.color),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleSegment(DavCalendarType type, bool enabled) async {
    final scope = AppScope.of(context);
    final next = List<String>.from(_enabledSegments);
    if (enabled) {
      if (!next.contains(type.segment)) next.add(type.segment);
    } else {
      next.remove(type.segment);
    }
    setState(() => _enabledSegments = next);
    await scope.davSync.updateSegments(next);
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'auth':
        return 'Token abgelaufen, wird erneuert';
      case 'apply':
      case 'calendar':
        return 'Fehler bei der Einrichtung';
      default:
        return status.startsWith('error:') ? 'Fehler ($status)' : status;
    }
  }

  Future<void> _toggleNativeSync(bool newValue) async {
    final scope = AppScope.of(context);
    if (newValue) {
      setState(() => _nativeSyncBusy = true);
      final granted = await scope.davSync.requestPermission();
      if (!granted) {
        if (!mounted) return;
        setState(() => _nativeSyncBusy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Kalender-Zugriff wurde abgelehnt. Synchronisation deaktiviert.',
            ),
          ),
        );
        return;
      }
      try {
        final ok = await scope.davSync.enable();
        if (!mounted) return;
        setState(() {
          _nativeSyncBusy = false;
          _nativeSyncEnabled = ok;
        });
        if (!ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Synchronisation konnte nicht aktiviert werden.'),
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _nativeSyncBusy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Synchronisation konnte nicht aktiviert werden.'),
          ),
        );
      }
    } else {
      final confirmed = await _confirmDisableSync();
      if (confirmed != true || !mounted) return;
      setState(() => _nativeSyncBusy = true);
      await scope.davSync.disable();
      if (!mounted) return;
      setState(() {
        _nativeSyncBusy = false;
        _nativeSyncEnabled = false;
        _nativeSyncStatus = null;
      });
    }
  }

  Future<bool?> _confirmDisableSync() async {
    final tokens = DesignTheme.of(context);
    return showDesignSheet<bool>(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DesignText(
              'Synchronisation deaktivieren',
              style: DesignTextStyle.title,
            ),
            const SizedBox(height: 8),
            DesignText(
              'Der Systemkalender-Account und alle synchronisierten Termine '
              'werden von diesem Gerät entfernt. DAV-Tokens bleiben bestehen.',
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
                    label: 'Deaktivieren',
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tokenList() {
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

    final tokensList = _tokens ?? <DavToken>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tokensList.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spaceLg,
              vertical: tokens.spaceMd,
            ),
            child: DesignText(
              'Noch keine Tokens erstellt.',
              style: DesignTextStyle.body,
              color: tokens.textLow,
            ),
          )
        else
          DesignCard.list(
            children: [
              for (final token in tokensList)
                DesignListTile(
                  leading: const Icon(Icons.vpn_key_rounded),
                  title: token.label,
                  subtitle:
                      'Gültig bis ${formatDate(parseApiDate(token.expiresAt))}',
                  trailing: DesignIconButton(
                    icon: Icons.delete_rounded,
                    onPressed: () => _confirmDelete(token),
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
            label: 'Neues Token erstellen',
            fullWidth: true,
            loading: _creating,
            onPressed: _creating ? null : _createToken,
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
                  'Neues Token erstellen',
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
            'Gib eine Bezeichnung an, z.B. „DAVx5 – Pixel 8".',
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
