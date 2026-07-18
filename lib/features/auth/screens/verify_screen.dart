import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/network/api_client.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_app_bar.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../../design/widgets/primitives/design_text_field.dart';

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
    if (_method == 'discord' || _method == 'discord_register') {
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
      ).showSnackBar(
        SnackBar(
          content: Text(
            _method == 'discord_register'
                ? 'Konto erstellt!'
                : 'Erfolgreich angemeldet!',
          ),
        ),
      );
      final target =
          auth.onboardingCompleted ? '/home' : '/onboarding';
      context.go(target);
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
    final tokens = DesignTheme.of(context);
    return DesignSurface(
      withGrain: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: DesignAppBar(
          leading: DesignIconButton(
            icon: Icons.arrow_back_rounded,
            onPressed: () => context.go('/login'),
          ),
          title: 'Code eingeben',
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
                    Icon(
                      _method == 'discord' || _method == 'discord_register'
                          ? Icons.headset_mic_rounded
                          : Icons.email_rounded,
                      size: 56,
                      color: tokens.primary,
                    ),
                    SizedBox(height: tokens.spaceXl),
                    const DesignText(
                      'Code bestätigen',
                      style: DesignTextStyle.subtitle,
                    ),
                    SizedBox(height: tokens.spaceXs),
                    DesignText(
                      _descriptionText,
                      style: DesignTextStyle.body,
                      color: tokens.textLow,
                    ),
                    SizedBox(height: tokens.spaceXl),
                    DesignTextField(
                      hint: '6-stelliger Code',
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      prefixIcon: Icons.vpn_key_rounded,
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
                      label: _loading ? 'Wird geprüft…' : 'Bestätigen',
                      icon: Icons.check_rounded,
                      loading: _loading,
                      fullWidth: true,
                      onPressed: _verify,
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
