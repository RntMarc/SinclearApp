import 'package:flutter/material.dart';

import '../primitives/beyond_surface.dart';

/// Scaffold that paints the brand surface (glow + optional grain) behind its
/// body and defers the app bar to [BeyondAppBar]. Grain is applied globally in
/// [SinclearApp]; keep [grain] false here to avoid double grain.
class BeyondScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? floatingActionButton;
  final bool brandGlow;

  const BeyondScaffold({
    super.key,
    this.appBar,
    this.body,
    this.bottomNavigationBar,
    this.drawer,
    this.floatingActionButton,
    this.brandGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: appBar,
      drawer: drawer,
      body: BeyondSurface(
        grain: false,
        brandGlow: brandGlow,
        child: body ?? const SizedBox.shrink(),
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
