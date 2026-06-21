import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/network/api_client.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${place.name} wurde hinzugefügt!')),
      );
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
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Name oder Ort suchen…',
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _searching ? null : _search,
              icon: _searching
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.search_rounded),
              label: Text(_searching ? 'Suche läuft…' : 'Suchen'),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: Text(
                      'Gib einen Namen oder Ort ein, um nach Einträgen zu suchen.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final result = _results[index];
                      return ListTile(
                        leading: Icon(
                          result.osmType == 'N'
                              ? Icons.location_on_rounded
                              : result.osmType == 'W'
                              ? Icons.route_rounded
                              : Icons.layers_rounded,
                          color: theme.colorScheme.primary,
                        ),
                        title: Text(
                          result.displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text('OSM-ID: ${result.osmId}'),
                        trailing: _submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.add_circle_outline),
                        onTap: _submitting ? null : () => _submit(result),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
