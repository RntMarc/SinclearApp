import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/models/app_update_info.dart';
import '../../../core/services/android_update_service.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/design_variant.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/composite/design_color_picker.dart';
import '../../../design/widgets/composite/design_list_tile.dart';
import '../../../design/widgets/composite/design_segmented_switch.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_avatar.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_divider.dart';
import '../../../design/widgets/primitives/press_scale.dart';
import '../../update/update_dialog.dart';
import '../../user/models/user_models.dart';
import '../models/notification_preference.dart';
import '../models/map_app_preference.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserMe? _user;
  bool _loading = true;
  String? _error;
  bool _hasLoaded = false;
  PackageInfo? _packageInfo;
  bool _checkingUpdate = false;
  String? _updateError;

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
      await scope.auth.getAccessToken();
      final user = await scope.user.getMe();
      final packageInfo = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _user = user;
        _packageInfo = packageInfo;
        _loading = false;
        _error = null;
      });
    } catch (e, st) {
      developer.log('Failed to load profile', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Profil konnte nicht geladen werden.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    if (_loading) {
      return DesignSurface(
        child: Center(child: CircularProgressIndicator(color: tokens.primary)),
      );
    }

    if (_error != null || _user == null) {
      return DesignSurface(
        child: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: tokens.danger),
                  const SizedBox(height: 8),
                  DesignText(_error ?? 'Unbekannter Fehler'),
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
        ),
      );
    }

    final user = _user!;

    return Scaffold(
      body: DesignSurface(
        child: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                // Profile header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      DesignAvatar(
                        imageUrl: user.base.image,
                        name: user.base.displayName,
                        size: 64,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DesignText(
                              user.base.displayName,
                              style: DesignTextStyle.subtitle,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const DesignDivider(),

                // Profile section
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: DesignText(
                    'Profil',
                    style: DesignTextStyle.label,
                    color: tokens.primary,
                  ),
                ),
                DesignCard.list(
                  children: [
                    DesignListTile(
                      leading: const Icon(Icons.person_rounded),
                      title: 'Profil bearbeiten',
                      subtitle: 'Name, Profilbild, Geburtstag',
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/einstellungen/profil'),
                    ),
                    const DesignDivider(),
                    DesignListTile(
                      leading: const Icon(Icons.alternate_email_rounded),
                      title: 'Social Media',
                      subtitle: _socialSummary(user.social),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/einstellungen/social'),
                    ),
                    DesignListTile(
                      leading: const Icon(Icons.chat_rounded),
                      title: 'Kontaktmöglichkeiten',
                      subtitle: _contactSummary(user.contact),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/einstellungen/kontakt'),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: DesignText(
                    'Erscheinungsbild',
                    style: DesignTextStyle.label,
                    color: tokens.primary,
                  ),
                ),
                DesignCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const DesignText('Design', style: DesignTextStyle.title),
                      const SizedBox(height: 4),
                      DesignText(
                        'Wähle das Erscheinungsbild der App. Die Auswahl wird lokal '
                        'auf dem Gerät gespeichert und überlebt Ab- und Anmeldung.',
                        style: DesignTextStyle.label,
                        color: tokens.textLow,
                      ),
                      const SizedBox(height: 12),
                      const DesignSegmentedSwitch(),
                      if (DesignScope.variantOf(context) ==
                          DesignVariant.custom) ...<Widget>[
                        const SizedBox(height: 24),
                        const DesignText(
                          'Akzentfarbe',
                          style: DesignTextStyle.title,
                        ),
                        const SizedBox(height: 4),
                        DesignText(
                          'Wähle eine Akzentfarbe für dein Theme.',
                          style: DesignTextStyle.label,
                          color: tokens.textLow,
                        ),
                        const SizedBox(height: 12),
                        const _AccentColorPicker(),
                      ],
                      const SizedBox(height: 24),
                      const DesignText(
                        'Design-Modus',
                        style: DesignTextStyle.title,
                      ),
                      const SizedBox(height: 4),
                      DesignText(
                        'Dunkel, hell oder Geräteeinstellung folgen.',
                        style: DesignTextStyle.label,
                        color: tokens.textLow,
                      ),
                      const SizedBox(height: 12),
                      _ThemeModeSelector(),
                      const SizedBox(height: 24),
                      const DesignText(
                        'Grain-Effekt',
                        style: DesignTextStyle.title,
                      ),
                      const SizedBox(height: 4),
                      DesignText(
                        'Stärke der feinen Textur im Hintergrund.',
                        style: DesignTextStyle.label,
                        color: tokens.textLow,
                      ),
                      const SizedBox(height: 12),
                      _GrainSlider(),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Notification section
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: DesignText(
                    'Benachrichtigungen',
                    style: DesignTextStyle.label,
                    color: tokens.primary,
                  ),
                ),
                DesignCard.list(
                  children: [
                    DesignListTile(
                      leading: const Icon(Icons.notifications_rounded),
                      title: 'Benachrichtigungen',
                      subtitle:
                          'Methode und Typen verwalten — Aktiv: '
                          '${AppScope.of(context).notificationMethod.value.label}',
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () =>
                          context.push('/einstellungen/benachrichtigungen'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Map app section
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: DesignText(
                    'Karten',
                    style: DesignTextStyle.label,
                    color: tokens.primary,
                  ),
                ),
                DesignCard.list(
                  children: [
                    ListenableBuilder(
                      listenable: AppScope.of(context).mapApp,
                      builder: (context, _) {
                        final current = AppScope.of(context).mapApp.value;
                        return DesignListTile(
                          leading: const Icon(Icons.map_rounded),
                          title: 'Karten-App',
                          subtitle: current.label,
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => context.push('/einstellungen/karte'),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Account section
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: DesignText(
                    'Konto',
                    style: DesignTextStyle.label,
                    color: tokens.primary,
                  ),
                ),
                DesignCard.list(
                  children: [
                    DesignListTile(
                      leading: const Icon(Icons.email_rounded),
                      title: 'E-Mail ändern',
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/einstellungen/email'),
                    ),
                    DesignListTile(
                      leading: const Icon(Icons.headset_mic_rounded),
                      title: 'Discord-Verknüpfung',
                      subtitle: user.base.discordId != null
                          ? 'Verbunden (${user.base.discordId})'
                          : 'Nicht verbunden',
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/einstellungen/discord'),
                    ),
                    const DesignDivider(),
                    DesignListTile(
                      leading: const Icon(Icons.key_rounded),
                      title: 'MCP-API-Keys',
                      subtitle: 'Keys und Endpunkt für den MCP-Server',
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/einstellungen/mcp'),
                    ),
                    DesignListTile(
                      leading: const Icon(Icons.vpn_key_rounded),
                      title: 'DAV-Tokens',
                      subtitle: 'CalDAV- und CardDAV-Synchronisation',
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/einstellungen/dav'),
                    ),
                  ],
                ),

                // App section
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: DesignText(
                    'App',
                    style: DesignTextStyle.label,
                    color: tokens.primary,
                  ),
                ),
                DesignCard.list(
                  children: [
                    DesignListTile(
                      leading: const Icon(Icons.info_outline_rounded),
                      title: 'Version',
                      subtitle: _packageInfo != null
                          ? '${_packageInfo!.version} (${_packageInfo!.buildNumber})'
                          : 'Wird geladen...',
                    ),
                    if (!kIsWeb && kReleaseMode)
                      DesignListTile(
                        leading: Icon(
                          Icons.system_update_rounded,
                          color: _checkingUpdate
                              ? tokens.textLow
                              : tokens.primary,
                        ),
                        title: 'Update prüfen',
                        subtitle: _updateError != null
                            ? _updateError!
                            : _checkingUpdate
                            ? 'Wird geprüft...'
                            : 'Auf neuere Version prüfen',
                        trailing: _checkingUpdate
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: tokens.primary,
                                ),
                              )
                            : const Icon(Icons.chevron_right_rounded),
                        onTap: _checkingUpdate ? null : _checkForUpdateManually,
                      ),
                  ],
                ),

                const SizedBox(height: 16),
                const DesignDivider(),

                // Logout
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: DesignButton(
                    label: 'Abmelden',
                    variant: DesignButtonVariant.outlined,
                    icon: Icons.logout_rounded,
                    fullWidth: true,
                    onPressed: _confirmLogout,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _socialSummary(UserSocialInfo s) {
    final handles = [
      s.unsplashHandle,
      s.instagramHandle,
      s.mastodonUser != null ? 'Mastodon' : null,
      s.pixelfedUser != null ? 'Pixelfed' : null,
      s.blueskyHandle,
      s.youtubeHandle,
      s.twitchHandle,
    ].where((e) => e != null).toList();
    if (handles.isEmpty) return 'Keine Angaben';
    return '${handles.length} Plattform${handles.length == 1 ? '' : 'en'} hinterlegt';
  }

  String _contactSummary(UserContactInfo c) {
    final count = [
      c.discordHandle,
      c.fluxerHandle,
      c.signalNumber,
      c.whatsappNumber,
      c.matrixUser,
    ].where((e) => e != null).length;
    if (count == 0) return 'Keine Angaben';
    return '$count Kontakt${count == 1 ? '' : 'e'} hinterlegt';
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDesignSheet<bool>(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DesignText('Abmelden', style: DesignTextStyle.title),
            const SizedBox(height: 8),
            const DesignText(
              'Möchtest du dich wirklich abmelden?',
              style: DesignTextStyle.body,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DesignButton(
                    label: 'Abbrechen',
                    variant: DesignButtonVariant.text,
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DesignButton(
                    label: 'Abmelden',
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      if (!mounted) return;
      final scope = AppScope.of(context);
      scope.notification.stopPolling();
      scope.notification.clear();
      try {
        await scope.davSync.disable();
      } catch (e) {
        developer.log(
          'Native DAV sync disable failed: $e',
          name: 'settings.logout',
        );
      }
      try {
        if (kIsWeb) {
          final token = await scope.auth.getAccessToken();
          await scope.webPush.unsubscribe(token: token);
        } else if (scope.notificationMethod.value ==
            NotificationMethod.unifiedPush) {
          await scope.unifiedPush.unregister();
        }
      } catch (e) {
        developer.log('Push unregister failed: $e', name: 'settings.logout');
      }
      await scope.auth.logout();
      if (!mounted) return;
      context.go('/');
    }
  }

  Future<void> _checkForUpdateManually() async {
    final androidUpdate = AppScope.of(context).androidUpdate;
    developer.log(
      'Settings: manual update check — isSupported=${androidUpdate.isSupported}',
    );
    if (!androidUpdate.isSupported) return;

    setState(() {
      _checkingUpdate = true;
      _updateError = null;
    });

    try {
      final updateInfo = await androidUpdate.checkForUpdate();
      developer.log('Settings: updateInfo=$updateInfo, mounted=$mounted');
      if (!mounted) return;

      if (updateInfo == null) {
        setState(() {
          _checkingUpdate = false;
          _updateError = 'Kein Update verfügbar.';
        });
        return;
      }

      setState(() => _checkingUpdate = false);
      await UpdateDialog.show(
        // ignore: use_build_context_synchronously
        context,
        updateInfo: updateInfo,
        onDownload: (dialog) =>
            _downloadAndInstall(dialog, androidUpdate, updateInfo),
      );
    } catch (e) {
      developer.log('Settings: update check error: $e');
      if (!mounted) return;
      final message = e.toString().contains('SocketException')
          ? 'Keine Internetverbindung.'
          : e.toString().contains('TimeoutException')
          ? 'Zeitüberschreitung – Server antwortet nicht.'
          : 'Update-Prüfung fehlgeschlagen: $e';
      setState(() {
        _checkingUpdate = false;
        _updateError = message;
      });
    }
  }

  Future<void> _downloadAndInstall(
    UpdateDialogState dialog,
    AndroidUpdateService service,
    AppUpdateInfo info,
  ) async {
    developer.log('Settings: _downloadAndInstall started');
    try {
      final filePath = await service.downloadApk(
        info.downloadUrl,
        onProgress: (p) => dialog.setProgress(p),
      );
      developer.log('Settings: download done, filePath=$filePath');
      if (!mounted) {
        developer.log('Settings: unmounted before pop, aborting');
        return;
      }
      // ignore: use_build_context_synchronously
      Navigator.pop(context, true);
      await Future<void>.delayed(Duration.zero);
      developer.log('Settings: calling installApk…');
      await service.installApk(filePath);
      developer.log('Settings: installApk returned');
    } catch (e) {
      developer.log('Settings: install error: $e');
      dialog.setError('Download fehlgeschlagen: $e');
    }
  }
}

/// Three-way segmented selector for the theme mode (dark / light / sync).
class _ThemeModeSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final active = DesignScope.themeModeOf(context);
    final notifier = DesignScope.themeModeNotifierOf(context);

    const modes = [
      (ThemeMode.dark, 'Dunkel'),
      (ThemeMode.light, 'Hell'),
      (ThemeMode.system, 'Sync'),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: tokens.surfaceVariant.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(tokens.radiusPill),
        border: Border.all(color: tokens.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: modes.map((entry) {
          final (mode, label) = entry;
          final isActive = mode == active;
          return Expanded(
            child: PressScale(
              onTap: () => notifier.value = mode,
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

/// Slider controlling the grain overlay intensity (0 = off, 1 = max).
class _GrainSlider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final notifier = DesignScope.grainNotifierOf(context);
    final grainOpacity = DesignScope.grainOpacityOf(context);

    return Row(
      children: [
        Icon(
          Icons.grain_rounded,
          size: 20,
          color: grainOpacity > 0 ? tokens.primary : tokens.textLow,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: tokens.primary,
              thumbColor: tokens.primary,
              overlayColor: tokens.primary.withValues(alpha: 0.15),
            ),
            child: Slider(
              value: grainOpacity,
              onChanged: (v) => notifier.value = v,
            ),
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 36,
          child: DesignText(
            grainOpacity > 0 ? '${(grainOpacity * 100).round()}%' : 'Aus',
            style: DesignTextStyle.label,
            color: grainOpacity > 0 ? tokens.textHigh : tokens.textLow,
          ),
        ),
      ],
    );
  }
}

/// Grid of preset accent colors for the custom theme.
class _AccentColorPicker extends StatelessWidget {
  const _AccentColorPicker();

  static const _presetColors = <Color>[
    Color(0xFF0064EA), // Blue
    Color(0xFFE53935), // Red
    Color(0xFF43A047), // Green
    Color(0xFF8E24AA), // Purple
    Color(0xFFF57C00), // Orange
    Color(0xFFD81B60), // Pink
    Color(0xFF00897B), // Teal
    Color(0xFF3949AB), // Indigo
    Color(0xFFFFB300), // Amber
    Color(0xFF00ACC1), // Cyan
    Color(0xFF7CB342), // Light Green
    Color(0xFF5C6BC0), // Indigo (lighter)
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final notifier = DesignScope.customAccentNotifierOf(context);
    final current = DesignScope.customAccentOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ..._presetColors.map((color) {
              final isSelected = color.toARGB32() == current.toARGB32();
              return GestureDetector(
                onTap: () => notifier.value = color,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? tokens.textHigh : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.5),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              );
            }),
            const _CustomPickerTile(),
          ],
        ),
      ],
    );
  }
}

/// Tile that opens the configurable HSL color picker.
class _CustomPickerTile extends StatelessWidget {
  const _CustomPickerTile();

  static const _hueGradient = LinearGradient(
    colors: [
      Color(0xFFFF0000),
      Color(0xFFFFFF00),
      Color(0xFF00FF00),
      Color(0xFF00FFFF),
      Color(0xFF0000FF),
      Color(0xFFFF00FF),
      Color(0xFFFF0000),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final notifier = DesignScope.customAccentNotifierOf(context);

    return GestureDetector(
      onTap: () => showDesignSheet<void>(
        context: context,
        child: _CustomColorSheet(notifier: notifier),
      ),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: _hueGradient,
          border: Border.all(
            color: tokens.textLow.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 20,
          shadows: [Shadow(color: Colors.black45, blurRadius: 3)],
        ),
      ),
    );
  }
}

/// Bottom-sheet content hosting the HSL color picker.
class _CustomColorSheet extends StatelessWidget {
  const _CustomColorSheet({required this.notifier});

  final ValueNotifier<Color> notifier;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DesignText('Eigene Farbe', style: DesignTextStyle.subtitle),
        const SizedBox(height: 4),
        DesignText(
          'Stelle den Farbton, die Sättigung und die Helligkeit ein.',
          style: DesignTextStyle.body,
          color: tokens.textLow,
        ),
        const SizedBox(height: 16),
        DesignColorPicker(
          initialColor: notifier.value,
          onChanged: (color) => notifier.value = color,
        ),
      ],
    );
  }
}
