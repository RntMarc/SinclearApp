import 'dart:developer' as developer;
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/network/api_client.dart';

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  String? get _method => GoRouterState.of(context).extra is Map
      ? (GoRouterState.of(context).extra as Map)['method'] as String?
      : null;

  String? get _email => GoRouterState.of(context).extra is Map
      ? (GoRouterState.of(context).extra as Map)['email'] as String?
      : null;

  String get _descriptionText {
    if (_method == 'discord') {
      return 'Gib den Pairing-Code aus deinem Discord-Browser-Tab ein.';
    }
    final email = _email ?? '';
    return 'Wir haben einen Code an $email gesendet.';
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length != 6 || !RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _error = 'Bitte gib einen gültigen 6-stelligen Code ein.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = AppScope.of(context).auth;
      await auth.verifyCode(
        email: _method == 'email' ? _email : null,
        code: code,
      );
      if (!mounted) return;
      showCupertinoDialog<void>(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          content: const Text('Erfolgreich angemeldet!'),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.pop(context);
                context.go('/home');
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } on ApiException catch (e) {
      developer.log(
        'Code verification failed: ${e.errorCode}',
        name: 'auth.verify',
        error: e,
      );
      setState(() {
        _error = switch (e.errorCode) {
          'invalid_or_expired_code' => 'Der Code ist ungültig oder abgelaufen.',
          'invalid_code' => 'Ungültiger Code.',
          'user_not_found' => 'Nutzer nicht gefunden.',
          'too_many_requests' ||
          'too_many_attempts' => 'Zu viele Versuche. Bitte warte einen Moment.',
          _ => 'Ein Fehler ist aufgetreten.',
        };
      });
    } catch (e, st) {
      developer.log('Failed to verify code', error: e, stackTrace: st);
      setState(() => _error = 'Netzwerkfehler. Bitte prüfe deine Verbindung.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Code eingeben'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.go('/login'),
          child: const Icon(CupertinoIcons.back, size: 22),
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    _method == 'discord'
                        ? CupertinoIcons.headphones
                        : CupertinoIcons.mail,
                    size: 56,
                    color: theme.primaryColor,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Code bestätigen',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.textStyle.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _descriptionText,
                    style: TextStyle(
                      fontSize: 15,
                      color: theme.textTheme.textStyle.color?.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  CupertinoTextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    placeholder: '6-stelliger Code',
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
                    onPressed: _loading ? null : _verify,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: _loading
                        ? const CupertinoActivityIndicator(
                            color: CupertinoColors.white,
                          )
                        : const Text('Bestätigen'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
