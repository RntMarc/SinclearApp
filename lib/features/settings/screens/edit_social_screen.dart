import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/network/api_client.dart';
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
    if (unsplash.isNotEmpty && unsplash.contains('@'))
      return 'Unsplash: Kein @ erlaubt.';
    final instagram = _instagramController.text.trim();
    if (instagram.isNotEmpty && instagram.contains('@'))
      return 'Instagram: Kein @ erlaubt.';
    if (_hasInvalidMastodon())
      return 'Mastodon: Ungültiges Format (User ohne @, Server als Domain).';
    if (_hasInvalidPixelfed())
      return 'Pixelfed: Ungültiges Format (User ohne @, Server als Domain).';
    final bluesky = _blueskyController.text.trim();
    if (bluesky.isNotEmpty && bluesky.contains('@'))
      return 'Bluesky: Kein @ erlaubt (Domain-Format).';
    if (bluesky.isNotEmpty && !_isDomain(bluesky))
      return 'Bluesky: Muss eine Domain sein (z.B. user.bsky.social).';
    final youtube = _youtubeController.text.trim();
    if (youtube.isNotEmpty && youtube.contains('@'))
      return 'YouTube: Kein @ erlaubt.';
    final twitch = _twitchController.text.trim();
    if (twitch.isNotEmpty && twitch.contains('@'))
      return 'Twitch: Kein @ erlaubt.';
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
      await scope.user.updateProfile(
        ProfileUpdateRequest(
          unsplashHandle: _emptyToNull(_unsplashController.text.trim()),
          instagramHandle: _emptyToNull(_instagramController.text.trim()),
          mastodonUser: _emptyToNull(_mastodonUserController.text.trim()),
          mastodonServer: _emptyToNull(_mastodonServerController.text.trim()),
          pixelfedUser: _emptyToNull(_pixelfedUserController.text.trim()),
          pixelfedServer: _emptyToNull(_pixelfedServerController.text.trim()),
          blueskyHandle: _emptyToNull(_blueskyController.text.trim()),
          youtubeHandle: _emptyToNull(_youtubeController.text.trim()),
          twitchHandle: _emptyToNull(_twitchController.text.trim()),
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

  String? _emptyToNull(String v) {
    return v.isEmpty ? null : v;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('SOCIAL MEDIA')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SocialField(
                icon: Icons.camera_alt_rounded,
                label: 'Unsplash',
                controller: _unsplashController,
                hint: 'Benutzername',
                visibility: _unsplashVisibility,
                onVisibilityChanged: (v) =>
                    setState(() => _unsplashVisibility = v),
              ),
              const SizedBox(height: 16),
              _SocialField(
                icon: Icons.photo_camera_rounded,
                label: 'Instagram',
                controller: _instagramController,
                hint: 'Benutzername',
                visibility: _instagramVisibility,
                onVisibilityChanged: (v) =>
                    setState(() => _instagramVisibility = v),
              ),
              const SizedBox(height: 16),
              _CompoundSocialField(
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
              const SizedBox(height: 16),
              _CompoundSocialField(
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
              const SizedBox(height: 16),
              _SocialField(
                icon: Icons.tag_rounded,
                label: 'Bluesky',
                controller: _blueskyController,
                hint: 'user.bsky.social',
                visibility: _blueskyVisibility,
                onVisibilityChanged: (v) =>
                    setState(() => _blueskyVisibility = v),
              ),
              const SizedBox(height: 16),
              _SocialField(
                icon: Icons.play_circle_rounded,
                label: 'YouTube',
                controller: _youtubeController,
                hint: 'Kanalname',
                visibility: _youtubeVisibility,
                onVisibilityChanged: (v) =>
                    setState(() => _youtubeVisibility = v),
              ),
              const SizedBox(height: 16),
              _SocialField(
                icon: Icons.videocam_rounded,
                label: 'Twitch',
                controller: _twitchController,
                hint: 'Kanalname',
                visibility: _twitchVisibility,
                onVisibilityChanged: (v) =>
                    setState(() => _twitchVisibility = v),
              ),
              const SizedBox(height: 24),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _error!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(_saving ? 'Wird gespeichert…' : 'Speichern'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialField extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final String hint;
  final int visibility;
  final ValueChanged<int> onVisibilityChanged;

  const _SocialField({
    required this.icon,
    required this.label,
    required this.controller,
    required this.hint,
    required this.visibility,
    required this.onVisibilityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hint,
                  border: const OutlineInputBorder(),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                textCapitalization: TextCapitalization.none,
              ),
            ),
            const SizedBox(width: 8),
            VisibilityBadge(value: visibility, onChanged: onVisibilityChanged),
          ],
        ),
      ],
    );
  }
}

class _CompoundSocialField extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextEditingController userController;
  final String userHint;
  final TextEditingController serverController;
  final String serverHint;
  final int visibility;
  final ValueChanged<int> onVisibilityChanged;

  const _CompoundSocialField({
    required this.icon,
    required this.label,
    required this.userController,
    required this.userHint,
    required this.serverController,
    required this.serverHint,
    required this.visibility,
    required this.onVisibilityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const SizedBox(width: 26),
            Expanded(
              child: TextField(
                controller: userController,
                decoration: InputDecoration(
                  labelText: 'Benutzername',
                  hintText: userHint,
                  border: const OutlineInputBorder(),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                textCapitalization: TextCapitalization.none,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: serverController,
                decoration: InputDecoration(
                  labelText: 'Server',
                  hintText: serverHint,
                  border: const OutlineInputBorder(),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                textCapitalization: TextCapitalization.none,
              ),
            ),
            const SizedBox(width: 8),
            VisibilityBadge(value: visibility, onChanged: onVisibilityChanged),
          ],
        ),
      ],
    );
  }
}
