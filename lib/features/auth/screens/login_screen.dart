import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/network/api_client.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Bitte gib deine E-Mail-Adresse ein.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = AppScope.of(context).auth;
      await auth.requestOtp(email);
      if (!mounted) return;
      context.go('/login/verify', extra: {'method': 'email', 'email': email});
    } on ApiException catch (e) {
      setState(() {
        _error = switch (e.errorCode) {
          'user_not_found' => 'Kein Nutzer mit dieser E-Mail gefunden.',
          'too_many_requests' => 'Zu viele Anfragen. Bitte warte einen Moment.',
          'invalid_email' => 'Ungültige E-Mail-Adresse.',
          _ => 'Ein Fehler ist aufgetreten. Bitte versuche es später erneut.',
        };
      });
    } catch (_) {
      setState(() => _error = 'Netzwerkfehler. Bitte prüfe deine Verbindung.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _discordLogin() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = AppScope.of(context).auth;
      final response = await auth.discordStart();
      final uri = Uri.parse(response.url);
      if (!mounted) return;
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        setState(() => _error = 'Konnte den Browser nicht öffnen.');
        return;
      }
      if (!mounted) return;
      context.go('/login/verify', extra: {'method': 'discord'});
    } on ApiException catch (e) {
      setState(() {
        _error = switch (e.errorCode) {
          _ => 'Ein Fehler ist aufgetreten. Bitte versuche es später erneut.',
        };
      });
    } catch (_) {
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
        title: const Text('Anmelden'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/'),
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
                  Text(
                    'E-Mail-Login',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Wir senden dir einen Code per E-Mail.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textCapitalization: TextCapitalization.none,
                    decoration: const InputDecoration(
                      labelText: 'E-Mail-Adresse',
                      prefixIcon: Icon(Icons.email_rounded),
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
                    onPressed: _loading ? null : _sendOtp,
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
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'oder',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _discordLogin,
                    icon: const Icon(Icons.headset_mic_rounded),
                    label: const Text('Mit Discord anmelden'),
                    style: OutlinedButton.styleFrom(
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
