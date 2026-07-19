import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
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

class DiscordRelinkScreen extends StatefulWidget {
  const DiscordRelinkScreen({super.key});

  @override
  State<DiscordRelinkScreen> createState() => _DiscordRelinkScreenState();
}

class _DiscordRelinkScreenState extends State<DiscordRelinkScreen> {
  final _codeController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;
  bool _hasLoaded = false;
  bool _showCodeInput = false;

  UserMe? _user;

  @override
  void dispose() {
    _codeController.dispose();
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
      final user = await AppScope.of(context).user.getMe();
      if (!mounted) return;
      setState(() {
        _user = user;
        _loading = false;
      });
    } catch (e, st) {
      developer.log('Failed to load user', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Daten konnten nicht geladen werden.';
      });
    }
  }

  Future<void> _startRelink() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final url = await AppScope.of(context).user.discordRelinkStart();
      final uri = Uri.tryParse(url);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        setState(() => _error = 'Discord konnte nicht geöffnet werden.');
      }
      if (!mounted) return;
      setState(() {
        _showCodeInput = true;
        _saving = false;
      });
    } catch (e, st) {
      developer.log('Failed to start discord relink', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Fehler beim Starten der Discord-Verknüpfung.';
      });
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6 || !RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _error = 'Bitte gib einen gültigen 6-stelligen Code ein.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await AppScope.of(context).user.discordRelinkVerify(code);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Discord-Verknüpfung aktualisiert')),
      );
    } on ApiException catch (e) {
      setState(() {
        _error = switch (e.errorCode) {
          'invalid_or_expired_code' => 'Der Code ist ungültig oder abgelaufen.',
          _ => e.message ?? 'Ein Fehler ist aufgetreten.',
        };
      });
    } catch (e, st) {
      developer.log('Failed to verify discord code', error: e, stackTrace: st);
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

    final hasDiscord = _user?.base.discordId != null;

    return DesignSurface(
      child: Column(
        children: [
          DesignSubpageHeader(
            leading: DesignIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => context.pop(),
            ),
            title: 'Discord-Verknüpfung',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(tokens.spaceLg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.headset_mic_rounded,
                      size: 56,
                      color: tokens.primary,
                    ),
                    SizedBox(height: tokens.spaceLg),
                    DesignText(
                      hasDiscord ? 'Discord verbunden' : 'Kein Discord verknüpft',
                      style: DesignTextStyle.title,
                    ),
                    SizedBox(height: tokens.spaceSm),
                    DesignText(
                      hasDiscord
                          ? 'Dein Account ist mit Discord-ID ${_user!.base.discordId} verknüpft.'
                          : 'Verknüpfe deinen Discord-Account, um dich schneller anmelden zu können.',
                      color: tokens.textLow,
                    ),
                    SizedBox(height: tokens.spaceXl),
                    if (!_showCodeInput) ...[
                      DesignButton(
                        label: _saving
                            ? 'Wird gestartet…'
                            : 'Discord-Verknüpfung ändern',
                        icon: Icons.open_in_browser_rounded,
                        loading: _saving,
                        onPressed: _saving ? null : _startRelink,
                        fullWidth: true,
                      ),
                    ] else ...[
                      DesignText(
                        'Gib den 6-stelligen Code aus dem Discord-Browser-Tab ein.',
                        color: tokens.textLow,
                      ),
                      SizedBox(height: tokens.spaceMd),
                      DesignTextField(
                        controller: _codeController,
                        hint: 'Pairing-Code',
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 6,
                        prefixIcon: Icons.vpn_key_rounded,
                      ),
                      SizedBox(height: tokens.spaceMd),
                      if (_error != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: tokens.spaceMd),
                          child: DesignText(_error!, color: tokens.danger),
                        ),
                      DesignButton(
                        label: _saving ? 'Wird geprüft…' : 'Bestätigen',
                        icon: Icons.check_rounded,
                        loading: _saving,
                        onPressed: _saving ? null : _verifyCode,
                        fullWidth: true,
                      ),
                      SizedBox(height: tokens.spaceSm),
                      DesignButton(
                        label: 'Abbrechen',
                        variant: DesignButtonVariant.text,
                        onPressed: () {
                          setState(() {
                            _showCodeInput = false;
                            _error = null;
                            _codeController.clear();
                          });
                        },
                        fullWidth: true,
                      ),
                    ],
                    if (_error != null && !_showCodeInput)
                      Padding(
                        padding: EdgeInsets.only(top: tokens.spaceMd),
                        child: DesignText(_error!, color: tokens.danger),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
