import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/network/api_client.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../../design/widgets/primitives/design_text_field.dart';

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
    final tokens = DesignTheme.of(context);

    return DesignSurface(
      child: Column(
        children: [
          DesignSubpageHeader(
            leading: DesignIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => context.pop(),
            ),
            title: 'E-Mail ändern',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(tokens.spaceLg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      _stepRequest ? Icons.email_rounded : Icons.vpn_key_rounded,
                      size: 56,
                      color: tokens.primary,
                    ),
                    SizedBox(height: tokens.spaceLg),
                    DesignText(
                      _stepRequest ? 'Neue E-Mail-Adresse' : 'Code bestätigen',
                      style: DesignTextStyle.title,
                    ),
                    SizedBox(height: tokens.spaceSm),
                    DesignText(
                      _stepRequest
                          ? 'Wir senden einen Bestätigungscode an die neue Adresse.'
                          : 'Gib den 6-stelligen Code ein, den wir an ${_emailController.text.trim()} gesendet haben.',
                      color: tokens.textLow,
                    ),
                    SizedBox(height: tokens.spaceLg),
                    if (_stepRequest)
                      DesignTextField(
                        controller: _emailController,
                        hint: 'Neue E-Mail',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_rounded,
                      )
                    else
                      DesignTextField(
                        controller: _codeController,
                        hint: '6-stelliger Code',
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 6,
                        prefixIcon: Icons.vpn_key_rounded,
                      ),
                    SizedBox(height: tokens.spaceLg),
                    if (_error != null)
                      Padding(
                        padding: EdgeInsets.only(bottom: tokens.spaceMd),
                        child: DesignText(_error!, color: tokens.danger),
                      ),
                    if (_stepRequest) ...[
                      DesignButton(
                        label: _loading ? 'Wird gesendet…' : 'Code senden',
                        icon: Icons.send_rounded,
                        loading: _loading,
                        onPressed: _loading ? null : _requestCode,
                        fullWidth: true,
                      ),
                      SizedBox(height: tokens.spaceSm),
                      DesignButton(
                        label: 'Abbrechen',
                        variant: DesignButtonVariant.text,
                        onPressed: () => Navigator.pop(context),
                        fullWidth: true,
                      ),
                    ] else ...[
                      DesignButton(
                        label: _loading ? 'Wird geprüft…' : 'Bestätigen',
                        icon: Icons.check_rounded,
                        loading: _loading,
                        onPressed: _loading ? null : _verifyCode,
                        fullWidth: true,
                      ),
                      SizedBox(height: tokens.spaceSm),
                      DesignButton(
                        label: 'Andere E-Mail verwenden',
                        variant: DesignButtonVariant.text,
                        onPressed: () {
                          setState(() {
                            _stepRequest = true;
                            _error = null;
                            _codeController.clear();
                          });
                        },
                        fullWidth: true,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
