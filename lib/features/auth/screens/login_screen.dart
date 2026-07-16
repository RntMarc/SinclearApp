import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/network/api_client.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_app_bar.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_divider.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../../design/widgets/primitives/design_text_field.dart';

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

  Future<void> _discordRegister() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = AppScope.of(context).auth;
      final response = await auth.registerDiscordStart();
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
      context.go(
        '/login/verify',
        extra: {'method': 'discord_register'},
      );
    } on ApiException catch (e) {
      developer.log(
        'Discord register failed: ${e.errorCode}',
        name: 'auth.discord.register',
        error: e,
      );
      setState(() {
        _error = switch (e.errorCode) {
          'too_many_attempts' => 'Zu viele Anfragen. Bitte warte einen Moment.',
          _ => 'Ein Fehler ist aufgetreten. Bitte versuche es später erneut.',
        };
      });
    } catch (e, st) {
      developer.log(
        'Failed to start Discord register',
        error: e,
        stackTrace: st,
      );
      setState(() => _error = 'Netzwerkfehler. Bitte prüfe deine Verbindung.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return DesignSurface(
      withGrain: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: DesignAppBar(
          leading: DesignIconButton(
            icon: Icons.arrow_back_rounded,
            onPressed: () => context.go('/'),
          ),
          title: 'Anmelden',
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spaceXl,
                vertical: tokens.spaceXl,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    DesignText(
                      'E-Mail-Login',
                      style: DesignTextStyle.subtitle,
                    ),
                    SizedBox(height: tokens.spaceXs),
                    DesignText(
                      'Wir senden dir einen Code per E-Mail.',
                      style: DesignTextStyle.body,
                      color: tokens.textLow,
                    ),
                    SizedBox(height: tokens.spaceLg),
                    DesignTextField(
                      hint: 'E-Mail-Adresse',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: tokens.spaceLg),
                    if (_error != null)
                      Padding(
                        padding: EdgeInsets.only(bottom: tokens.spaceMd),
                        child: DesignText(
                          _error!,
                          style: DesignTextStyle.body,
                          color: tokens.danger,
                        ),
                      ),
                    DesignButton(
                      label: _loading ? 'Wird gesendet…' : 'Code senden',
                      icon: Icons.send_rounded,
                      loading: _loading,
                      fullWidth: true,
                      onPressed: _sendOtp,
                    ),
                    SizedBox(height: tokens.spaceXxl),
                    Row(
                      children: <Widget>[
                        const Expanded(child: DesignDivider()),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: tokens.spaceMd,
                          ),
                          child: DesignText(
                            'oder',
                            style: DesignTextStyle.label,
                            color: tokens.textLow,
                          ),
                        ),
                        const Expanded(child: DesignDivider()),
                      ],
                    ),
                    SizedBox(height: tokens.spaceLg),
                    DesignButton(
                      label: 'Mit Discord anmelden',
                      icon: Icons.headset_mic_rounded,
                      variant: DesignButtonVariant.outlined,
                      fullWidth: true,
                      onPressed: _loading ? null : _discordLogin,
                    ),
                    SizedBox(height: tokens.spaceMd),
                    Center(
                      child: DesignButton(
                        label: 'Noch kein Konto? Registrieren',
                        variant: DesignButtonVariant.text,
                        onPressed: _loading ? null : _discordRegister,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
