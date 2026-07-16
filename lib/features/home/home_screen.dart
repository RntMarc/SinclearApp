import 'package:flutter/material.dart';
import '../../design/theme/design_theme.dart';
import '../../design/widgets/foundation/design_surface.dart';
import '../../design/widgets/foundation/design_text.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return DesignSurface(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(tokens.spaceLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.home_rounded, size: 64, color: tokens.primary),
              SizedBox(height: tokens.spaceLg),
              DesignText(
                'Willkommen bei Beyond',
                style: DesignTextStyle.title,
                color: tokens.textHigh,
              ),
              SizedBox(height: tokens.spaceSm),
              DesignText(
                'Hier entsteht in Kürze dein persönliches Dashboard.',
                textAlign: TextAlign.center,
                style: DesignTextStyle.body,
                color: tokens.textLow,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
