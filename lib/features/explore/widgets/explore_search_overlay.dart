import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../../core/di/app_scope.dart';
import '../models/explore_models.dart';

class ExploreSearchOverlay extends StatefulWidget {
  const ExploreSearchOverlay({super.key});

  @override
  State<ExploreSearchOverlay> createState() => _ExploreSearchOverlayState();
}

class _ExploreSearchOverlayState extends State<ExploreSearchOverlay> {
  final _queryController = TextEditingController();
  final _focusNode = FocusNode();
  String _searchMode = 'name';
  String? _selectedCategory;
  double _radius = 5000;
  bool _searching = false;

  @override
  void dispose() {
    _queryController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;

    setState(() => _searching = true);

    try {
      final explore = AppScope.of(context).explore;
      final ExploreListResponse response;

      if (_searchMode == 'name') {
        response = await explore.search(q: query, category: _selectedCategory);
      } else {
        response = await explore.search(
          location: query,
          radius: _radius.round(),
          category: _selectedCategory,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, response);
    } catch (e, st) {
      developer.log('Search failed', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _searching = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Suche fehlgeschlagen.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SUCHEN'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _queryController,
              focusNode: _focusNode,
              autofocus: true,
              decoration: InputDecoration(
                hintText: _searchMode == 'name'
                    ? 'Orte, Kategorien…'
                    : 'Stadt, Stadtteil…',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'name',
                    label: Text('Name'),
                    icon: Icon(Icons.search_rounded),
                  ),
                  ButtonSegment(
                    value: 'location',
                    label: Text('Ort/Region'),
                    icon: Icon(Icons.location_on_rounded),
                  ),
                ],
                selected: {_searchMode},
                onSelectionChanged: (v) {
                  setState(() => _searchMode = v.first);
                  _focusNode.requestFocus();
                },
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Kategorie',
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Alle'),
                  selected: _selectedCategory == null,
                  onSelected: (_) => setState(() => _selectedCategory = null),
                ),
                FilterChip(
                  label: const Text('Gastronomie'),
                  selected: _selectedCategory == 'gastronomy',
                  onSelected: (_) =>
                      setState(() => _selectedCategory = 'gastronomy'),
                ),
                FilterChip(
                  label: const Text('Freizeit'),
                  selected: _selectedCategory == 'leisure',
                  onSelected: (_) =>
                      setState(() => _selectedCategory = 'leisure'),
                ),
              ],
            ),
            if (_searchMode == 'location') ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Umkreis',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${(_radius / 1000).round()} km',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _radius,
                min: 1000,
                max: 50000,
                divisions: 49,
                label: '${(_radius / 1000).round()} km',
                onChanged: (v) => setState(() => _radius = v),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '1 km',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '50 km',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _searching ? null : _search,
              icon: _searching
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.search_rounded),
              label: Text(_searching ? 'Suche läuft…' : 'Suchen'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
