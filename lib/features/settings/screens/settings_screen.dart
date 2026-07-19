import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/models/app_update_info.dart';
import '../../../core/services/android_update_service.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/composite/design_list_tile.dart';
import '../../../design/widgets/composite/design_segmented_switch.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_avatar.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_divider.dart';
import '../../update/update_dialog.dart';
import '../../user/models/user_models.dart';

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
  bool _syncAvatarFromDiscord = true;
  bool _savingSync = false;

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
        _syncAvatarFromDiscord = user.base.syncAvatarFromDiscord;
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

    return DesignSurface(
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
                    subtitle: 'Anzeigename, Geburtstag',
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/einstellungen/profil'),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: DesignText(
                  'Vernetzungen',
                  style: DesignTextStyle.label,
                  color: tokens.primary,
                ),
              ),
              DesignCard.list(
                children: [
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
                  if (user.base.discordId != null)
                    DesignListTile(
                      leading: const Icon(Icons.sync_rounded),
                      title: 'Discord-Profilbild synchronisieren',
                      subtitle: _syncAvatarFromDiscord
                          ? 'Automatisch bei jedem Login'
                          : 'Deaktiviert',
                      trailing: _savingSync
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
                                value: _syncAvatarFromDiscord,
                                onChanged: (v) => _toggleDiscordSync(v),
                                activeThumbColor: tokens.primary,
                              ),
                            ),
                      onTap: _savingSync
                          ? null
                          : () => _toggleDiscordSync(!_syncAvatarFromDiscord),
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
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const DesignDivider(),

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
    );
  }

  Future<void> _toggleDiscordSync(bool newValue) async {
    setState(() => _savingSync = true);

    try {
      final updated = await AppScope.of(
        context,
      ).user.updatePreferences({'syncAvatarFromDiscord': newValue});
      if (!mounted) return;
      setState(() {
        _syncAvatarFromDiscord = updated.syncAvatarFromDiscord;
        _savingSync = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Einstellung gespeichert')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _savingSync = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fehler beim Speichern')));
    }
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
      await AppScope.of(context).auth.logout();
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
