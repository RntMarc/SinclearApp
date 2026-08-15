import 'package:flutter/material.dart';

import '../../core/di/app_scope.dart';
import '../../design/theme/design_theme.dart';
import '../../design/widgets/composite/design_bottom_sheet.dart';
import '../../design/widgets/foundation/design_surface.dart';
import '../../design/widgets/foundation/design_text.dart';
import '../../design/widgets/primitives/press_scale.dart';
import '../stories/widgets/stories_bar.dart';
import 'dashboard_controller.dart';
import 'dashboard_widget.dart';
import 'dashboard_widget_repository.dart';
import 'dashboard_widget_view.dart';

/// Maximale Breite des Dashboards auf Desktop (z.B. 720), darunter volle Breite.
const double _desktopMaxWidth = 720;

/// Start-Seite: modulares Dashboard aus platzierbaren Widgets.
///
/// Normal-Modus: scrollende Liste mit Pull-to-Refresh. Edit-Modus: Widgets
/// per Drag & Drop oder Pfeilen sortieren, entfernen, hinzufügen (FAB) und
/// konfigurieren (Tipp auf die Karte).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).dashboard;
    final repository = AppScope.of(context).dashboardWidgets;
    return DesignSurface(
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final editing = controller.editing;
          return Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth >= _desktopMaxWidth
                            ? _desktopMaxWidth
                            : double.infinity,
                      ),
                      child: RefreshIndicator(
                        onRefresh: controller.refreshAll,
                        child: _buildList(
                          context,
                          controller,
                          repository,
                          editing,
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (editing)
                _AddWidgetFab(onPressed: () => _showAddWidgetSheet(context)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    DashboardController controller,
    DashboardWidgetRepository repository,
    bool editing,
  ) {
    final tokens = DesignTheme.of(context);
    final layout = controller.layout;
    final padding = EdgeInsets.only(
      top: tokens.spaceXs,
      bottom: editing ? 96 : tokens.spaceXl,
    );
    final entries = <Widget>[
      for (var i = 0; i < layout.widgets.length; i++)
        DashboardWidgetView(
          controller: controller,
          spec: repository.specFor(layout.widgets[i].type),
          index: i,
          total: layout.widgets.length,
        ),
    ];
    if (editing) {
      return ReorderableListView(
        padding: padding,
        buildDefaultDragHandles: false,
        onReorderItem: (oldIndex, newIndex) =>
            controller.moveWidget(oldIndex, newIndex),
        children: [
          for (var i = 0; i < entries.length; i++)
            ReorderableDelayedDragStartListener(
              key: ValueKey(layout.widgets[i].type),
              index: i,
              child: entries[i],
            ),
        ],
      );
    }
    return ListView(
      padding: padding,
      children: [
        StoriesBar(
          controller: controller,
          service: AppScope.of(context).stories,
        ),
        ...entries,
      ],
    );
  }

  Future<void> _showAddWidgetSheet(BuildContext context) async {
    final controller = AppScope.of(context).dashboard;
    final tokens = DesignTheme.of(context);
    await showDesignSheet(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DesignText(
            'Widget hinzufügen',
            style: DesignTextStyle.subtitle,
            color: tokens.textHigh,
          ),
          SizedBox(height: tokens.spaceLg),
          for (final type in DashboardWidgetType.values)
            _AddWidgetTile(
              type: type,
              added: controller.layout.widgets.any((c) => c.type == type),
              onTap: () {
                controller.addWidget(type);
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }
}

class _AddWidgetFab extends StatelessWidget {
  const _AddWidgetFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Positioned(
      right: tokens.spaceLg,
      bottom: tokens.spaceLg,
      child: PressScale(
        onTap: onPressed,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: tokens.primary,
            borderRadius: BorderRadius.circular(tokens.radiusPill),
            boxShadow: tokens.glowShadow,
          ),
          child: Icon(Icons.add_rounded, color: tokens.textOnPrimary, size: 28),
        ),
      ),
    );
  }
}

class _AddWidgetTile extends StatelessWidget {
  const _AddWidgetTile({
    required this.type,
    required this.added,
    required this.onTap,
  });

  final DashboardWidgetType type;
  final bool added;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Opacity(
      opacity: added ? 0.45 : 1,
      child: PressScale(
        onTap: added ? null : onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: tokens.spaceMd),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tokens.surfaceVariant,
                  borderRadius: BorderRadius.circular(tokens.radiusMd),
                ),
                child: Icon(type.icon, size: 18, color: tokens.primary),
              ),
              SizedBox(width: tokens.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DesignText(
                      type.title,
                      style: DesignTextStyle.body,
                      color: tokens.textHigh,
                    ),
                    SizedBox(height: tokens.spaceXs),
                    DesignText(
                      type.description,
                      style: DesignTextStyle.label,
                      color: tokens.textLow,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (added)
                Icon(
                  Icons.check_circle_rounded,
                  color: tokens.success,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
