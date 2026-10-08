import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/network/api_client.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_chip.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../../design/widgets/primitives/design_text_field.dart';
import '../models/travel_planning_models.dart';
import '../travel_planning_error_messages.dart';

/// Erstellt eine neue Planungsreise (`POST /trips/planning`).
///
/// Name und Beschreibung genügen; das Datum bleibt offen. Die Leitung kann
/// beim Start einzelne Phasen überspringen.
class PlanningCreateScreen extends StatefulWidget {
  const PlanningCreateScreen({super.key});

  @override
  State<PlanningCreateScreen> createState() => _PlanningCreateScreenState();
}

class _PlanningCreateScreenState extends State<PlanningCreateScreen> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final Set<String> _skipped = {};
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte gib einen Namen an.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final detail = await AppScope.of(context).planning.create(
        name: name,
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        skippedTopics: _skipped.toList(),
      );
      if (!mounted) return;
      context.go('/reisen/planung/${detail.id}');
    } on ApiException catch (e) {
      developer.log('Failed to create planning trip', error: e);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(planningErrorMessage(e))));
    } catch (e, st) {
      developer.log('Failed to create planning trip', error: e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fehler beim Erstellen.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return DesignSurface(
      child: Column(
        children: [
          DesignSubpageHeader(
            leading: DesignIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => context.pop(),
            ),
            title: 'Reise gemeinsam planen',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(tokens.spaceLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label(tokens, 'Name'),
                  SizedBox(height: tokens.spaceSm),
                  DesignTextField(hint: 'Name der Reise', controller: _name),
                  SizedBox(height: tokens.spaceMd),
                  _label(tokens, 'Beschreibung'),
                  SizedBox(height: tokens.spaceSm),
                  DesignTextField(
                    hint: 'Beschreibung (optional)',
                    controller: _description,
                    maxLines: 3,
                  ),
                  SizedBox(height: tokens.spaceXl),
                  _label(tokens, 'Phasen überspringen'),
                  SizedBox(height: tokens.spaceXs),
                  DesignText(
                    'Übersprungene Phasen werden als solches gekennzeichnet.',
                    style: DesignTextStyle.label,
                    color: tokens.textLow,
                  ),
                  SizedBox(height: tokens.spaceSm),
                  Wrap(
                    spacing: tokens.spaceSm,
                    runSpacing: tokens.spaceSm,
                    children: [
                      for (final topic in PlanningPhase.order)
                        DesignChip(
                          label: PlanningPhase.label(topic),
                          selected: _skipped.contains(topic),
                          onTap: () => setState(() {
                            if (!_skipped.remove(topic)) _skipped.add(topic);
                          }),
                        ),
                    ],
                  ),
                  SizedBox(height: tokens.spaceXxl),
                  DesignButton(
                    label: 'Planung erstellen',
                    fullWidth: true,
                    loading: _saving,
                    onPressed: _save,
                  ),
                  SizedBox(height: tokens.spaceXl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(DesignTokens tokens, String text) {
    return DesignText(
      text,
      style: DesignTextStyle.label,
      color: tokens.textLow,
    );
  }
}
