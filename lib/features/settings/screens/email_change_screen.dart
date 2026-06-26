import 'dart:developer' as developer;
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/network/api_client.dart';

class EmailChangeScreen extends StatefulWidget {
  const EmailChangeScreen({super.key});

  @override
  State<EmailChangeScreen> createState() => _EmailChangeScreenState();
}

class _EmailChangeScreenState extends State<EmailChangeScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();

  bool _stepRequest = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Bitte gib eine gultige E-Mail-Adresse ein.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await AppScope.of(context).user.requestEmailChange(email);
      if (!mounted) return;
      setState(() {
        _stepRequest = false;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = switch (e.errorCode) {
          'email_already_taken' => 'Diese E-Mail wird bereits verwendet.',
          'invalid_email' => 'Ungultiges E-Mail-Format.',
          'too_many_requests' => 'Zu viele Anfragen. Bitte warte einen Moment.',
          _ => e.message ?? 'Ein Fehler ist aufgetreten.',
        };
      });
    } catch (e, st) {
      developer.log('Failed to request email change', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _error = 'Netzwerkfehler. Bitte prufe deine Verbindung.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6 || !RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _error = 'Bitte gib einen gultigen 6-stelligen Code ein.');
      return;
    }

    final email = _emailController.text.trim();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final scope = AppScope.of(context);
      await scope.user.verifyEmailChange(code, email);
      await scope.auth.logout();
      if (!mounted) return;
      showCupertinoDialog<void>(
        context: context,
        builder: (_) => const CupertinoAlertDialog(
          content: Text('E-Mail geandert. Bitte melde dich neu an.'),
        ),
      );
      context.go('/');
    } on ApiException catch (e) {
      setState(() {
        _error = switch (e.errorCode) {
          'invalid_or_expired_code' => 'Der Code ist ungultig oder abgelaufen.',
          'invalid_code' => 'Ungultiger Code.',
          _ => e.message ?? 'Ein Fehler ist aufgetreten.',
        };
      });
    } catch (e, st) {
      developer.log('Failed to verify email change', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _error = 'Netzwerkfehler. Bitte prufe deine Verbindung.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('E-Mail andern'),
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
                  _stepRequest
                      ? CupertinoIcons.mail
                      : CupertinoIcons.lock,
                  size: 56,
                  color: theme.primaryColor,
                ),
                const SizedBox(height: 24),
                Text(
                  _stepRequest ? 'Neue E-Mail-Adresse' : 'Code bestatigen',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.textStyle.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _stepRequest
                      ? 'Wir senden einen Bestatigungscode an die neue Adresse.'
                      : 'Gib den 6-stelligen Code ein, den wir an ${_emailController.text.trim()} gesendet haben.',
                  style: TextStyle(
                    fontSize: 15,
                    color: theme.textTheme.textStyle.color
                        ?.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 24),
                if (_stepRequest)
                  CupertinoTextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    placeholder: 'Neue E-Mail',
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Icon(CupertinoIcons.mail, size: 20),
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  )
                else
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
                if (_stepRequest) ...[
                  CupertinoButton.filled(
                    onPressed: _loading ? null : _requestCode,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: _loading
                        ? const CupertinoActivityIndicator(
                            color: CupertinoColors.white,
                          )
                        : const Text('Code senden'),
                  ),
                  const SizedBox(height: 12),
                  CupertinoButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Abbrechen'),
                  ),
                ] else ...[
                  CupertinoButton.filled(
                    onPressed: _loading ? null : _verifyCode,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: _loading
                        ? const CupertinoActivityIndicator(
                            color: CupertinoColors.white,
                          )
                        : const Text('Bestatigen'),
                  ),
                  const SizedBox(height: 12),
                  CupertinoButton(
                    onPressed: () {
                      setState(() {
                        _stepRequest = true;
                        _error = null;
                        _codeController.clear();
                      });
                    },
                    child: const Text('Andere E-Mail verwenden'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
