import 'dart:developer' as developer;
import 'package:flutter/material.dart';
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
      setState(() => _error = 'Bitte gib eine gültige E-Mail-Adresse ein.');
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
          'invalid_email' => 'Ungültiges E-Mail-Format.',
          'too_many_requests' => 'Zu viele Anfragen. Bitte warte einen Moment.',
          _ => e.message ?? 'Ein Fehler ist aufgetreten.',
        };
      });
    } catch (e, st) {
      developer.log('Failed to request email change', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _error = 'Netzwerkfehler. Bitte prüfe deine Verbindung.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6 || !RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _error = 'Bitte gib einen gültigen 6-stelligen Code ein.');
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('E-Mail geändert. Bitte melde dich neu an.'),
        ),
      );
      context.go('/');
    } on ApiException catch (e) {
      setState(() {
        _error = switch (e.errorCode) {
          'invalid_or_expired_code' => 'Der Code ist ungültig oder abgelaufen.',
          'invalid_code' => 'Ungültiger Code.',
          _ => e.message ?? 'Ein Fehler ist aufgetreten.',
        };
      });
    } catch (e, st) {
      developer.log('Failed to verify email change', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _error = 'Netzwerkfehler. Bitte prüfe deine Verbindung.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('E-Mail ändern')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  _stepRequest ? Icons.email_rounded : Icons.vpn_key_rounded,
                  size: 56,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  _stepRequest ? 'Neue E-Mail-Adresse' : 'Code bestätigen',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  _stepRequest
                      ? 'Wir senden einen Bestätigungscode an die neue Adresse.'
                      : 'Gib den 6-stelligen Code ein, den wir an ${_emailController.text.trim()} gesendet haben.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                if (_stepRequest)
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Neue E-Mail',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_rounded),
                    ),
                  )
                else
                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: '6-stelliger Code',
                      counterText: '',
                      prefixIcon: Icon(Icons.vpn_key_rounded),
                      border: OutlineInputBorder(),
                    ),
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
                if (_stepRequest) ...[
                  FilledButton.icon(
                    onPressed: _loading ? null : _requestCode,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(_loading ? 'Wird gesendet…' : 'Code senden'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Abbrechen'),
                  ),
                ] else ...[
                  FilledButton.icon(
                    onPressed: _loading ? null : _verifyCode,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(_loading ? 'Wird geprüft…' : 'Bestätigen'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
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
