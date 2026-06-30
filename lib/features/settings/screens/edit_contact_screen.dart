import 'dart:developer' as developer;
import 'package:flutter/material.dart';
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

  String? _emptyToNull(TextEditingController c) {
    final v = c.text.trim();
    return v.isEmpty ? null : v;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('KONTAKTMÖGLICHKEITEN')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSimpleField(
                icon: Icons.chat_rounded,
                label: 'Discord',
                controller: _discordController,
                hint: 'Benutzername',
                visibility: _discordVisibility,
                onVisibilityChanged: (v) =>
                    setState(() => _discordVisibility = v),
              ),
              const SizedBox(height: 16),
              _buildSimpleField(
                icon: Icons.alternate_email_rounded,
                label: 'Fluxer',
                controller: _fluxerController,
                hint: 'Benutzername',
                visibility: _fluxerVisibility,
                onVisibilityChanged: (v) =>
                    setState(() => _fluxerVisibility = v),
              ),
              const SizedBox(height: 16),
              _buildSimpleField(
                icon: Icons.phone_rounded,
                label: 'Signal',
                controller: _signalController,
                hint: 'username.00',
                visibility: _signalVisibility,
                onVisibilityChanged: (v) =>
                    setState(() => _signalVisibility = v),
              ),
              const SizedBox(height: 16),
              _buildSimpleField(
                icon: Icons.phone_android_rounded,
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

  Widget _buildSimpleField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required String hint,
    required int visibility,
    required ValueChanged<int> onVisibilityChanged,
  }) {
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

  Widget _buildMatrixField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.forum_rounded,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Matrix',
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
                controller: _matrixUserController,
                decoration: const InputDecoration(
                  labelText: 'Benutzername',
                  hintText: 'Benutzername',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
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
                controller: _matrixServerController,
                decoration: const InputDecoration(
                  labelText: 'Homeserver',
                  hintText: 'matrix.org',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
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
