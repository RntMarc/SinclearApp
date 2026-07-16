import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/network/api_client.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_app_bar.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../../design/widgets/primitives/design_text_field.dart';
import '../../user/models/user_models.dart';
import '../widgets/visibility_badge.dart';

class EditContactScreen extends StatefulWidget {
  const EditContactScreen({super.key});

  @override
  State<EditContactScreen> createState() => _EditContactScreenState();
}

class _EditContactScreenState extends State<EditContactScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  bool _hasLoaded = false;

  final _discordController = TextEditingController();
  final _fluxerController = TextEditingController();
  final _signalController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _matrixUserController = TextEditingController();
  final _matrixServerController = TextEditingController();

  int _discordVisibility = 1;
  int _fluxerVisibility = 1;
  int _signalVisibility = 1;
  int _whatsappVisibility = 1;
  int _matrixVisibility = 1;

  @override
  void dispose() {
    _discordController.dispose();
    _fluxerController.dispose();
    _signalController.dispose();
    _whatsappController.dispose();
    _matrixUserController.dispose();
    _matrixServerController.dispose();
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
      final contact = await AppScope.of(context).user.getMeContact();
      if (!mounted) return;
      setState(() {
        _discordController.text = contact.discordHandle ?? '';
        _fluxerController.text = contact.fluxerHandle ?? '';
        _signalController.text = contact.signalNumber ?? '';
        _whatsappController.text = contact.whatsappNumber ?? '';
        _matrixUserController.text = contact.matrixUser ?? '';
        _matrixServerController.text = contact.matrixHomeserver ?? '';

        _discordVisibility = contact.discordVisibility;
        _fluxerVisibility = contact.fluxerVisibility;
        _signalVisibility = contact.signalVisibility;
        _whatsappVisibility = contact.whatsappVisibility;
        _matrixVisibility = contact.matrixVisibility;

        _loading = false;
      });
    } catch (e, st) {
      developer.log('Failed to load contact info', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Kontaktdaten konnten nicht geladen werden.';
      });
    }
  }

  String? _validate() {
    final signal = _signalController.text.trim();
    if (signal.isNotEmpty && !RegExp(r'^.+\.\d{2}$').hasMatch(signal)) {
      return 'Signal: Format username.00 (Punkt + 2 Ziffern).';
    }
    final whatsapp = _whatsappController.text.trim();
    if (whatsapp.isNotEmpty && !whatsapp.startsWith('+')) {
      return 'WhatsApp: Muss mit + beginnen (z.B. +49123456789).';
    }
    final matrixUser = _matrixUserController.text.trim();
    final matrixServer = _matrixServerController.text.trim();
    if (matrixUser.isNotEmpty &&
        (matrixUser.contains('@') || matrixUser.contains(':'))) {
      return 'Matrix: Benutzername darf kein @ oder : enthalten.';
    }
    if (matrixServer.isNotEmpty &&
        !RegExp(
          r'^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)*$',
        ).hasMatch(matrixServer)) {
      return 'Matrix: Server muss eine gültige Domain sein (z.B. matrix.org).';
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
      final discord = _discordController.text.trim();
      final fluxer = _fluxerController.text.trim();
      final signal = _signalController.text.trim();
      final whatsapp = _whatsappController.text.trim();
      final matrixUser = _matrixUserController.text.trim();
      final matrixServer = _matrixServerController.text.trim();

      await scope.user.updateProfile(
        ProfileUpdateRequest(
          discordHandle: discord.isNotEmpty ? discord : null,
          removeDiscordHandle: discord.isEmpty,
          fluxerHandle: fluxer.isNotEmpty ? fluxer : null,
          removeFluxerHandle: fluxer.isEmpty,
          signalNumber: signal.isNotEmpty ? signal : null,
          removeSignalNumber: signal.isEmpty,
          whatsappNumber: whatsapp.isNotEmpty ? whatsapp : null,
          removeWhatsappNumber: whatsapp.isEmpty,
          matrixUser: matrixUser.isNotEmpty ? matrixUser : null,
          removeMatrixUser: matrixUser.isEmpty,
          matrixHomeserver: matrixServer.isNotEmpty ? matrixServer : null,
          removeMatrixHomeserver: matrixServer.isEmpty,
        ),
      );
      await scope.user.updateVisibility(
        VisibilityUpdateRequest(
          discordVisibility: _discordVisibility,
          fluxerVisibility: _fluxerVisibility,
          signalVisibility: _signalVisibility,
          whatsappVisibility: _whatsappVisibility,
          matrixVisibility: _matrixVisibility,
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kontaktdaten gespeichert')));
    } on ApiException catch (e) {
      setState(() => _error = e.message ?? 'Fehler beim Speichern.');
    } catch (e, st) {
      developer.log('Failed to save contact info', error: e, stackTrace: st);
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
          DesignAppBar(
            leading: DesignIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => context.pop(),
            ),
            title: 'Kontaktmöglichkeiten',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(tokens.spaceMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _contactField(
                    tokens: tokens,
                    prefixIcon: Icons.chat_rounded,
                    label: 'Discord',
                    controller: _discordController,
                    hint: 'Benutzername',
                    visibility: _discordVisibility,
                    onVisibilityChanged: (v) =>
                        setState(() => _discordVisibility = v),
                  ),
                  SizedBox(height: tokens.spaceMd),
                  _contactField(
                    tokens: tokens,
                    prefixIcon: Icons.alternate_email_rounded,
                    label: 'Fluxer',
                    controller: _fluxerController,
                    hint: 'Benutzername',
                    visibility: _fluxerVisibility,
                    onVisibilityChanged: (v) =>
                        setState(() => _fluxerVisibility = v),
                  ),
                  SizedBox(height: tokens.spaceMd),
                  _contactField(
                    tokens: tokens,
                    prefixIcon: Icons.phone_rounded,
                    label: 'Signal',
                    controller: _signalController,
                    hint: 'username.00',
                    visibility: _signalVisibility,
                    onVisibilityChanged: (v) =>
                        setState(() => _signalVisibility = v),
                  ),
                  SizedBox(height: tokens.spaceMd),
                  _contactField(
                    tokens: tokens,
                    prefixIcon: Icons.phone_android_rounded,
                    label: 'WhatsApp',
                    controller: _whatsappController,
                    hint: '+49123456789',
                    visibility: _whatsappVisibility,
                    onVisibilityChanged: (v) =>
                        setState(() => _whatsappVisibility = v),
                  ),
                  SizedBox(height: tokens.spaceMd),
                  _matrixField(tokens),
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

Widget _contactField({
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

Widget _matrixField(DesignTokens tokens) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(Icons.forum_rounded, size: 18, color: tokens.primary),
          SizedBox(width: tokens.spaceSm),
          DesignText('Matrix', style: DesignTextStyle.label),
        ],
      ),
      SizedBox(height: tokens.spaceSm),
      Row(
        children: [
          const SizedBox(width: 26),
          Expanded(
            child: DesignTextField(
              controller: _matrixUserController,
              hint: 'Benutzername',
            ),
          ),
          SizedBox(width: tokens.spaceSm),
          Expanded(
            child: DesignTextField(
              controller: _matrixServerController,
              hint: 'matrix.org',
            ),
          ),
          SizedBox(width: tokens.spaceSm),
          VisibilityBadge(
            value: _matrixVisibility,
            onChanged: (v) => setState(() => _matrixVisibility = v),
          ),
        ],
      ),
    ],
  );
}
}
