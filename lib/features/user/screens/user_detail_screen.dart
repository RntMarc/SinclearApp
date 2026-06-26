import 'dart:developer' as developer;
import 'package:flutter/cupertino.dart';
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
      return const Center(child: CupertinoActivityIndicator());
    }

    if (_error != null || _user == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
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

    final theme = CupertinoTheme.of(context);
    final user = _user!;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: const Icon(CupertinoIcons.back, size: 22),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: ClipOval(
                  child: Container(
                    width: 96,
                    height: 96,
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
                                fontSize: 36,
                                fontWeight: FontWeight.w600,
                                color: theme.primaryColor,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  user.base.displayName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.textStyle.color,
                  ),
                ),
              ),
              if (_isSelf)
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Das bist du',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              if (user.base.email != null)
                _InfoTile(
                  icon: CupertinoIcons.mail,
                  label: 'E-Mail',
                  value: user.base.email!,
                ),
              if (user.base.birthday != null)
                _InfoTile(
                  icon: CupertinoIcons.gift,
                  label: 'Geburtstag',
                  value: user.base.birthday!,
                ),
              _InfoTile(
                icon: CupertinoIcons.calendar,
                label: 'Dabei seit',
                value: user.base.createdAt.substring(0, 10),
              ),
              if (user.social.toList().isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Social Media',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.textStyle.color,
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
                Text(
                  'Kontakt',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.textStyle.color,
                  ),
                ),
                const SizedBox(height: 8),
                if (user.contact.discordHandle != null)
                  _InfoTile(
                    icon: CupertinoIcons.chat_bubble_2_fill,
                    label: 'Discord',
                    value: user.contact.discordHandle!,
                  ),
                if (user.contact.fluxerHandle != null)
                  _InfoTile(
                    icon: CupertinoIcons.at_circle_fill,
                    label: 'Fluxer',
                    value: user.contact.fluxerHandle!,
                  ),
                if (user.contact.signalNumber != null)
                  _InfoTile(
                    icon: CupertinoIcons.phone_fill,
                    label: 'Signal',
                    value: user.contact.signalNumber!,
                  ),
                if (user.contact.whatsappNumber != null)
                  _InfoTile(
                    icon: CupertinoIcons.phone_fill,
                    label: 'WhatsApp',
                    value: user.contact.whatsappNumber!,
                  ),
                if (user.contact.matrixUser != null)
                  _InfoTile(
                    icon: CupertinoIcons.chat_bubble_fill,
                    label: 'Matrix',
                    value: user.contact.matrixHomeserver != null
                        ? '@${user.contact.matrixUser}:${user.contact.matrixHomeserver}'
                        : user.contact.matrixUser!,
                  ),
              ],
            ],
          ),
        ),
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
    final theme = CupertinoTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.primaryColor),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: theme.textTheme.textStyle.color,
                ),
              ),
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

  const _SocialTile({required this.platform, required this.handle, this.url});

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: url != null
          ? GestureDetector(
              onTap: () => launchUrl(Uri.parse(url!)),
              child: _SocialRow(
                platform: platform,
                handle: handle,
                primaryColor: theme.primaryColor,
              ),
            )
          : _SocialRow(
              platform: platform,
              handle: handle,
              primaryColor: theme.primaryColor,
            ),
    );
  }
}

class _SocialRow extends StatelessWidget {
  final String platform;
  final String handle;
  final Color primaryColor;

  const _SocialRow({
    required this.platform,
    required this.handle,
    required this.primaryColor,
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
              style: const TextStyle(
                fontSize: 13,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              handle,
              style: TextStyle(
                fontSize: 15,
                color: primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
