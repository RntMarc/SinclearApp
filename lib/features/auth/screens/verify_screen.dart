import 'dart:developer' as developer;
import 'package:flutter/material.dart';
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Erfolgreich angemeldet!')));
      context.go('/home');
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
          'too_many_requests' || 'too_many_attempts' =>
            'Zu viele Versuche. Bitte warte einen Moment.',
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Code eingeben'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
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
                        ? Icons.headset_mic_rounded
                        : Icons.email_rounded,
                    size: 56,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text('Code bestätigen', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    _descriptionText,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
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
                    onPressed: _loading ? null : _verify,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
