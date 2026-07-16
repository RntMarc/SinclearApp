import 'package:flutter/material.dart';
import '../design_variant.dart';
import 'app_design.dart';
import '../tokens/design_tokens.dart';

export '../tokens/design_tokens.dart';

/// Provides the active [DesignVariant] and resolved [DesignTokens] to the
/// widget catalog. Switching the [variant] notifier rebuilds every catalog
/// widget that depends on it.
///
/// The scope is mounted once, near the app root (see [SinclearApp]), so the
/// selection survives navigation within a session. It intentionally does not
/// touch the rest of the app, which keeps using Material 3.
class DesignScope extends StatefulWidget {
  const DesignScope({
    required this.variant,
    required this.child,
    super.key,
  });

  /// In-memory notifier holding the currently selected design variant.
  final ValueNotifier<DesignVariant> variant;

  /// The widget tree that should consume the active design.
  final Widget child;

  /// The active variant (call inside build / from descendants).
  static DesignVariant variantOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_DesignInherited>()!
        .variant;
  }

  /// The resolved tokens for the active variant and current brightness.
  static DesignTokens of(BuildContext context) {
    final inherited =
        context.dependOnInheritedWidgetOfExactType<_DesignInherited>()!;
    final brightness = Theme.of(context).brightness;
    return AppDesign.resolve(inherited.variant, brightness);
  }

  /// The underlying notifier, so controls (e.g. the showcase switcher) can
  /// change the active design.
  static ValueNotifier<DesignVariant> notifierOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_DesignInherited>()!
        .notifier;
  }

  @override
  State<DesignScope> createState() => _DesignScopeState();
}

class _DesignScopeState extends State<DesignScope> {
  @override
  void initState() {
    super.initState();
    widget.variant.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(covariant DesignScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.variant != widget.variant) {
      oldWidget.variant.removeListener(_onChanged);
      widget.variant.addListener(_onChanged);
      _onChanged();
    }
  }

  @override
  void dispose() {
    widget.variant.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return _DesignInherited(
      variant: widget.variant.value,
      notifier: widget.variant,
      child: widget.child,
    );
  }
}

class _DesignInherited extends InheritedWidget {
  const _DesignInherited({
    required this.variant,
    required this.notifier,
    required super.child,
  });

  final DesignVariant variant;
  final ValueNotifier<DesignVariant> notifier;

  @override
  bool updateShouldNotify(covariant _DesignInherited old) =>
      old.variant != variant;
}

/// Convenience alias. Catalog widgets read the active design via
/// `DesignTheme.of(context)`; the scope is mounted as [DesignScope].
typedef DesignTheme = DesignScope;
