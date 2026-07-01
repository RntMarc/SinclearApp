import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/network/api_client.dart';
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
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasDiscord = _user?.base.discordId != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discord-Verknüpfung'),
        titleTextStyle: theme.textTheme.titleMedium,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.headset_mic_rounded,
                  size: 56,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  hasDiscord ? 'Discord verbunden' : 'Kein Discord verknüpft',
                   style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  hasDiscord
                      ? 'Dein Account ist mit Discord-ID ${_user!.base.discordId} verknüpft.'
                      : 'Verknüpfe deinen Discord-Account, um dich schneller anmelden zu können.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                if (!_showCodeInput) ...[
                  FilledButton.icon(
                    onPressed: _saving ? null : _startRelink,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.open_in_browser_rounded),
                    label: Text(
                      _saving
                          ? 'Wird gestartet…'
                          : 'Discord-Verknüpfung ändern',
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ] else ...[
                  Text(
                    'Gib den 6-stelligen Code aus dem Discord-Browser-Tab ein.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'Pairing-Code',
                      counterText: '',
                      prefixIcon: Icon(Icons.vpn_key_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                    onPressed: _saving ? null : _verifyCode,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(_saving ? 'Wird geprüft…' : 'Bestätigen'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showCodeInput = false;
                        _error = null;
                        _codeController.clear();
                      });
                    },
                    child: const Text('Abbrechen'),
                  ),
                ],
                if (_error != null && !_showCodeInput)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      _error!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
