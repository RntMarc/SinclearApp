import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../../design/theme/design_theme.dart';
import '../../design/widgets/foundation/design_text.dart';
import '../../design/widgets/primitives/design_button.dart';
import '../../design/widgets/primitives/design_card.dart';

/// Renders one independently loaded section of a screen.
///
/// A section receives a memoized [future] and renders one of three states: a
/// skeleton placeholder while loading, an inline error card with retry when
/// the future fails, or the section content via [builder]. A failing section
/// therefore only replaces itself – the rest of the screen stays intact,
/// which keeps parse or API errors from taking down a whole screen.
///
/// The skeleton only appears after [skeletonDelay], so fast loads show the
/// content directly without flashing a placeholder. It pulses gently while
/// visible and disappears when the data or an error arrives.
///
/// Pass a *new* [future] instance to reload (e.g. after [onRetry] invalidated
/// the memoized loader); identity, not content, is compared, and stale
/// responses from a previous future are ignored. With [keepAlive] the state
/// survives when the parent scrolls the section out of view (TabBarView),
/// avoiding refetches on tab switches.
class AsyncSection<T> extends StatefulWidget {
  const AsyncSection({
    super.key,
    required this.future,
    required this.builder,
    this.onRetry,
    this.skeleton,
    this.keepAlive = false,
    this.skeletonDelay = const Duration(milliseconds: 400),
  });

  /// The future holding this section's data (typically memoized by a
  /// per-screen controller so shared data is fetched only once).
  final Future<T> future;

  /// Builds the section content once [future] completed successfully.
  final Widget Function(BuildContext context, T data) builder;

  /// Invalidates the memoized [future] so a retry produces new data.
  final Future<void> Function()? onRetry;

  /// Loading placeholder; defaults to a neutral card skeleton.
  final Widget? skeleton;

  /// How long to wait before showing the loading [skeleton]. Loads that
  /// finish sooner show their content directly, without a placeholder flash.
  final Duration skeletonDelay;

  /// Whether the section state survives when scrolled out of view.
  final bool keepAlive;

  @override
  State<AsyncSection<T>> createState() => _AsyncSectionState<T>();
}

class _AsyncSectionState<T> extends State<AsyncSection<T>>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  static final _log = Logger('async_section');

  Future<T>? _observed;
  T? _data;
  Object? _error;

  Timer? _skeletonTimer;
  bool _showSkeleton = false;
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  @override
  bool get wantKeepAlive => widget.keepAlive;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulse = Tween<double>(begin: 0.55, end: 1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _observed = widget.future;
    _reload();
  }

  @override
  void didUpdateWidget(covariant AsyncSection<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.future, widget.future)) {
      _observed = widget.future;
      _reload();
    }
  }

  @override
  void dispose() {
    _skeletonTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    _data = null;
    _error = null;
    _hideSkeleton();
    final future = widget.future;
    _skeletonTimer = Timer(widget.skeletonDelay, () {
      if (!mounted || !identical(_observed, future)) return;
      if (_data != null || _error != null) return;
      _pulseController.repeat(reverse: true);
      setState(() => _showSkeleton = true);
    });
    try {
      final data = await future;
      if (!mounted || !identical(_observed, future)) return;
      _hideSkeleton();
      setState(() => _data = data);
    } catch (e, st) {
      _log.warning('Section load failed', e, st);
      if (!mounted || !identical(_observed, future)) return;
      _hideSkeleton();
      setState(() => _error = e);
    }
  }

  void _hideSkeleton() {
    _skeletonTimer?.cancel();
    _skeletonTimer = null;
    _showSkeleton = false;
    if (_pulseController.isAnimating) _pulseController.stop();
    _pulseController.value = 1;
  }

  Future<void> _retry() async {
    final onRetry = widget.onRetry;
    if (onRetry != null) {
      await onRetry();
      return;
    }
    if (!mounted) return;
    setState(() {});
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final error = _error;
    if (error != null) return _ErrorCard(onRetry: _retry);
    final data = _data;
    if (data != null) return widget.builder(context, data);
    if (!_showSkeleton) return const SizedBox.shrink();
    return FadeTransition(
      opacity: _pulse,
      child: widget.skeleton ?? const _SkeletonCard(),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return DesignCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 40, color: tokens.danger),
          SizedBox(height: tokens.spaceSm),
          DesignText(
            'Dieser Abschnitt konnte nicht geladen werden.',
            style: DesignTextStyle.body,
            color: tokens.textHigh,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: tokens.spaceMd),
          DesignButton(
            variant: DesignButtonVariant.outlined,
            label: 'Erneut versuchen',
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    Widget bar(double widthFactor) => FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: 14,
        decoration: BoxDecoration(
          color: tokens.surfaceVariant.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(tokens.radiusSm),
        ),
      ),
    );

    return DesignCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bar(1),
          SizedBox(height: tokens.spaceSm),
          bar(0.85),
          SizedBox(height: tokens.spaceSm),
          bar(0.6),
        ],
      ),
    );
  }
}
