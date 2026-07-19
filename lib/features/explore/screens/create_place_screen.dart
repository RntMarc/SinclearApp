import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/network/api_client.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_divider.dart';
import '../../../design/widgets/primitives/design_text_field.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/composite/design_list_tile.dart';
import '../models/explore_models.dart';

class CreatePlaceScreen extends StatefulWidget {
  const CreatePlaceScreen({super.key});

  @override
  State<CreatePlaceScreen> createState() => _CreatePlaceScreenState();
}

class _CreatePlaceScreenState extends State<CreatePlaceScreen> {
  final _searchController = TextEditingController();
  List<NominatimResult> _results = [];
  bool _searching = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _searching = true;
      _error = null;
      _results = [];
    });

    try {
      final nominatim = AppScope.of(context).nominatim;
      final results = await nominatim.search(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _searching = false;
      });
    } catch (e, st) {
      developer.log('Failed to search OSM', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _searching = false;
        _error = 'Suche fehlgeschlagen. Bitte versuche es erneut.';
      });
    }
  }

  Future<void> _submit(NominatimResult result) async {
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final explore = AppScope.of(context).explore;
      final place = await explore.create(
        osmId: result.osmId,
        osmType: result.osmType,
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      context.go('/entdecken/${place.id}');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = switch (e.errorCode) {
          'place_already_exists' => 'Dieser Ort existiert bereits.',
          _ => 'Fehler beim Hinzufügen.',
        };
      });
    } catch (e, st) {
      developer.log('Failed to create place', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Netzwerkfehler. Bitte versuche es erneut.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return DesignSurface(
      child: Column(
        children: [
          const DesignSubpageHeader(
            title: 'Ort hinzufügen',
          ),
          Expanded(child: _buildBody(tokens)),
        ],
      ),
    );
  }

  Widget _buildBody(DesignTokens tokens) {
    return Padding(
      padding: EdgeInsets.all(tokens.spaceLg),
      child: Column(
        children: [
          DesignTextField(
            controller: _searchController,
            hint: 'Name oder Ort suchen…',
            prefixIcon: Icons.search_rounded,
          ),
          SizedBox(height: tokens.spaceMd),
          DesignButton(
            variant: DesignButtonVariant.filled,
            icon: Icons.search_rounded,
            label: _searching ? 'Suche läuft…' : 'Suchen',
            fullWidth: true,
            loading: _searching,
            onPressed: _searching ? null : _search,
          ),
          if (_error != null) ...[
            SizedBox(height: tokens.spaceMd),
            DesignText(
              _error!,
              style: DesignTextStyle.body,
              color: tokens.danger,
            ),
          ],
          SizedBox(height: tokens.spaceLg),
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: DesignText(
                      'Gib einen Namen oder Ort ein, um nach Einträgen zu suchen.',
                      textAlign: TextAlign.center,
                      style: DesignTextStyle.body,
                      color: tokens.textLow,
                    ),
                  )
                : ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (_, _) => const DesignDivider(),
                    itemBuilder: (context, index) {
                      final result = _results[index];
                      return DesignCard(
                        margin: EdgeInsets.zero,
                        padding: EdgeInsets.zero,
                        child: DesignListTile(
                          leading: Icon(
                            result.osmType == 'N'
                                ? Icons.location_on_rounded
                                : result.osmType == 'W'
                                ? Icons.route_rounded
                                : Icons.layers_rounded,
                            color: tokens.primary,
                          ),
                          title: result.displayName,
                          subtitle: 'OSM-ID: ${result.osmId}',
                          trailing: _submitting
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: tokens.primary,
                                  ),
                                )
                              : Icon(
                                  Icons.add_circle_outline,
                                  color: tokens.primary,
                                ),
                          onTap: _submitting ? null : () => _submit(result),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
