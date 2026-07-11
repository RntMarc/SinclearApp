import 'package:flutter/material.dart';

import '../../effects/beyond_glass.dart';
import '../../theme/beyond_theme.dart';

/// Glass bottom sheet. Shows a drag handle, blurs the content behind it and
/// uses the brand radius on the top corners.
class BeyondSheet {
  const BeyondSheet._();

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    bool isScrollControlled = true,
    bool dismissible = true,
  }) {
    final tokens = context.beyond;

    final sheet = BeyondGlass(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(tokens.radius.xl),
      ),
      padding: EdgeInsets.fromLTRB(
        tokens.spacing.lg,
        tokens.spacing.md,
        tokens.spacing.lg,
        MediaQuery.of(context).padding.bottom + tokens.spacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: tokens.color.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: tokens.spacing.md),
          child,
        ],
      ),
    );

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      isDismissible: dismissible,
      builder: (_) => sheet,
    );
  }
}
