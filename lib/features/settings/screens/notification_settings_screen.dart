import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/notification_config.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/notifications/local_notification_helper.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/composite/design_list_tile.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_avatar.dart';
import '../../../design/widgets/primitives/design_badge.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../../design/widgets/primitives/press_scale.dart';
import '../../notifications/models/notification_type_preference.dart';
import '../../notifications/screens/push_setup_screens.dart';
import '../models/notification_preference.dart';

/// Reihenfolge der Kategorien im Screen; Typen mit unbekannter Kategorie
/// (`NotificationTypeLabel.category` == null) werden nicht angezeigt.
const _categoryOrder = [
  'Forum',
  'Stories',
  'Reisen',
  'Events',
  'Tickets',
  'Unterkunft',
  'Abos',
];

/// Zentraler Screen für die Benachrichtigungs-Verwaltung: Zustell-Methode
/// (Polling/UnifiedPush) und die serververwalteten Typ-Präferenzen
/// (`GET/PUT /notifications/preferences`).
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  Map<String, NotificationTypePreference> _preferences = {};
  final Set<String> _saving = {};
  bool _loading = true;
  String? _error;
  bool _hasLoaded = false;
  bool _savingNotificationMethod = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      _hasLoaded = true;
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final scope = AppScope.of(context);
      final prefs = await scope.notification.getPreferences(
        token: await scope.auth.getAccessToken(),
      );
      if (!mounted) return;
      setState(() {
        _preferences = prefs;
        _loading = false;
        _error = null;
      });
    } catch (e, st) {
      developer.log(
        'Failed to load notification preferences',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Präferenzen konnten nicht geladen werden.';
      });
    }
  }

  Future<void> _savePreference(NotificationTypePreference pref) async {
    setState(() => _saving.add(pref.type));
    try {
      final scope = AppScope.of(context);
      final updated = await scope.notification.updatePreferences([
        pref,
      ], token: await scope.auth.getAccessToken());
      if (!mounted) return;
      setState(() => _preferences = updated);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Einstellung gespeichert')));
    } catch (e, st) {
      developer.log(
        'Failed to save notification preference',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fehler beim Speichern')));
    } finally {
      if (mounted) setState(() => _saving.remove(pref.type));
    }
  }

  Future<void> _toggleEnabled(
    NotificationTypePreference pref,
    bool enabled,
  ) async {
    await _savePreference(
      NotificationTypePreference(
        type: pref.type,
        state: enabled
            ? NotificationPreferenceState.enabled
            : NotificationPreferenceState.disabled,
        customAllowed: pref.customAllowed,
      ),
    );
  }

  Future<void> _openCustomSheet(NotificationTypePreference pref) async {
    final key = NotificationTypeLabel.customDataKey(pref.type);
    if (key == null) return;
    final result = await showDesignSheet<NotificationTypePreference>(
      context: context,
      child: _CustomPreferenceSheet(
        type: pref.type,
        keyName: key,
        initial: pref,
      ),
    );
    if (result == null || !mounted) return;
    await _savePreference(result);
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
            title: 'Benachrichtigungen',
          ),
          Expanded(
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(color: tokens.primary),
                  )
                : _error != null
                ? _errorView(context, tokens)
                : _content(context, tokens),
          ),
        ],
      ),
    );
  }

  Widget _errorView(BuildContext context, DesignTokens tokens) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: tokens.danger),
              const SizedBox(height: 8),
              DesignText(_error!, style: DesignTextStyle.body),
              const SizedBox(height: 16),
              DesignButton(
                label: 'Erneut versuchen',
                variant: DesignButtonVariant.outlined,
                onPressed: _load,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, DesignTokens tokens) {
    final visibleTypes =
        _preferences.values
            .where((p) => NotificationTypeLabel.category(p.type) != null)
            .toList()
          ..sort(
            (a, b) => NotificationTypeLabel.title(
              a.type,
            ).compareTo(NotificationTypeLabel.title(b.type)),
          );

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(vertical: tokens.spaceSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!kIsWeb) ...<Widget>[
            _sectionHeader(context, 'Zustellung', tokens),
            DesignCard.list(
              children: [
                for (final method in NotificationMethodX.availableFor())
                  DesignListTile(
                    leading: Icon(
                      method == NotificationMethod.unifiedPush
                          ? Icons.push_pin_rounded
                          : Icons.sync_rounded,
                      color: tokens.textHigh,
                    ),
                    title: method.label,
                    subtitle: method.description,
                    trailing: _savingNotificationMethod
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: tokens.primary,
                            ),
                          )
                        : Icon(
                            AppScope.of(context).notificationMethod.value ==
                                    method
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color:
                                AppScope.of(context).notificationMethod.value ==
                                    method
                                ? tokens.primary
                                : tokens.textLow,
                          ),
                    onTap: _savingNotificationMethod
                        ? null
                        : () => _applyNotificationMethod(method),
                  ),
                if (Platform.isAndroid)
                  const DesignListTile(
                    leading: Icon(Icons.cloud_rounded),
                    title: 'FCM',
                    subtitle: 'Google Firebase Cloud Messaging – geplant',
                    trailing: DesignBadge(label: 'Bald verfügbar'),
                  ),
              ],
            ),
            SizedBox(height: tokens.spaceMd),
          ],
          for (final category in _categoryOrder) ...<Widget>[
            if (visibleTypes.any(
              (p) => NotificationTypeLabel.category(p.type) == category,
            )) ...<Widget>[
              _sectionHeader(context, category, tokens),
              DesignCard.list(
                children: [
                  for (final pref in visibleTypes.where(
                    (p) => NotificationTypeLabel.category(p.type) == category,
                  ))
                    _typeTile(context, pref, tokens),
                ],
              ),
              SizedBox(height: tokens.spaceMd),
            ],
          ],
          if (visibleTypes.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: DesignText(
                  'Keine Benachrichtigungstypen verfügbar.',
                  style: DesignTextStyle.body,
                  color: tokens.textLow,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionHeader(
    BuildContext context,
    String label,
    DesignTokens tokens,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLg,
        tokens.spaceMd,
        tokens.spaceLg,
        tokens.spaceXs,
      ),
      child: DesignText(
        label,
        style: DesignTextStyle.label,
        color: tokens.primary,
      ),
    );
  }

  Widget _typeTile(
    BuildContext context,
    NotificationTypePreference pref,
    DesignTokens tokens,
  ) {
    final type = pref.type;
    final label = NotificationTypeLabel.title(type);
    final icon = NotificationTypeLabel.icon(type);
    final canCustom =
        pref.customAllowed && NotificationTypeLabel.customDataKey(type) != null;

    if (canCustom) {
      final excluded = NotificationTypeLabel.customDataKey(type) != null
          ? pref.denylistIds(NotificationTypeLabel.customDataKey(type)!).length
          : 0;
      final subtitle = switch (pref.state) {
        NotificationPreferenceState.enabled => 'Aktiv',
        NotificationPreferenceState.disabled => 'Aus',
        NotificationPreferenceState.custom =>
          excluded == 0
              ? 'Individuell'
              : 'Individuell ($excluded ausgeschlossen)',
      };
      return DesignListTile(
        leading: Icon(icon, color: tokens.textHigh),
        title: label,
        subtitle: subtitle,
        trailing: _saving.contains(type)
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: tokens.primary,
                ),
              )
            : Icon(Icons.tune_rounded, color: tokens.textLow),
        onTap: _saving.contains(type) ? null : () => _openCustomSheet(pref),
      );
    }

    return DesignListTile(
      leading: Icon(icon, color: tokens.textHigh),
      title: label,
      subtitle: pref.state == NotificationPreferenceState.disabled
          ? 'Aus'
          : 'Aktiv',
      trailing: _saving.contains(type)
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
                value: pref.state != NotificationPreferenceState.disabled,
                onChanged: (v) => _toggleEnabled(pref, v),
                activeThumbColor: tokens.primary,
              ),
            ),
      onTap: _saving.contains(type)
          ? null
          : () => _toggleEnabled(
              pref,
              pref.state == NotificationPreferenceState.disabled,
            ),
    );
  }

  // --- Zustell-Methode (aus dem Haupt-Settings hierher verschoben) ---

  Future<void> _setupPush() async {
    final scope = AppScope.of(context);
    await LocalNotificationHelper.requestPermission();
    scope.unifiedPush.init(
      token: await scope.auth.getAccessToken(),
      onMessage: (item) {
        scope.notification.registerIncoming(item);
        unawaited(scope.notificationContent.showLocal(item));
      },
    );
    if (!mounted) return;
    await scope.unifiedPush.checkAndSetup(
      context: context,
      onDistributorsFound: (distributors) async {
        if (!mounted) return;
        await showDistributorPickerSheet(
          context: context,
          distributors: distributors,
          onSelect: scope.unifiedPush.selectDistributor,
        );
      },
      onNoDistributor: () async {
        if (!mounted) return;
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const NoDistributorScreen()));
      },
    );
  }

  /// Stoppt den bisherigen Service und startet die gewählte Methode.
  Future<void> _applyNotificationMethod(NotificationMethod method) async {
    final scope = AppScope.of(context);
    final previous = scope.notificationMethod.value;
    if (method == previous) return;

    setState(() => _savingNotificationMethod = true);
    try {
      switch (method) {
        case NotificationMethod.polling:
          if (previous == NotificationMethod.unifiedPush) {
            await scope.unifiedPush.unregister();
          }
          await LocalNotificationHelper.requestPermission();
          scope.notification.startPolling(
            token: await scope.auth.getAccessToken(),
          );
        case NotificationMethod.unifiedPush:
          scope.notification.stopPolling();
          await _setupPush();
        case NotificationMethod.fcm:
          break;
      }
      scope.notificationMethod.value = method;
      await NotificationPreference.save(method);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Benachrichtigungs-Methode: ${method.label}')),
      );
    } catch (e) {
      developer.log(
        'Notification method switch failed',
        error: e,
        name: 'settings.notifications',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Methode konnte nicht gewechselt werden')),
      );
    } finally {
      if (mounted) setState(() => _savingNotificationMethod = false);
    }
  }
}

/// Denylist-Eintrag für den Picker (id + Anzeigename + optionales Bild).
class _DenylistItem {
  final String id;
  final String label;
  final String? image;

  const _DenylistItem({required this.id, required this.label, this.image});
}

/// Bottom-Sheet zur Konfiguration eines `custom`-fähigen Typs:
/// 3-Stufen-Auswahl (An/Aus/Individuell) plus Denylist-Checkboxen.
class _CustomPreferenceSheet extends StatefulWidget {
  final String type;
  final String keyName;
  final NotificationTypePreference initial;

  const _CustomPreferenceSheet({
    required this.type,
    required this.keyName,
    required this.initial,
  });

  @override
  State<_CustomPreferenceSheet> createState() => _CustomPreferenceSheetState();
}

class _CustomPreferenceSheetState extends State<_CustomPreferenceSheet> {
  late NotificationPreferenceState _state;
  late Set<String> _denylist;
  bool _loadingList = true;
  String? _listError;
  List<_DenylistItem> _items = [];
  bool _hasLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      _hasLoaded = true;
      _state = widget.initial.state == NotificationPreferenceState.disabled
          ? NotificationPreferenceState.disabled
          : widget.initial.state;
      _denylist = widget.initial.denylistIds(widget.keyName).toSet();
      _loadItems();
    }
  }

  Future<void> _loadItems() async {
    setState(() => _loadingList = true);
    try {
      final scope = AppScope.of(context);
      final List<_DenylistItem> items;
      if (widget.keyName == 'forumIds') {
        // Nur Mitglieds-Foren sind relevant — `isMember` liefert die
        // Listen-Antwort seit dem API-Update.
        final response = await scope.forum.list(limit: 100);
        items = response.data
            .where((f) => f.isMember)
            .map((f) => _DenylistItem(id: f.id, label: f.name))
            .toList();
      } else {
        final selfId = scope.auth.userId;
        final users = await scope.user.listAll();
        items = users
            .where((u) => u.id != selfId)
            .map(
              (u) =>
                  _DenylistItem(id: u.id, label: u.displayName, image: u.image),
            )
            .toList();
      }
      if (!mounted) return;
      setState(() {
        _items = items;
        _loadingList = false;
        _listError = null;
      });
    } catch (e, st) {
      developer.log(
        'Failed to load denylist items',
        error: e,
        stackTrace: st,
        name: 'notification_preferences',
      );
      if (!mounted) return;
      setState(() {
        _loadingList = false;
        _listError = 'Auswahl konnte nicht geladen werden.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesignText(
          NotificationTypeLabel.title(widget.type),
          style: DesignTextStyle.subtitle,
        ),
        SizedBox(height: tokens.spaceSm),
        _StateSelector(
          state: _state,
          onChanged: (s) => setState(() => _state = s),
        ),
        if (_state == NotificationPreferenceState.custom) ...<Widget>[
          SizedBox(height: tokens.spaceMd),
          DesignText(
            'Benachrichtigungen ausblenden für:',
            style: DesignTextStyle.label,
            color: tokens.textLow,
          ),
          SizedBox(height: tokens.spaceSm),
          _buildDenylist(tokens),
        ],
        SizedBox(height: tokens.spaceLg),
        Row(
          children: [
            Expanded(
              child: DesignButton(
                label: 'Abbrechen',
                variant: DesignButtonVariant.text,
                onPressed: () => Navigator.pop(context),
              ),
            ),
            SizedBox(width: tokens.spaceMd),
            Expanded(
              child: DesignButton(
                label: 'Übernehmen',
                onPressed: () => Navigator.pop(
                  context,
                  NotificationTypePreference(
                    type: widget.type,
                    state: _state,
                    customAllowed: true,
                    customData: _state == NotificationPreferenceState.custom
                        ? {widget.keyName: _denylist.toList()}
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDenylist(DesignTokens tokens) {
    if (_loadingList) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: CircularProgressIndicator(color: tokens.primary),
        ),
      );
    }
    if (_listError != null) {
      return DesignText(
        _listError!,
        style: DesignTextStyle.body,
        color: tokens.danger,
      );
    }
    if (_items.isEmpty) {
      return DesignText(
        'Keine Einträge vorhanden.',
        style: DesignTextStyle.body,
        color: tokens.textLow,
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 320),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          final excluded = _denylist.contains(item.id);
          return DesignListTile(
            leading: item.image != null
                ? DesignAvatar(imageUrl: item.image, name: item.label, size: 32)
                : Icon(Icons.forum_rounded, color: tokens.textLow),
            title: item.label,
            trailing: Checkbox(
              value: excluded,
              activeColor: tokens.primary,
              onChanged: (v) => setState(() {
                if (v == true) {
                  _denylist.add(item.id);
                } else {
                  _denylist.remove(item.id);
                }
              }),
            ),
            onTap: () => setState(() {
              if (_denylist.contains(item.id)) {
                _denylist.remove(item.id);
              } else {
                _denylist.add(item.id);
              }
            }),
          );
        },
      ),
    );
  }
}

/// 3-Stufen-Auswahl (An / Aus / Individuell) im Stil der bestehenden
/// Segmented-Switches.
class _StateSelector extends StatelessWidget {
  final NotificationPreferenceState state;
  final ValueChanged<NotificationPreferenceState> onChanged;

  const _StateSelector({required this.state, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    const options = [
      (NotificationPreferenceState.enabled, 'An'),
      (NotificationPreferenceState.disabled, 'Aus'),
      (NotificationPreferenceState.custom, 'Individuell'),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: tokens.surfaceVariant.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(tokens.radiusPill),
        border: Border.all(color: tokens.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: options.map((entry) {
          final (option, label) = entry;
          final isActive = option == state;
          return Expanded(
            child: PressScale(
              onTap: () => onChanged(option),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: tokens.spaceSm),
                decoration: BoxDecoration(
                  color: isActive ? tokens.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(tokens.radiusPill),
                  boxShadow: isActive ? tokens.glowShadow : null,
                ),
                alignment: Alignment.center,
                child: DesignText(
                  label,
                  style: DesignTextStyle.label,
                  color: isActive ? tokens.textOnPrimary : tokens.textLow,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
