import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/app_scope.dart';
import '../models/explore_models.dart';
import '../widgets/place_card.dart';
import '../widgets/explore_map.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchController = TextEditingController();
  List<ExplorePlace> _suggestions = [];
  bool _loading = true;
  bool _showMap = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    setState(() => _loading = true);
    try {
      final explore = AppScope.of(context).explore;
      final response = await explore.list(page: 1, limit: 20);
      if (!mounted) return;
      setState(() {
        _suggestions = response.data;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Vorschläge konnten nicht geladen werden.';
      });
    }
  }

  Future<void> _searchByLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      final explore = AppScope.of(context).explore;
      final response = await explore.search(
        lat: position.latitude,
        lon: position.longitude,
        radius: 5000,
      );
      if (!mounted) return;
      setState(() {
        _suggestions = response.data;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Standort konnte nicht ermittelt werden.');
    }
  }

  void _searchByText(String query) {
    if (query.trim().isEmpty) return;
    context.go('/entdecken/gastronomie', extra: {'q': query.trim()});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 600;
    final crossAxisCount = isWide ? (width >= 900 ? 3 : 2) : 1;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Orte, Städte, Kategorien…',
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
                      onSubmitted: _searchByText,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _searchByLocation,
                    icon: const Icon(Icons.my_location_rounded),
                    tooltip: 'In meiner Nähe suchen',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _CategoryButton(
                      icon: Icons.restaurant_rounded,
                      label: 'Gastronomie',
                      onTap: () => context.go('/entdecken/gastronomie'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CategoryButton(
                      icon: Icons.park_rounded,
                      label: 'Freizeit',
                      onTap: () => context.go('/entdecken/freizeit'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => setState(() => _showMap = !_showMap),
                    icon: Icon(
                      _showMap ? Icons.list_rounded : Icons.map_rounded,
                    ),
                    tooltip: _showMap ? 'Listenansicht' : 'Kartenansicht',
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_showMap)
          Expanded(
            child: ExploreMap(
              places: _suggestions,
              zoom: 6,
            ),
          )
        else
          Expanded(
            child: _buildSuggestionsList(theme, crossAxisCount),
          ),
      ],
    );
  }

  Widget _buildSuggestionsList(ThemeData theme, int crossAxisCount) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48,
                color: theme.colorScheme.error),
            const SizedBox(height: 8),
            Text(_error!, style: theme.textTheme.bodyMedium),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Vorschläge',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        // TODO: Suggestions durch einen API-Endpunkt für zufällige Orte ersetzen
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: crossAxisCount > 1 ? 1.5 : 2.5,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => PlaceCard(place: _suggestions[index]),
              childCount: _suggestions.length,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lesezeichen',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // TODO: Lesezeichen-Integration, wenn API-Endpunkte verfügbar sind
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Lesezeichen sind bald verfügbar.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CategoryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
      ),
    );
  }
}
