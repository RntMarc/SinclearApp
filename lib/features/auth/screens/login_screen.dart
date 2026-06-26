import 'dart:developer' as developer;
import 'package:flutter/cupertino.dart';
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
      developer.log(
        'Login request failed: ${e.errorCode}',
        name: 'auth.login',
        error: e,
      );
      setState(() {
        _error = switch (e.errorCode) {
          'user_not_found' => 'Kein Nutzer mit dieser E-Mail gefunden.',
          'too_many_requests' ||
          'too_many_attempts' => 'Zu viele Anfragen. Bitte warte einen Moment.',
          'invalid_email' => 'Ungültige E-Mail-Adresse.',
          _ => 'Ein Fehler ist aufgetreten. Bitte versuche es später erneut.',
        };
      });
    } catch (e, st) {
      developer.log('Failed to send OTP', error: e, stackTrace: st);
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
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        setState(() => _error = 'Konnte den Browser nicht öffnen.');
        return;
      }
      if (!mounted) return;
      context.go('/login/verify', extra: {'method': 'discord'});
    } on ApiException catch (e) {
      developer.log(
        'Discord login failed: ${e.errorCode}',
        name: 'auth.discord',
        error: e,
      );
      setState(() {
        _error = switch (e.errorCode) {
          'too_many_attempts' => 'Zu viele Anfragen. Bitte warte einen Moment.',
          _ => 'Ein Fehler ist aufgetreten. Bitte versuche es später erneut.',
        };
      });
    } catch (e, st) {
      developer.log('Failed to start Discord login', error: e, stackTrace: st);
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
        middle: const Text('Anmelden'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.go('/'),
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
                  Text(
                    'E-Mail-Login',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.textStyle.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Wir senden dir einen Code per E-Mail.',
                    style: TextStyle(
                      fontSize: 15,
                      color: theme.textTheme.textStyle.color?.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CupertinoTextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    placeholder: 'E-Mail-Adresse',
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
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          fontSize: 15,
                          color: CupertinoColors.destructiveRed,
                        ),
                      ),
                    ),
                  CupertinoButton.filled(
                    onPressed: _loading ? null : _sendOtp,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: _loading
                        ? const CupertinoActivityIndicator(
                            color: CupertinoColors.white,
                          )
                        : const Text('Code senden'),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      const Expanded(child: SizedBox(height: 1, child: DecoratedBox(decoration: BoxDecoration(color: CupertinoColors.systemGrey4)))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'oder',
                          style: TextStyle(
                            fontSize: 15,
                            color: theme.textTheme.textStyle.color
                                ?.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      const Expanded(child: SizedBox(height: 1, child: DecoratedBox(decoration: BoxDecoration(color: CupertinoColors.systemGrey4)))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CupertinoButton(
                    onPressed: _loading ? null : _discordLogin,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    color: CupertinoColors.systemGrey5,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          CupertinoIcons.headphones,
                          size: 20,
                          color: CupertinoColors.black,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Mit Discord anmelden',
                          style: TextStyle(
                            color: CupertinoTheme.of(context)
                                .textTheme
                                .textStyle
                                .color,
                          ),
                        ),
                      ],
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
