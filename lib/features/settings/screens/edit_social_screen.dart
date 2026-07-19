import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/network/api_client.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../../design/widgets/primitives/design_text_field.dart';
import '../../user/models/user_models.dart';
import '../widgets/visibility_badge.dart';

class EditSocialScreen extends StatefulWidget {
  const EditSocialScreen({super.key});

  @override
  State<EditSocialScreen> createState() => _EditSocialScreenState();
}

class _EditSocialScreenState extends State<EditSocialScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  bool _hasLoaded = false;

  final _unsplashController = TextEditingController();
  final _instagramController = TextEditingController();
  final _mastodonUserController = TextEditingController();
  final _mastodonServerController = TextEditingController();
  final _pixelfedUserController = TextEditingController();
  final _pixelfedServerController = TextEditingController();
  final _blueskyController = TextEditingController();
  final _youtubeController = TextEditingController();
  final _twitchController = TextEditingController();

  int _unsplashVisibility = 1;
  int _instagramVisibility = 1;
  int _mastodonVisibility = 1;
  int _pixelfedVisibility = 1;
  int _blueskyVisibility = 1;
  int _youtubeVisibility = 1;
  int _twitchVisibility = 1;

  @override
  void dispose() {
    _unsplashController.dispose();
    _instagramController.dispose();
    _mastodonUserController.dispose();
    _mastodonServerController.dispose();
    _pixelfedUserController.dispose();
    _pixelfedServerController.dispose();
    _blueskyController.dispose();
    _youtubeController.dispose();
    _twitchController.dispose();
    super.dispose();
  }

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
      final social = await AppScope.of(context).user.getMeSocial();
      if (!mounted) return;
      setState(() {
        _unsplashController.text = social.unsplashHandle ?? '';
        _instagramController.text = social.instagramHandle ?? '';
        _mastodonUserController.text = social.mastodonUser ?? '';
        _mastodonServerController.text = social.mastodonServer ?? '';
        _pixelfedUserController.text = social.pixelfedUser ?? '';
        _pixelfedServerController.text = social.pixelfedServer ?? '';
        _blueskyController.text = social.blueskyHandle ?? '';
        _youtubeController.text = social.youtubeHandle ?? '';
        _twitchController.text = social.twitchHandle ?? '';

        _unsplashVisibility = social.unsplashVisibility;
        _instagramVisibility = social.instagramVisibility;
        _mastodonVisibility = social.mastodonVisibility;
        _pixelfedVisibility = social.pixelfedVisibility;
        _blueskyVisibility = social.blueskyVisibility;
        _youtubeVisibility = social.youtubeVisibility;
        _twitchVisibility = social.twitchVisibility;

        _loading = false;
      });
    } catch (e, st) {
      developer.log('Failed to load social info', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Soziale Netzwerke konnten nicht geladen werden.';
      });
    }
  }

  bool _hasInvalidMastodon() {
    final user = _mastodonUserController.text.trim();
    final server = _mastodonServerController.text.trim();
    if (user.isEmpty && server.isEmpty) return false;
    if (user.contains('@') || user.contains(':')) return true;
    if (server.isNotEmpty && !_isDomain(server)) return true;
    return false;
  }

  bool _hasInvalidPixelfed() {
    final user = _pixelfedUserController.text.trim();
    final server = _pixelfedServerController.text.trim();
    if (user.isEmpty && server.isEmpty) return false;
    if (user.contains('@') || user.contains(':')) return true;
    if (server.isNotEmpty && !_isDomain(server)) return true;
    return false;
  }

  bool _isDomain(String v) => RegExp(
    r'^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)*$',
  ).hasMatch(v);

  String? _validate() {
    final unsplash = _unsplashController.text.trim();
    if (unsplash.isNotEmpty && unsplash.contains('@')) {
      return 'Unsplash: Kein @ erlaubt.';
    }
    final instagram = _instagramController.text.trim();
    if (instagram.isNotEmpty && instagram.contains('@')) {
      return 'Instagram: Kein @ erlaubt.';
    }
    if (_hasInvalidMastodon()) {
      return 'Mastodon: Ungültiges Format (User ohne @, Server als Domain).';
    }
    if (_hasInvalidPixelfed()) {
      return 'Pixelfed: Ungültiges Format (User ohne @, Server als Domain).';
    }
    final bluesky = _blueskyController.text.trim();
    if (bluesky.isNotEmpty && bluesky.contains('@')) {
      return 'Bluesky: Kein @ erlaubt (Domain-Format).';
    }
    if (bluesky.isNotEmpty && !_isDomain(bluesky)) {
      return 'Bluesky: Muss eine Domain sein (z.B. user.bsky.social).';
    }
    final youtube = _youtubeController.text.trim();
    if (youtube.isNotEmpty && youtube.contains('@')) {
      return 'YouTube: Kein @ erlaubt.';
    }
    final twitch = _twitchController.text.trim();
    if (twitch.isNotEmpty && twitch.contains('@')) {
      return 'Twitch: Kein @ erlaubt.';
    }
    return null;
  }

  Future<void> _save() async {
    final validationError = _validate();
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final scope = AppScope.of(context);
      final unsplash = _unsplashController.text.trim();
      final instagram = _instagramController.text.trim();
      final mastoUser = _mastodonUserController.text.trim();
      final mastoServer = _mastodonServerController.text.trim();
      final pixelUser = _pixelfedUserController.text.trim();
      final pixelServer = _pixelfedServerController.text.trim();
      final bluesky = _blueskyController.text.trim();
      final youtube = _youtubeController.text.trim();
      final twitch = _twitchController.text.trim();

      await scope.user.updateProfile(
        ProfileUpdateRequest(
          unsplashHandle: unsplash.isNotEmpty ? unsplash : null,
          removeUnsplashHandle: unsplash.isEmpty,
          instagramHandle: instagram.isNotEmpty ? instagram : null,
          removeInstagramHandle: instagram.isEmpty,
          mastodonUser: mastoUser.isNotEmpty ? mastoUser : null,
          removeMastodonUser: mastoUser.isEmpty,
          mastodonServer: mastoServer.isNotEmpty ? mastoServer : null,
          removeMastodonServer: mastoServer.isEmpty,
          pixelfedUser: pixelUser.isNotEmpty ? pixelUser : null,
          removePixelfedUser: pixelUser.isEmpty,
          pixelfedServer: pixelServer.isNotEmpty ? pixelServer : null,
          removePixelfedServer: pixelServer.isEmpty,
          blueskyHandle: bluesky.isNotEmpty ? bluesky : null,
          removeBlueskyHandle: bluesky.isEmpty,
          youtubeHandle: youtube.isNotEmpty ? youtube : null,
          removeYoutubeHandle: youtube.isEmpty,
          twitchHandle: twitch.isNotEmpty ? twitch : null,
          removeTwitchHandle: twitch.isEmpty,
        ),
      );
      await scope.user.updateVisibility(
        VisibilityUpdateRequest(
          unsplashVisibility: _unsplashVisibility,
          instagramVisibility: _instagramVisibility,
          mastodonVisibility: _mastodonVisibility,
          pixelfedVisibility: _pixelfedVisibility,
          blueskyVisibility: _blueskyVisibility,
          youtubeVisibility: _youtubeVisibility,
          twitchVisibility: _twitchVisibility,
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Social Media gespeichert')));
    } on ApiException catch (e) {
      setState(() => _error = e.message ?? 'Fehler beim Speichern.');
    } catch (e, st) {
      developer.log('Failed to save social info', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _error = 'Netzwerkfehler. Bitte prüfe deine Verbindung.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    if (_loading) {
      return DesignSurface(
        child: Center(
          child: CircularProgressIndicator(color: tokens.primary),
        ),
      );
    }

    return DesignSurface(
      child: Column(
        children: [
          DesignSubpageHeader(
            leading: DesignIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => context.pop(),
            ),
            title: 'Social Media',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(tokens.spaceMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _socialField(
                    tokens: tokens,
                    prefixIcon: Icons.camera_alt_rounded,
                    label: 'Unsplash',
                    controller: _unsplashController,
                    hint: 'Benutzername',
                    visibility: _unsplashVisibility,
                    onVisibilityChanged: (v) =>
                        setState(() => _unsplashVisibility = v),
                  ),
                  SizedBox(height: tokens.spaceMd),
                  _socialField(
                    tokens: tokens,
                    prefixIcon: Icons.photo_camera_rounded,
                    label: 'Instagram',
                    controller: _instagramController,
                    hint: 'Benutzername',
                    visibility: _instagramVisibility,
                    onVisibilityChanged: (v) =>
                        setState(() => _instagramVisibility = v),
                  ),
                  SizedBox(height: tokens.spaceMd),
                  _compoundField(
                    tokens: tokens,
                    icon: Icons.group_rounded,
                    label: 'Mastodon',
                    userController: _mastodonUserController,
                    userHint: 'Benutzername',
                    serverController: _mastodonServerController,
                    serverHint: 'Server (z.B. mastodon.social)',
                    visibility: _mastodonVisibility,
                    onVisibilityChanged: (v) =>
                        setState(() => _mastodonVisibility = v),
                  ),
                  SizedBox(height: tokens.spaceMd),
                  _compoundField(
                    tokens: tokens,
                    icon: Icons.photo_library_rounded,
                    label: 'Pixelfed',
                    userController: _pixelfedUserController,
                    userHint: 'Benutzername',
                    serverController: _pixelfedServerController,
                    serverHint: 'Server (z.B. pixelfed.de)',
                    visibility: _pixelfedVisibility,
                    onVisibilityChanged: (v) =>
                        setState(() => _pixelfedVisibility = v),
                  ),
                  SizedBox(height: tokens.spaceMd),
                  _socialField(
                    tokens: tokens,
                    prefixIcon: Icons.tag_rounded,
                    label: 'Bluesky',
                    controller: _blueskyController,
                    hint: 'user.bsky.social',
                    visibility: _blueskyVisibility,
                    onVisibilityChanged: (v) =>
                        setState(() => _blueskyVisibility = v),
                  ),
                  SizedBox(height: tokens.spaceMd),
                  _socialField(
                    tokens: tokens,
                    prefixIcon: Icons.play_circle_rounded,
                    label: 'YouTube',
                    controller: _youtubeController,
                    hint: 'Kanalname',
                    visibility: _youtubeVisibility,
                    onVisibilityChanged: (v) =>
                        setState(() => _youtubeVisibility = v),
                  ),
                  SizedBox(height: tokens.spaceMd),
                  _socialField(
                    tokens: tokens,
                    prefixIcon: Icons.videocam_rounded,
                    label: 'Twitch',
                    controller: _twitchController,
                    hint: 'Kanalname',
                    visibility: _twitchVisibility,
                    onVisibilityChanged: (v) =>
                        setState(() => _twitchVisibility = v),
                  ),
                  SizedBox(height: tokens.spaceLg),
                  if (_error != null)
                    Padding(
                      padding: EdgeInsets.only(bottom: tokens.spaceMd),
                      child: DesignText(_error!, color: tokens.danger),
                    ),
                  DesignButton(
                    label: _saving ? 'Wird gespeichert…' : 'Speichern',
                    icon: Icons.save_rounded,
                    loading: _saving,
                    onPressed: _saving ? null : _save,
                    fullWidth: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _socialField({
  required DesignTokens tokens,
  required IconData prefixIcon,
  required String label,
  required TextEditingController controller,
  required String hint,
  required int visibility,
  required ValueChanged<int> onVisibilityChanged,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: EdgeInsets.only(left: tokens.spaceXs),
        child: DesignText(label, style: DesignTextStyle.label),
      ),
      SizedBox(height: tokens.spaceXs),
      DesignTextField(
        controller: controller,
        hint: hint,
        prefixIcon: prefixIcon,
        suffix: VisibilityBadge(value: visibility, onChanged: onVisibilityChanged),
      ),
    ],
  );
}

Widget _compoundField({
  required DesignTokens tokens,
  required IconData icon,
  required String label,
  required TextEditingController userController,
  required String userHint,
  required TextEditingController serverController,
  required String serverHint,
  required int visibility,
  required ValueChanged<int> onVisibilityChanged,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, size: 18, color: tokens.primary),
          SizedBox(width: tokens.spaceSm),
          DesignText(label, style: DesignTextStyle.label),
        ],
      ),
      SizedBox(height: tokens.spaceSm),
      Row(
        children: [
          const SizedBox(width: 26),
          Expanded(
            child: DesignTextField(
              controller: userController,
              hint: userHint,
            ),
          ),
          SizedBox(width: tokens.spaceSm),
          Expanded(
            child: DesignTextField(
              controller: serverController,
              hint: serverHint,
            ),
          ),
          SizedBox(width: tokens.spaceSm),
          VisibilityBadge(value: visibility, onChanged: onVisibilityChanged),
        ],
      ),
    ],
  );
}
