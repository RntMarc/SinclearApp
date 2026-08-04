import 'package:flutter/material.dart';
import '../design_variant.dart';
import 'app_design.dart';
import '../tokens/design_tokens.dart';

export '../tokens/design_tokens.dart';

/// Provides the active [DesignVariant], resolved [DesignTokens], grain overlay
/// intensity and theme mode to the widget catalog. Changing any notifier
/// rebuilds every catalog widget that depends on it.
///
/// The scope is mounted once, near the app root (see [SinclearApp]), so the
/// selections survive navigation within a session. It intentionally does not
/// touch the rest of the app, which keeps using Material 3.
class DesignScope extends StatefulWidget {
  const DesignScope({
    required this.variant,
    this.grain,
    this.themeMode,
    required this.child,
    super.key,
  });

  /// In-memory notifier holding the currently selected design variant.
  final ValueNotifier<DesignVariant> variant;

  /// In-memory notifier holding the grain intensity as a fraction (0..1).
  /// The actual overlay opacity is `value * tokens.grainOpacity`.
  /// Defaults to a fixed `0.0` (off) when omitted.
  final ValueNotifier<double>? grain;

  /// In-memory notifier holding the chosen [ThemeMode].
  /// Defaults to [ThemeMode.system] when omitted.
  final ValueNotifier<ThemeMode>? themeMode;

  /// The widget tree that should consume the active design.
  final Widget child;

  /// The active variant (call inside build / from descendants).
  static DesignVariant variantOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_DesignInherited>()!
        .variant;
  }

  /// The grain intensity fraction (0..1). Multiply by
  /// `tokens.grainOpacity` for the real overlay alpha.
  static double grainOpacityOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_DesignInherited>()!
        .grainOpacity;
  }

  /// The underlying grain notifier, so controls (e.g. the settings slider)
  /// can update the intensity.
  static ValueNotifier<double> grainNotifierOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_DesignInherited>()!
        .grain;
  }

  /// The active theme mode (system / light / dark).
  static ThemeMode themeModeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_DesignInherited>()!
        .themeMode;
  }

  /// The underlying theme mode notifier, so controls (e.g. the segmented
  /// switch in settings) can change the mode.
  static ValueNotifier<ThemeMode> themeModeNotifierOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_DesignInherited>()!
        .themeModeNotifier;
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
  late ValueNotifier<double> _grain;
  late ValueNotifier<ThemeMode> _themeMode;

  @override
  void initState() {
    super.initState();
    _grain = widget.grain ?? ValueNotifier<double>(0.0);
    _themeMode = widget.themeMode ?? ValueNotifier<ThemeMode>(ThemeMode.system);
    widget.variant.addListener(_onChanged);
    _grain.addListener(_onChanged);
    _themeMode.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(covariant DesignScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.variant != widget.variant) {
      oldWidget.variant.removeListener(_onChanged);
      widget.variant.addListener(_onChanged);
    }
    if (oldWidget.grain != widget.grain) {
      _grain.removeListener(_onChanged);
      _grain = widget.grain ?? ValueNotifier<double>(0.0);
      _grain.addListener(_onChanged);
    }
    if (oldWidget.themeMode != widget.themeMode) {
      _themeMode.removeListener(_onChanged);
      _themeMode = widget.themeMode ??
          ValueNotifier<ThemeMode>(ThemeMode.system);
      _themeMode.addListener(_onChanged);
    }
    _onChanged();
  }

  @override
  void dispose() {
    widget.variant.removeListener(_onChanged);
    _grain.removeListener(_onChanged);
    _themeMode.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return _DesignInherited(
      variant: widget.variant.value,
      notifier: widget.variant,
      grainOpacity: _grain.value,
      grain: _grain,
      themeMode: _themeMode.value,
      themeModeNotifier: _themeMode,
      child: widget.child,
    );
  }
}

class _DesignInherited extends InheritedWidget {
  const _DesignInherited({
    required this.variant,
    required this.notifier,
    required this.grainOpacity,
    required this.grain,
    required this.themeMode,
    required this.themeModeNotifier,
    required super.child,
  });

  final DesignVariant variant;
  final ValueNotifier<DesignVariant> notifier;
  final double grainOpacity;
  final ValueNotifier<double> grain;
  final ThemeMode themeMode;
  final ValueNotifier<ThemeMode> themeModeNotifier;

  @override
  bool updateShouldNotify(covariant _DesignInherited old) =>
      old.variant != variant ||
      old.grainOpacity != grainOpacity ||
      old.themeMode != themeMode;
}

/// Convenience alias. Catalog widgets read the active design via
/// `DesignTheme.of(context)`; the scope is mounted as [DesignScope].
typedef DesignTheme = DesignScope;
