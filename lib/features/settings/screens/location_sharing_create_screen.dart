import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/app_scope.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/composite/design_list_tile.dart';
import '../../../design/widgets/composite/design_picker_field.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_avatar.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../../design/widgets/primitives/press_scale.dart';
import '../../location_sharing/models/location_sharing_models.dart';
import '../../user/models/user_models.dart';

/// Erstellt eine neue Standort-Sharing-Session: Empfänger auswählen, Dauer
/// und Modus festlegen. Nach dem Erstellen werden Token und die
/// Drittanbieter-URLs zum Kopieren angezeigt.
class LocationSharingCreateScreen extends StatefulWidget {
  const LocationSharingCreateScreen({super.key});

  @override
  State<LocationSharingCreateScreen> createState() =>
      _LocationSharingCreateScreenState();
}

class _LocationSharingCreateScreenState
    extends State<LocationSharingCreateScreen> {
  static const _durations = <({String label, int? seconds})>[
    (label: '15 Minuten', seconds: 900),
    (label: '1 Stunde', seconds: 3600),
    (label: '2 Stunden', seconds: 7200),
    (label: '8 Stunden', seconds: 28800),
    (label: '24 Stunden', seconds: 86400),
    (label: 'Unbegrenzt', seconds: null),
  ];

  List<UserBasePublic> _contacts = const [];
  final Set<String> _selectedIds = {};
  bool _loadingContacts = true;
  String? _loadError;
  int? _durationSeconds = 3600;
  SharingMode _mode = SharingMode.location;
  bool _creating = false;
  bool _didLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoad) {
      _didLoad = true;
      _loadContacts();
    }
  }

  Future<void> _loadContacts() async {
    setState(() {
      _loadingContacts = true;
      _loadError = null;
    });
    try {
      final scope = AppScope.of(context);
      final contacts = await scope.user.listAll();
      if (!mounted) return;
      setState(() {
        _contacts = contacts.where((c) => c.id != scope.auth.userId).toList();
        _loadingContacts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingContacts = false;
        _loadError = 'Kontakte konnten nicht geladen werden.';
      });
    }
  }

  Future<void> _create() async {
    setState(() => _creating = true);
    try {
      final created = await AppScope.of(context).locationSharing.createSession(
        recipientIds: _selectedIds.toList(),
        durationSeconds: _durationSeconds,
        sharingMode: _mode,
      );
      if (!mounted) return;
      setState(() => _creating = false);
      await _showCreatedSession(created);
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _creating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session konnte nicht erstellt werden.')),
      );
    }
  }

  Future<void> _showCreatedSession(LocationSharingSession session) async {
    final tokens = DesignTheme.of(context);
    await showDesignSheet<void>(
      context: context,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DesignText(
                'Session erstellt',
                style: DesignTextStyle.title,
              ),
              const SizedBox(height: 8),
              DesignText(
                'Trage eine der folgenden URLs in deine Tracking-App ein, '
                'damit sie deinen Standort automatisch sendet.',
                style: DesignTextStyle.body,
                color: tokens.textLow,
              ),
              const SizedBox(height: 16),
              _urlRow(context, 'Token', session.token),
              const SizedBox(height: 8),
              ..._integrationEntries(
                session.integrationUrls,
              ).map((e) => _urlRow(context, e.label, e.url)),
              const SizedBox(height: 16),
              DesignButton(
                variant: DesignButtonVariant.filled,
                label: 'Schließen',
                fullWidth: true,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<({String label, String url})> _integrationEntries(
    Map<String, String> urls,
  ) {
    const keys = [
      ('osmand', 'OsmAnd'),
      ('gpslogger', 'GPSLogger'),
      ('owntracks', 'OwnTracks'),
      ('traccar', 'Traccar'),
      ('httpGet', 'HTTP GET'),
    ];
    return [
      for (final (key, label) in keys)
        if (urls[key] != null && urls[key]!.isNotEmpty)
          (label: label, url: urls[key]!),
    ];
  }

  Widget _urlRow(BuildContext context, String label, String url) {
    final tokens = DesignTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DesignText(label, style: DesignTextStyle.label, color: tokens.textLow),
        const SizedBox(height: 4),
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
                  url,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: tokens.textHigh,
                  ),
                ),
              ),
              SizedBox(width: tokens.spaceSm),
              DesignIconButton(
                icon: Icons.copy_rounded,
                onPressed: () => _copy(url),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Kopiert')));
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
            title: 'Neue Session',
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: tokens.spaceMd),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: DesignText(
                    'Empfänger',
                    style: DesignTextStyle.label,
                    color: tokens.primary,
                  ),
                ),
                _recipientList(),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: DesignText(
                    'Dauer',
                    style: DesignTextStyle.label,
                    color: tokens.primary,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DesignPickerField(
                    prefixIcon: Icons.schedule_rounded,
                    value: _durationSeconds == null
                        ? 'unlimited'
                        : _durationSeconds.toString(),
                    hint: 'Dauer wählen',
                    items: [
                      for (final d in _durations)
                        DesignPickerItem(
                          value: d.seconds?.toString() ?? 'unlimited',
                          label: d.label,
                        ),
                    ],
                    onChanged: (v) => setState(() {
                      _durationSeconds = v == 'unlimited'
                          ? null
                          : int.tryParse(v);
                    }),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: DesignText(
                    'Modus',
                    style: DesignTextStyle.label,
                    color: tokens.primary,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _ModeSwitch(
                    value: _mode,
                    onChanged: (m) => setState(() => _mode = m),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DesignButton(
                    variant: DesignButtonVariant.filled,
                    icon: Icons.share_location_rounded,
                    label: 'Session erstellen',
                    fullWidth: true,
                    loading: _creating,
                    onPressed: _selectedIds.isEmpty || _creating
                        ? null
                        : _create,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _recipientList() {
    final tokens = DesignTheme.of(context);

    if (_loadingContacts) {
      return Padding(
        padding: EdgeInsets.all(tokens.spaceXl),
        child: Center(child: CircularProgressIndicator(color: tokens.primary)),
      );
    }
    if (_loadError != null) {
      return Padding(
        padding: EdgeInsets.all(tokens.spaceXl),
        child: Center(
          child: Column(
            children: [
              DesignText(_loadError!),
              const SizedBox(height: 16),
              DesignButton(
                label: 'Erneut versuchen',
                variant: DesignButtonVariant.outlined,
                onPressed: _loadContacts,
              ),
            ],
          ),
        ),
      );
    }
    if (_contacts.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceLg,
          vertical: tokens.spaceMd,
        ),
        child: DesignText(
          'Keine Kontakte gefunden.',
          style: DesignTextStyle.body,
          color: tokens.textLow,
        ),
      );
    }

    return DesignCard.list(
      children: [for (final contact in _contacts) _recipientTile(contact)],
    );
  }

  Widget _recipientTile(UserBasePublic contact) {
    final tokens = DesignTheme.of(context);
    final selected = _selectedIds.contains(contact.id);
    return DesignListTile(
      leading: DesignAvatar(
        imageUrl: contact.image,
        name: contact.displayName,
        size: 40,
      ),
      title: contact.displayName,
      trailing: Icon(
        selected
            ? Icons.check_circle_rounded
            : Icons.radio_button_unchecked_rounded,
        color: selected ? tokens.primary : tokens.textLow,
      ),
      onTap: () => setState(() {
        selected
            ? _selectedIds.remove(contact.id)
            : _selectedIds.add(contact.id);
      }),
    );
  }
}

/// Zweistufiger Umschalter für den Sharing-Modus (Standort / Route).
class _ModeSwitch extends StatelessWidget {
  final SharingMode value;
  final ValueChanged<SharingMode> onChanged;

  const _ModeSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: tokens.surfaceVariant.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(tokens.radiusPill),
        border: Border.all(color: tokens.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: SharingMode.values.map((mode) {
              final isActive = mode == value;
              final isDisabled = mode == SharingMode.route;
              return Expanded(
                child: Opacity(
                  opacity: isDisabled ? 0.45 : 1.0,
                  child: PressScale(
                    onTap: isDisabled ? null : () => onChanged(mode),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: tokens.spaceSm),
                      decoration: BoxDecoration(
                        color: isActive ? tokens.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(tokens.radiusPill),
                      ),
                      alignment: Alignment.center,
                      child: DesignText(
                        isDisabled ? 'Route (bald)' : mode.label,
                        style: DesignTextStyle.label,
                        color: isActive ? tokens.onPrimary : tokens.textLow,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              tokens.spaceMd,
              tokens.spaceSm,
              tokens.spaceMd,
              tokens.spaceSm,
            ),
            child: DesignText(
              value.description,
              style: DesignTextStyle.label,
              color: tokens.textLow,
            ),
          ),
        ],
      ),
    );
  }
}
