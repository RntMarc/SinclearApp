import 'package:flutter/material.dart';
import '../../theme/design_theme.dart';
import '../foundation/design_text.dart';
import '../primitives/design_card.dart';
import '../primitives/press_scale.dart';

/// A compact card optimized for dashboard grids.
///
/// Displays a [title] at the top, an optional [period] line in the middle,
/// and a prominent [amount] at the bottom. The [amountColor] tints the
/// amount text (e.g. red for unpaid, green for paid).
///
/// Builds on [DesignCard] so it inherits the active design tokens for
/// surface, glass, shadow and radius.
class DesignGridCard extends StatelessWidget {
  const DesignGridCard({
    required this.title,
    this.period,
    required this.amount,
    this.amountColor,
    this.onTap,
    super.key,
  });

  final String title;
  final String? period;
  final String amount;
  final Color? amountColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    return PressScale(
      onTap: onTap,
      child: DesignCard(
        margin: EdgeInsets.zero,
        useGlass: tokens.useGlass,
        child: Padding(
          padding: EdgeInsets.all(tokens.spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DesignText(
                    title,
                    style: DesignTextStyle.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (period != null) ...[
                    SizedBox(height: tokens.spaceSm),
                    DesignText(
                      period!,
                      style: DesignTextStyle.label,
                      color: tokens.textLow,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
              DesignText(
                amount,
                style: DesignTextStyle.title,
                color: amountColor ?? tokens.textHigh,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
