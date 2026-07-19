import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/di/app_scope.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_list_tile.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_avatar.dart';
import '../../../design/widgets/primitives/design_badge.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
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
      return DesignSurface(
        child: Center(
          child: CircularProgressIndicator(
            color: DesignTheme.of(context).primary,
          ),
        ),
      );
    }

    if (_error != null || _user == null) {
      return DesignSurface(
        child: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: DesignTheme.of(context).danger,
                    ),
                    const SizedBox(height: 8),
                    DesignText(
                      _error ?? 'Unbekannter Fehler',
                      style: DesignTextStyle.body,
                    ),
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
        ),
      );
    }

    final tokens = DesignTheme.of(context);
    final user = _user!;

    final infoTiles = <Widget>[
      if (user.base.email != null)
        _infoTile(tokens, Icons.email_rounded, 'E-Mail', user.base.email!),
      if (user.base.birthday != null)
        _infoTile(
          tokens,
          Icons.cake_rounded,
          'Geburtstag',
          user.base.birthday!,
        ),
      _infoTile(
        tokens,
        Icons.calendar_today_rounded,
        'Dabei seit',
        user.base.createdAt.substring(0, 10),
      ),
    ];

    final socialTiles = user.social.toList().map(
      (entry) => _socialTile(tokens, entry),
    );

    final contactTiles = <Widget>[
      if (user.contact.discordHandle != null)
        _infoTile(
          tokens,
          Icons.chat_rounded,
          'Discord',
          user.contact.discordHandle!,
        ),
      if (user.contact.fluxerHandle != null)
        _infoTile(
          tokens,
          Icons.alternate_email_rounded,
          'Fluxer',
          user.contact.fluxerHandle!,
        ),
      if (user.contact.signalNumber != null)
        _infoTile(
          tokens,
          Icons.phone_rounded,
          'Signal',
          user.contact.signalNumber!,
        ),
      if (user.contact.whatsappNumber != null)
        _infoTile(
          tokens,
          Icons.phone_android_rounded,
          'WhatsApp',
          user.contact.whatsappNumber!,
        ),
      if (user.contact.matrixUser != null)
        _infoTile(
          tokens,
          Icons.forum_rounded,
          'Matrix',
          user.contact.matrixHomeserver != null
              ? '@${user.contact.matrixUser}:${user.contact.matrixHomeserver}'
              : user.contact.matrixUser!,
        ),
    ];

    return DesignSurface(
      child: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(tokens.spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              DesignIconButton(
                icon: Icons.arrow_back_rounded,
                onPressed: () => context.pop(),
              ),
              SizedBox(height: tokens.spaceSm),
              Center(
                child: DesignAvatar(
                  imageUrl: user.base.image,
                  name: user.base.displayName,
                  size: 96,
                ),
              ),
              SizedBox(height: tokens.spaceMd),
              Center(
                child: DesignText(
                  user.base.displayName,
                  style: DesignTextStyle.title,
                ),
              ),
              if (_isSelf)
                Padding(
                  padding: EdgeInsets.only(top: tokens.spaceXs),
                  child: const Center(child: DesignBadge(label: 'Das bist du')),
                ),
              SizedBox(height: tokens.spaceXl),
              DesignCard.list(children: infoTiles),
              if (socialTiles.isNotEmpty) ...<Widget>[
                SizedBox(height: tokens.spaceXl),
                const DesignText(
                  'Social Media',
                  style: DesignTextStyle.subtitle,
                ),
                SizedBox(height: tokens.spaceSm),
                DesignCard.list(children: socialTiles.toList()),
              ],
              if (contactTiles.isNotEmpty) ...<Widget>[
                SizedBox(height: tokens.spaceXl),
                const DesignText('Kontakt', style: DesignTextStyle.subtitle),
                SizedBox(height: tokens.spaceSm),
                DesignCard.list(children: contactTiles),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoTile(
    DesignTokens tokens,
    IconData icon,
    String label,
    String value,
  ) {
    return DesignListTile(
      leading: Icon(icon, color: tokens.primary, size: 20),
      title: value,
      subtitle: label,
    );
  }

  Widget _socialTile(DesignTokens tokens, SocialEntry entry) {
    return DesignListTile(
      leading: Icon(Icons.open_in_new_rounded, color: tokens.primary, size: 20),
      title: entry.handle,
      subtitle: entry.platform,
      onTap: entry.url != null ? () => launchUrl(Uri.parse(entry.url!)) : null,
    );
  }
}
