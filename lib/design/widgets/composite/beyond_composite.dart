import 'package:flutter/material.dart';

import '../../effects/beyond_glass.dart';
import '../../theme/beyond_theme.dart';
import '../../tokens/beyond_tokens.dart';
import '../components/beyond_button.dart';
import '../components/beyond_text.dart';

/// A titled content group with optional trailing control.
class BeyondSection extends StatelessWidget {
  final String? title;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const BeyondSection({
    super.key,
    this.title,
    this.trailing,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.beyond;
    return Padding(
      padding: padding ??
          EdgeInsets.symmetric(
            horizontal: tokens.spacing.lg,
            vertical: tokens.spacing.md,
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (title != null || trailing != null)
            Padding(
              padding: EdgeInsets.only(bottom: tokens.spacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  if (title != null) BeyondHeadline(title!),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          child,
        ],
      ),
    );
  }
}

/// Centered placeholder for empty lists / dashboards.
class BeyondEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final Widget? action;

  const BeyondEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.beyond;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(tokens.spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: BeyondBrand.signature,
              ),
              child: Icon(icon, size: 32, color: Colors.white),
            ),
            SizedBox(height: tokens.spacing.md),
            BeyondHeadline(title),
            if (description != null) ...<Widget>[
              SizedBox(height: tokens.spacing.xs),
              BeyondBody(description!, textAlign: TextAlign.center),
            ],
            if (action != null) ...<Widget>[
              SizedBox(height: tokens.spacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class BeyondLoader extends StatelessWidget {
  final double size;

  const BeyondLoader({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
}

/// Glass alert dialog.
class BeyondDialog {
  const BeyondDialog._();

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmLabel,
    String? cancelLabel,
    VoidCallback? onConfirm,
  }) {
    final tokens = context.beyond;

    return showDialog<T>(
      context: context,
      barrierColor: tokens.color.scrim,
      builder: (_) => BeyondGlass(
        borderRadius: BorderRadius.circular(tokens.radius.lg),
        padding: EdgeInsets.all(tokens.spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            BeyondTitle(title),
            SizedBox(height: tokens.spacing.sm),
            BeyondBody(message),
            SizedBox(height: tokens.spacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                if (cancelLabel != null)
                  BeyondButton(
                    label: cancelLabel,
                    variant: BeyondButtonVariant.ghost,
                    onPressed: () => Navigator.pop(context),
                  ),
                if (confirmLabel != null) ...<Widget>[
                  SizedBox(width: tokens.spacing.sm),
                  BeyondButton(
                    label: confirmLabel,
                    onPressed: () {
                      Navigator.pop(context);
                      onConfirm?.call();
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
