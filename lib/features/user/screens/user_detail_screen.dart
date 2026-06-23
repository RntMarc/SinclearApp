import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/image/image_provider_helper.dart';
import '../models/user_models.dart';

class UserDetailScreen extends StatefulWidget {
  final String id;

  const UserDetailScreen({super.key, required this.id});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  UserDetailPublic? _user;
  bool _loading = true;
  String? _error;
  bool _isSelf = false;
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
      final user = await scope.user.get(widget.id);
      if (!mounted) return;
      setState(() {
        _user = user;
        _isSelf = scope.auth.userId == widget.id;
        _loading = false;
        _error = null;
      });
    } catch (e, st) {
      developer.log('Failed to load user', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Benutzer konnte nicht geladen werden.';
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

    final theme = Theme.of(context);
    final user = _user!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BackButton(),
          const SizedBox(height: 8),
          Center(
            child: CircleAvatar(
            radius: 48,
            backgroundImage: resolveImageProvider(user.base.image),
            child: resolveImageProvider(user.base.image) == null
                ? Text(
                    user.base.displayName.isNotEmpty
                        ? user.base.displayName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  )
                : null,
          ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              user.base.displayName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_isSelf)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Das bist du',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 24),
          if (user.base.email != null)
            _InfoTile(
              icon: Icons.email_rounded,
              label: 'E-Mail',
              value: user.base.email!,
            ),
          if (user.base.birthday != null)
            _InfoTile(
              icon: Icons.cake_rounded,
              label: 'Geburtstag',
              value: user.base.birthday!,
            ),
          _InfoTile(
            icon: Icons.calendar_today_rounded,
            label: 'Dabei seit',
            value: user.base.createdAt.substring(0, 10),
          ),
          if (user.social.toList().isNotEmpty) ...[
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Social Media',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...user.social.toList().map(
              (entry) => _SocialTile(
                platform: entry.platform,
                handle: entry.handle,
                url: entry.url,
              ),
            ),
          ],
          if (user.contact.discordHandle != null ||
              user.contact.fluxerHandle != null ||
              user.contact.signalNumber != null ||
              user.contact.whatsappNumber != null ||
              user.contact.matrixUser != null) ...[
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Kontakt',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (user.contact.discordHandle != null)
              _InfoTile(
                icon: Icons.chat_rounded,
                label: 'Discord',
                value: user.contact.discordHandle!,
              ),
            if (user.contact.fluxerHandle != null)
              _InfoTile(
                icon: Icons.alternate_email_rounded,
                label: 'Fluxer',
                value: user.contact.fluxerHandle!,
              ),
            if (user.contact.signalNumber != null)
              _InfoTile(
                icon: Icons.phone_rounded,
                label: 'Signal',
                value: user.contact.signalNumber!,
              ),
            if (user.contact.whatsappNumber != null)
              _InfoTile(
                icon: Icons.phone_android_rounded,
                label: 'WhatsApp',
                value: user.contact.whatsappNumber!,
              ),
            if (user.contact.matrixUser != null)
              _InfoTile(
                icon: Icons.forum_rounded,
                label: 'Matrix',
                value: user.contact.matrixHomeserver != null
                    ? '@${user.contact.matrixUser}:${user.contact.matrixHomeserver}'
                    : user.contact.matrixUser!,
              ),
          ],
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(value, style: theme.textTheme.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }
}

class _SocialTile extends StatelessWidget {
  final String platform;
  final String handle;
  final String? url;

  const _SocialTile({
    required this.platform,
    required this.handle,
    this.url,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: url != null
          ? InkWell(
              onTap: () => launchUrl(Uri.parse(url!)),
              borderRadius: BorderRadius.circular(8),
              child: _SocialRow(platform: platform, handle: handle, theme: theme),
            )
          : _SocialRow(platform: platform, handle: handle, theme: theme),
    );
  }
}

class _SocialRow extends StatelessWidget {
  final String platform;
  final String handle;
  final ThemeData theme;

  const _SocialRow({
    required this.platform,
    required this.handle,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              platform,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              handle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
