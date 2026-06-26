import 'dart:developer' as developer;
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/image/image_provider_helper.dart';
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
      if (!mounted) return;
      setState(() {
        _user = user;
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
      return const Center(child: CupertinoActivityIndicator());
    }

    if (_error != null || _user == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 48,
              color: CupertinoColors.destructiveRed,
            ),
            const SizedBox(height: 8),
            Text(_error ?? 'Unbekannter Fehler'),
            const SizedBox(height: 16),
            CupertinoButton(
              onPressed: _load,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    final user = _user!;
    final theme = CupertinoTheme.of(context);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // Profile header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              ClipOval(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: resolveImageProvider(user.base.image) != null
                      ? Image(
                          image: resolveImageProvider(user.base.image)!,
                          fit: BoxFit.cover,
                        )
                      : Center(
                          child: Text(
                            user.base.displayName.isNotEmpty
                                ? user.base.displayName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: theme.primaryColor,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.base.displayName,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.textStyle.color,
                      ),
                    ),
                    Text(
                      user.base.email,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.textTheme.textStyle.color
                            ?.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Container(height: 1, color: CupertinoColors.systemGrey4),

        // Profile section
        _SectionHeader(title: 'Profil'),
        _SettingsTile(
          icon: CupertinoIcons.person_fill,
          title: 'Profil bearbeiten',
          subtitle: 'Anzeigename, Geburtstag',
          onTap: () => context.push('/einstellungen/profil'),
        ),
        _SettingsTile(
          icon: CupertinoIcons.gift,
          title: 'Geburtstag',
          subtitle: user.base.birthday ?? 'Nicht angegeben',
          onTap: () => context.push('/einstellungen/profil'),
        ),

        const SizedBox(height: 8),
        _SectionHeader(title: 'Vernetzungen'),
        _SettingsTile(
          icon: CupertinoIcons.at_circle_fill,
          title: 'Social Media',
          subtitle: _socialSummary(user.social),
          onTap: () => context.push('/einstellungen/social'),
        ),
        _SettingsTile(
          icon: CupertinoIcons.chat_bubble_2_fill,
          title: 'Kontaktmöglichkeiten',
          subtitle: _contactSummary(user.contact),
          onTap: () => context.push('/einstellungen/kontakt'),
        ),

        const SizedBox(height: 8),
        _SectionHeader(title: 'Konto'),
        _SettingsTile(
          icon: CupertinoIcons.mail,
          title: 'E-Mail ändern',
          subtitle: user.base.email,
          onTap: () => context.push('/einstellungen/email'),
        ),
        _SettingsTile(
          icon: CupertinoIcons.headphones,
          title: 'Discord-Verknüpfung',
          subtitle: user.base.discordId != null
              ? 'Verbunden (${user.base.discordId})'
              : 'Nicht verbunden',
          onTap: () => context.push('/einstellungen/discord'),
        ),

        const SizedBox(height: 16),
        Container(height: 1, color: CupertinoColors.systemGrey4),

        // Logout
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: CupertinoButton(
            onPressed: _confirmLogout,
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: CupertinoColors.destructiveRed.withValues(alpha: 0.12),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.square_arrow_right,
                  size: 20,
                  color: CupertinoColors.destructiveRed,
                ),
                SizedBox(width: 8),
                Text(
                  'Abmelden',
                  style: TextStyle(
                    color: CupertinoColors.destructiveRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Abmelden'),
        content: const Text('Möchtest du dich wirklich abmelden?'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
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
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: CupertinoTheme.of(context).primaryColor,
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
    final theme = CupertinoTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 22, color: theme.primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.textTheme.textStyle.color,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textTheme.textStyle.color
                          ?.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: CupertinoColors.systemGrey,
            ),
          ],
        ),
      ),
    );
  }
}
