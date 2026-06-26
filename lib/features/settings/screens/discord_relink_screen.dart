import 'dart:developer' as developer;
import 'package:flutter/cupertino.dart';
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
        setState(() => _error = 'Discord konnte nicht geoffnet werden.');
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
        _error = 'Fehler beim Starten der Discord-Verknupfung.';
      });
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6 || !RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _error = 'Bitte gib einen gultigen 6-stelligen Code ein.');
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
      showCupertinoDialog<void>(
        context: context,
        builder: (_) => const CupertinoAlertDialog(
          content: Text('Discord-Verknupfung aktualisiert'),
        ),
      );
    } on ApiException catch (e) {
      setState(() {
        _error = switch (e.errorCode) {
          'invalid_or_expired_code' => 'Der Code ist ungultig oder abgelaufen.',
          _ => e.message ?? 'Ein Fehler ist aufgetreten.',
        };
      });
    } catch (e, st) {
      developer.log('Failed to verify discord code', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _error = 'Netzwerkfehler. Bitte prufe deine Verbindung.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    if (_loading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    final hasDiscord = _user?.base.discordId != null;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Discord-Verknupfung'),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  CupertinoIcons.headphones,
                  size: 56,
                  color: theme.primaryColor,
                ),
                const SizedBox(height: 24),
                Text(
                  hasDiscord ? 'Discord verbunden' : 'Kein Discord verknupft',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.textStyle.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hasDiscord
                      ? 'Dein Account ist mit Discord-ID ${_user!.base.discordId} verknupft.'
                      : 'Verknupfe deinen Discord-Account, um dich schneller anmelden zu konnen.',
                  style: TextStyle(
                    fontSize: 15,
                    color: theme.textTheme.textStyle.color
                        ?.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 32),
                if (!_showCodeInput) ...[
                  CupertinoButton.filled(
                    onPressed: _saving ? null : _startRelink,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: _saving
                        ? const CupertinoActivityIndicator(
                            color: CupertinoColors.white,
                          )
                        : const Text('Discord-Verknupfung andern'),
                  ),
                ] else ...[
                  Text(
                    'Gib den 6-stelligen Code aus dem Discord-Browser-Tab ein.',
                    style: TextStyle(
                      fontSize: 15,
                      color: theme.textTheme.textStyle.color
                          ?.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CupertinoTextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    placeholder: 'Pairing-Code',
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Icon(CupertinoIcons.lock, size: 20),
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
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
                    onPressed: _saving ? null : _verifyCode,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: _saving
                        ? const CupertinoActivityIndicator(
                            color: CupertinoColors.white,
                          )
                        : const Text('Bestatigen'),
                  ),
                  const SizedBox(height: 12),
                  CupertinoButton(
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
                      style: const TextStyle(
                        fontSize: 15,
                        color: CupertinoColors.destructiveRed,
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
