import 'package:flutter/material.dart';
import '../../theme/design_theme.dart';
import 'press_scale.dart';

/// Floating action button from the design system.
///
/// A filled primary circle with a glow shadow and springy press feedback,
/// following the reference implementation on the Explore screen. The
/// [DesignFabSize.small] variant is used for secondary actions stacked above
/// the main FAB (e.g. a drafts button next to a "create" button).
class DesignFab extends StatelessWidget {
  const DesignFab({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = DesignFabSize.regular,
    this.loading = false,
  });

  /// Icon shown inside the button.
  final IconData icon;

  /// Callback invoked when the button is tapped.
  final VoidCallback onPressed;

  /// Tooltip and accessibility label shown on long-press and hover.
  final String? tooltip;

  /// Size variant; use [DesignFabSize.small] for stacked secondary actions.
  final DesignFabSize size;

  /// Replaces the icon with a spinner and blocks taps while an action runs.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final isSmall = size == DesignFabSize.small;
    final dimension = isSmall ? 40.0 : 56.0;
    final iconSize = isSmall ? 20.0 : 28.0;
    return Material(
      type: MaterialType.transparency,
      child: Tooltip(
        message: tooltip ?? '',
        child: PressScale(
          onTap: loading ? null : onPressed,
          child: Container(
            width: dimension,
            height: dimension,
            decoration: BoxDecoration(
              color: tokens.primary,
              shape: BoxShape.circle,
              boxShadow: tokens.glowShadow,
            ),
            child: loading
                ? Center(
                    child: SizedBox(
                      width: iconSize,
                      height: iconSize,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: tokens.onPrimary,
                      ),
                    ),
                  )
                : Icon(icon, color: tokens.onPrimary, size: iconSize),
          ),
        ),
      ),
    );
  }
}

/// Size variants for [DesignFab].
enum DesignFabSize { regular, small }
