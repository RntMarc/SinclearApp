import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design/theme/design_theme.dart';
import '../../design/widgets/foundation/design_surface.dart';
import '../../design/widgets/foundation/design_text.dart';
import '../../design/widgets/primitives/design_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return DesignSurface(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spaceXl,
              vertical: tokens.spaceXxl,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image.asset('assets/logo.png', width: 96, height: 96),
                SizedBox(height: tokens.spaceMd),
                DesignText(
                  'Sinclear Beyond',
                  style: DesignTextStyle.display,
                  color: tokens.primary,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: tokens.spaceXs),
                DesignText(
                  'Gemeinsam sind wir Sinclear.',
                  style: DesignTextStyle.subtitle,
                  color: tokens.textLow,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: tokens.spaceXl),
                DesignText(
                  'Chats, Kalender, Geburtstage, Kontakte – '
                  'alles was eine Gruppe zum Überleben braucht. '
                  'An einem Ort.',
                  style: DesignTextStyle.body,
                  color: tokens.textLow,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: tokens.spaceXxl),
                Center(
                  child: SizedBox(
                    width: 240,
                    child: DesignButton(
                      label: 'Zum Login',
                      icon: Icons.login_rounded,
                      fullWidth: true,
                      onPressed: () => context.go('/login'),
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
