import 'dart:developer' as developer;
import 'package:flutter/cupertino.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/network/api_client.dart';
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
      return 'Matrix: Server muss eine gultige Domain sein.';
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
      await scope.user.updateProfile(
        ProfileUpdateRequest(
          discordHandle: _emptyToNull(_discordController),
          fluxerHandle: _emptyToNull(_fluxerController),
          signalNumber: _emptyToNull(_signalController),
          whatsappNumber: _emptyToNull(_whatsappController),
          matrixUser: _emptyToNull(_matrixUserController),
          matrixHomeserver: _emptyToNull(_matrixServerController),
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
      showCupertinoDialog<void>(
        context: context,
        builder: (_) => const CupertinoAlertDialog(
          content: Text('Kontaktdaten gespeichert'),
        ),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message ?? 'Fehler beim Speichern.');
    } catch (e, st) {
      developer.log('Failed to save contact info', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _error = 'Netzwerkfehler. Bitte prufe deine Verbindung.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _emptyToNull(TextEditingController c) {
    final v = c.text.trim();
    return v.isEmpty ? null : v;
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    if (_loading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Kontaktmoglichkeiten'),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSimpleField(
                icon: CupertinoIcons.chat_bubble_2_fill,
                label: 'Discord',
                controller: _discordController,
                hint: 'Benutzername',
                visibility: _discordVisibility,
                onVisibilityChanged: (v) =>
                    setState(() => _discordVisibility = v),
              ),
              const SizedBox(height: 16),
              _buildSimpleField(
                icon: CupertinoIcons.at_circle_fill,
                label: 'Fluxer',
                controller: _fluxerController,
                hint: 'Benutzername',
                visibility: _fluxerVisibility,
                onVisibilityChanged: (v) =>
                    setState(() => _fluxerVisibility = v),
              ),
              const SizedBox(height: 16),
              _buildSimpleField(
                icon: CupertinoIcons.phone_fill,
                label: 'Signal',
                controller: _signalController,
                hint: 'username.00',
                visibility: _signalVisibility,
                onVisibilityChanged: (v) =>
                    setState(() => _signalVisibility = v),
              ),
              const SizedBox(height: 16),
              _buildSimpleField(
                icon: CupertinoIcons.phone_fill,
                label: 'WhatsApp',
                controller: _whatsappController,
                hint: '+49123456789',
                visibility: _whatsappVisibility,
                onVisibilityChanged: (v) =>
                    setState(() => _whatsappVisibility = v),
              ),
              const SizedBox(height: 16),
              _buildMatrixField(),
              const SizedBox(height: 24),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      fontSize: 15,
                      color: CupertinoColors.destructiveRed,
                    ),
                  ),
                ),
              CupertinoButton.filled(
                onPressed: _saving ? null : _save,
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: _saving
                    ? const CupertinoActivityIndicator(
                        color: CupertinoColors.white,
                      )
                    : const Text('Speichern'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required String hint,
    required int visibility,
    required ValueChanged<int> onVisibilityChanged,
  }) {
    final theme = CupertinoTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.textStyle.color,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, size: 18, color: theme.primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: CupertinoTextField(
                controller: controller,
                placeholder: hint,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
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

  Widget _buildMatrixField() {
    final theme = CupertinoTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(CupertinoIcons.chat_bubble_fill, size: 18, color: theme.primaryColor),
            const SizedBox(width: 8),
            Text(
              'Matrix',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.textStyle.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const SizedBox(width: 26),
            Expanded(
              child: CupertinoTextField(
                controller: _matrixUserController,
                placeholder: 'Benutzername',
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                textCapitalization: TextCapitalization.none,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CupertinoTextField(
                controller: _matrixServerController,
                placeholder: 'matrix.org',
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                textCapitalization: TextCapitalization.none,
              ),
            ),
            const SizedBox(width: 8),
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
