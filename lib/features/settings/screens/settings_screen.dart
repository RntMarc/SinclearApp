import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/image/image_provider_helper.dart';
import '../../../core/models/app_update_info.dart';
import '../../../core/services/android_update_service.dart';
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
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null || _user == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 8),
            Text(_error ?? 'Unbekannter Fehler'),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: _load,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    final user = _user!;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // Profile header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundImage: resolveImageProvider(user.base.image),
                child: resolveImageProvider(user.base.image) == null
                    ? Text(
                        user.base.displayName.isNotEmpty
                            ? user.base.displayName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.base.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      user.base.email,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Divider(),

        // Profile section
        _SectionHeader(title: 'Profil'),
        _SettingsTile(
          icon: Icons.person_rounded,
          title: 'Profil bearbeiten',
          subtitle: 'Anzeigename, Geburtstag',
          onTap: () => context.push('/einstellungen/profil'),
        ),
        _SettingsTile(
          icon: Icons.cake_rounded,
          title: 'Geburtstag',
          subtitle: user.base.birthday ?? 'Nicht angegeben',
          onTap: () => context.push('/einstellungen/profil'),
        ),

        const SizedBox(height: 8),
        _SectionHeader(title: 'Vernetzungen'),
        _SettingsTile(
          icon: Icons.alternate_email_rounded,
          title: 'Social Media',
          subtitle: _socialSummary(user.social),
          onTap: () => context.push('/einstellungen/social'),
        ),
        _SettingsTile(
          icon: Icons.chat_rounded,
          title: 'Kontaktmöglichkeiten',
          subtitle: _contactSummary(user.contact),
          onTap: () => context.push('/einstellungen/kontakt'),
        ),

        const SizedBox(height: 8),
        _SectionHeader(title: 'Konto'),
        _SettingsTile(
          icon: Icons.email_rounded,
          title: 'E-Mail ändern',
          subtitle: user.base.email,
          onTap: () => context.push('/einstellungen/email'),
        ),
        _SettingsTile(
          icon: Icons.headset_mic_rounded,
          title: 'Discord-Verknüpfung',
          subtitle: user.base.discordId != null
              ? 'Verbunden (${user.base.discordId})'
              : 'Nicht verbunden',
          onTap: () => context.push('/einstellungen/discord'),
        ),

        const SizedBox(height: 16),
        const Divider(),

        // App section
        _SectionHeader(title: 'App'),
        _SettingsTile(
          icon: Icons.info_outline_rounded,
          title: 'Version',
          subtitle: _packageInfo != null
              ? '${_packageInfo!.version} (${_packageInfo!.buildNumber})'
              : 'Wird geladen...',
          onTap: () {},
        ),
        if (!kIsWeb && kReleaseMode)
          ListTile(
            leading: Icon(
              Icons.system_update_rounded,
              color: _checkingUpdate
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Update prüfen'),
            subtitle: _updateError != null
                ? Text(
                    _updateError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  )
                : _checkingUpdate
                ? const Text('Wird geprüft...')
                : const Text('Auf neuere Version prüfen'),
            trailing: _checkingUpdate
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right_rounded),
            onTap: _checkingUpdate ? null : _checkForUpdateManually,
          ),

        const SizedBox(height: 16),
        const Divider(),

        // Logout
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: OutlinedButton.icon(
            onPressed: _confirmLogout,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Abmelden'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(
                color: theme.colorScheme.error.withValues(alpha: 0.5),
              ),
              minimumSize: const Size.fromHeight(44),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Abmelden'),
        content: const Text('Möchtest du dich wirklich abmelden?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Abmelden'),
          ),
        ],
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

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
