import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design/theme/design_theme.dart';
import '../../design/widgets/composite/design_bottom_sheet.dart';
import '../../design/widgets/foundation/design_text.dart';
import '../../design/widgets/primitives/design_button.dart';
import '../../design/widgets/primitives/design_card.dart';
import '../../design/widgets/primitives/design_icon_button.dart';
import '../../design/widgets/primitives/press_scale.dart';
import 'dashboard_controller.dart';
import 'dashboard_widget.dart';
import 'dashboard_widget_spec.dart';

/// Feste Höhe der Widget-Headerzeile (inkl. Edit-Aktionen).
const double _headerHeight = 52;

/// Feste Höhe einer Inhaltszeile – identisch für Daten, Leer- und Fehlerzustand.
const double _rowHeight = 60;

/// Container eines Dashboard-Widgets.
///
/// Rendert die Karte in fester Höhe (Header + konfigurierte Anzahl Zeilen):
/// Skeleton vor dem ersten Laden, danach Daten/Leerkarte/Fehlerkarte ohne
/// Größen-Sprünge. Zeigt zuerst den persistierten Cache und pflegt frische
/// Daten in-place ein (stale-while-revalidate, kein Flackern).
class DashboardWidgetView extends StatefulWidget {
  const DashboardWidgetView({
    required this.controller,
    required this.spec,
    required this.index,
    required this.total,
    super.key,
  });

  final DashboardController controller;
  final DashboardWidgetSpec spec;
  final int index;
  final int total;

  @override
  State<DashboardWidgetView> createState() => _DashboardWidgetViewState();
}

class _DashboardWidgetViewState extends State<DashboardWidgetView>
    with TickerProviderStateMixin
    implements DashboardRefreshable {
  List<DashboardRow>? _rows;
  Object? _error;
  bool _initialized = false;
  int _lastCount = 0;
  int _refreshEpoch = 0;
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  DashboardWidgetConfig get _config =>
      widget.controller.configFor(widget.spec.type);

  bool get _editing => widget.controller.editing;

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
    widget.controller.register(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _lastCount = _config.count;
      _load();
    }
  }

  @override
  void didUpdateWidget(covariant DashboardWidgetView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final count = _config.count;
    if (count != _lastCount) {
      _lastCount = count;
      refresh();
    }
  }

  @override
  void dispose() {
    widget.controller.unregister(this);
    _pulseController.dispose();
    super.dispose();
  }

  /// Cache anzeigen (falls vorhanden), dann frische Daten holen.
  Future<void> _load() async {
    final cached = await widget.controller.cache.read(widget.spec.type);
    if (!mounted) return;
    if (cached != null && cached.isNotEmpty) {
      setState(() {
        _rows = [for (final json in cached) widget.spec.rowFromJson(json)];
      });
    }
    await refresh();
  }

  @override
  Future<void> refresh() async {
    final epoch = ++_refreshEpoch;
    try {
      final rows = await widget.spec.fetch(_config.count);
      if (!mounted || epoch != _refreshEpoch) return;
      setState(() {
        _rows = rows;
        _error = null;
      });
      await widget.controller.cache.write(widget.spec.type, rows);
    } catch (e) {
      if (!mounted || epoch != _refreshEpoch) return;
      if (_rows == null) {
        setState(() => _error = e);
      }
      // Mit vorhandenen Daten: stale weiter anzeigen, Fehler ist nicht sichtbar.
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _config;
    final editing = _editing;
    final rows = _rows;
    final error = _error;
    final showSkeleton = rows == null && error == null;

    if (!editing &&
        (rows == null || rows.isEmpty) &&
        error == null &&
        config.emptyState == WidgetEmptyState.hide) {
      return const SizedBox.shrink();
    }

    final tokens = DesignTheme.of(context);
    if (showSkeleton && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!showSkeleton && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.value = 1;
    }

    return DesignCard(
      margin: EdgeInsets.symmetric(
        horizontal: tokens.spaceLg,
        vertical: tokens.spaceXs,
      ),
      onTap: editing
          ? _openSettings
          : widget.spec.listRoute.isEmpty
          ? null
          : () => context.go(widget.spec.listRoute),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, tokens, config, editing),
          if (showSkeleton)
            _buildSkeleton(tokens, config.count)
          else if (error != null)
            _buildErrorBox(tokens, config.count)
          else if (rows!.isEmpty)
            _buildEmptyBox(tokens, config.count)
          else
            for (var i = 0; i < config.count; i++)
              SizedBox(
                height: _rowHeight,
                child: i < rows.length
                    ? Center(child: _rowTile(rows[i], editing))
                    : null,
              ),
        ],
      ),
    );
  }

  Widget _rowTile(DashboardRow row, bool editing) {
    final onTap = editing || !widget.spec.rowsTappable
        ? null
        : () => widget.spec.onRowTap(context, row);
    return widget.spec.rowBuilder(context, row, onTap);
  }

  Widget _buildHeader(
    BuildContext context,
    DesignTokens tokens,
    DashboardWidgetConfig config,
    bool editing,
  ) {
    return SizedBox(
      height: _headerHeight,
      child: Row(
        children: [
          if (editing) ...[
            Icon(Icons.drag_indicator_rounded, size: 18, color: tokens.textLow),
            SizedBox(width: tokens.spaceSm),
          ],
          Icon(widget.spec.type.icon, size: 18, color: tokens.primary),
          SizedBox(width: tokens.spaceSm),
          Expanded(
            child: DesignText(
              widget.spec.type.title,
              style: DesignTextStyle.subtitle,
              color: tokens.textHigh,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (editing) ...[
            if (widget.index > 0)
              DesignIconButton(
                icon: Icons.arrow_upward_rounded,
                onPressed: () => widget.controller.moveWidget(
                  widget.index,
                  widget.index - 1,
                ),
              ),
            if (widget.index < widget.total - 1)
              DesignIconButton(
                icon: Icons.arrow_downward_rounded,
                onPressed: () => widget.controller.moveWidget(
                  widget.index,
                  widget.index + 1,
                ),
              ),
            DesignIconButton(
              icon: Icons.close_rounded,
              onPressed: () => widget.controller.removeWidget(widget.index),
            ),
          ] else if (widget.spec.listRoute.isNotEmpty)
            Icon(Icons.chevron_right_rounded, size: 20, color: tokens.textLow),
        ],
      ),
    );
  }

  Widget _buildSkeleton(DesignTokens tokens, int count) {
    return FadeTransition(
      opacity: _pulse,
      child: Column(
        children: [for (var i = 0; i < count; i++) _skeletonRow(tokens)],
      ),
    );
  }

  Widget _skeletonRow(DesignTokens tokens) {
    final barColor = tokens.surfaceVariant.withValues(alpha: 0.8);
    Widget bar(double widthFactor) => FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: 12,
        decoration: BoxDecoration(
          color: barColor,
          borderRadius: BorderRadius.circular(tokens.radiusSm),
        ),
      ),
    );
    return SizedBox(
      height: _rowHeight,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(tokens.radiusMd),
            ),
          ),
          SizedBox(width: tokens.spaceMd),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(0.6),
                SizedBox(height: tokens.spaceXs),
                bar(0.35),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBox(DesignTokens tokens, int count) {
    return SizedBox(
      height: count * _rowHeight,
      child: Center(
        child: DesignText(
          widget.spec.type.emptyText,
          style: DesignTextStyle.body,
          color: tokens.textLow,
        ),
      ),
    );
  }

  Widget _buildErrorBox(DesignTokens tokens, int count) {
    return SizedBox(
      height: count * _rowHeight,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 18, color: tokens.danger),
            SizedBox(width: tokens.spaceSm),
            Flexible(
              child: DesignText(
                'Konnte nicht geladen werden.',
                style: DesignTextStyle.label,
                color: tokens.textLow,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: tokens.spaceSm),
            DesignButton(
              variant: DesignButtonVariant.text,
              label: 'Erneut versuchen',
              onPressed: refresh,
            ),
          ],
        ),
      ),
    );
  }

  /// Einstellungen des Widgets (Anzahl, Leer-Verhalten) im Edit-Modus.
  Future<void> _openSettings() async {
    await showDesignSheet(
      context: context,
      child: _WidgetSettingsSheet(
        controller: widget.controller,
        config: _config,
      ),
    );
  }
}

class _WidgetSettingsSheet extends StatefulWidget {
  const _WidgetSettingsSheet({required this.controller, required this.config});

  final DashboardController controller;
  final DashboardWidgetConfig config;

  @override
  State<_WidgetSettingsSheet> createState() => _WidgetSettingsSheetState();
}

class _WidgetSettingsSheetState extends State<_WidgetSettingsSheet> {
  late int _count = widget.config.count;
  late WidgetEmptyState _emptyState = widget.config.emptyState;

  void _apply() {
    widget.controller.updateConfig(
      widget.config.type,
      count: _count,
      emptyState: _emptyState,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final type = widget.config.type;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DesignText(
          type.title,
          style: DesignTextStyle.subtitle,
          color: tokens.textHigh,
        ),
        if (type.countConfigurable) ...[
          SizedBox(height: tokens.spaceLg),
          Row(
            children: [
              Expanded(
                child: DesignText(
                  'Anzahl Einträge',
                  style: DesignTextStyle.body,
                  color: tokens.textLow,
                ),
              ),
              _StepperButton(
                icon: Icons.remove_rounded,
                onPressed: _count > type.countMin!
                    ? () {
                        setState(() => _count--);
                        _apply();
                      }
                    : null,
              ),
              SizedBox(
                width: tokens.spaceXl,
                child: DesignText(
                  '$_count',
                  style: DesignTextStyle.body,
                  textAlign: TextAlign.center,
                ),
              ),
              _StepperButton(
                icon: Icons.add_rounded,
                onPressed: _count < type.countMax!
                    ? () {
                        setState(() => _count++);
                        _apply();
                      }
                    : null,
              ),
            ],
          ),
        ],
        SizedBox(height: tokens.spaceLg),
        DesignText(
          'Bei fehlenden Daten',
          style: DesignTextStyle.body,
          color: tokens.textLow,
        ),
        SizedBox(height: tokens.spaceSm),
        Row(
          children: [
            Expanded(
              child: _EmptyStateOption(
                label: 'Karte anzeigen',
                active: _emptyState == WidgetEmptyState.card,
                onTap: () {
                  setState(() => _emptyState = WidgetEmptyState.card);
                  _apply();
                },
              ),
            ),
            SizedBox(width: tokens.spaceMd),
            Expanded(
              child: _EmptyStateOption(
                label: 'Ausblenden',
                active: _emptyState == WidgetEmptyState.hide,
                onTap: () {
                  setState(() => _emptyState = WidgetEmptyState.hide);
                  _apply();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final enabled = onPressed != null;
    return PressScale(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: enabled
              ? tokens.surfaceVariant
              : tokens.surfaceVariant.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(tokens.radiusMd),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled
              ? tokens.textHigh
              : tokens.textLow.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

class _EmptyStateOption extends StatelessWidget {
  const _EmptyStateOption({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return PressScale(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: tokens.spaceSm),
        decoration: BoxDecoration(
          color: active
              ? tokens.primary.withValues(alpha: 0.15)
              : tokens.surfaceVariant.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(tokens.radiusPill),
          border: Border.all(
            color: active
                ? tokens.primary
                : tokens.border.withValues(alpha: 0.5),
          ),
          boxShadow: active ? tokens.glowShadow : null,
        ),
        child: Center(
          child: DesignText(
            label,
            style: DesignTextStyle.label,
            color: active ? tokens.primary : tokens.textHigh,
          ),
        ),
      ),
    );
  }
}
