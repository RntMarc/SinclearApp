import 'package:flutter/material.dart';
import '../../theme/design_theme.dart';
import '../foundation/design_text.dart';
import '../primitives/design_card.dart';

/// A titled group of samples inside the showcase. Builds on [DesignCard].
class DesignShowcaseSection extends StatelessWidget {
  const DesignShowcaseSection({
    required this.title,
    required this.child,
    this.description,
    super.key,
  });

  final String title;
  final String? description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return DesignCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DesignText(title, style: DesignTextStyle.title, color: tokens.textHigh),
          if (description != null) ...<Widget>[
            SizedBox(height: tokens.spaceXs),
            DesignText(
              description!,
              style: DesignTextStyle.body,
              color: tokens.textLow,
            ),
          ],
          SizedBox(height: tokens.spaceLg),
          child,
        ],
      ),
    );
  }
}
