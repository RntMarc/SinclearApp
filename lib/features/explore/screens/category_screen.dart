import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/di/app_scope.dart';
import '../models/explore_models.dart';
import '../widgets/explore_map.dart';
import '../widgets/explore_search_overlay.dart';
import '../widgets/place_card.dart';

class CategoryScreen extends StatefulWidget {
  final String category;

  const CategoryScreen({super.key, required this.category});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _scrollController = ScrollController();
  List<ExplorePlace> _places = [];
  PaginationMeta? _meta;
  bool _loading = true;
  bool _loadingMore = false;
  bool _showMap = false;
  String? _error;
  String? _sort;

  List<ExplorePlace>? _searchResults;
  PaginationMeta? _searchMeta;
  bool _loadingMoreSearch = false;
  final _searchScrollController = ScrollController();
  ({String mode, String query, String? category, double radius})? _lastSearch;

  static const _sortOptions = [
    ('name', 'Alphabetisch'),
    ('created', 'Neueste'),
    ('rating', 'Bewertung'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
    _scrollController.addListener(_onScroll);
    _searchScrollController.addListener(_onSearchScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchScrollController.removeListener(_onSearchScroll);
    _searchScrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_loadingMore &&
        _meta?.hasMore == true) {
      _loadMore();
    }
  }

  void _onSearchScroll() {
    if (_searchScrollController.position.pixels >=
            _searchScrollController.position.maxScrollExtent - 200 &&
        !_loadingMoreSearch &&
        _searchMeta?.hasMore == true) {
      _loadMoreSearch();
    }
  }

  void _setSort(String base) {
    setState(() {
      if (_sort == null || !_sort!.startsWith(base)) {
        _sort = '${base}_${base == 'name' ? 'asc' : 'desc'}';
      } else if (_sort!.endsWith('asc')) {
        _sort = '${base}_desc';
      } else {
        _sort = null;
      }
      _places = [];
      _meta = null;
    });
    _load();
  }

  bool _isSelected(String base) => _sort?.startsWith(base) ?? false;

  String _sortLabel(String base) {
    if (!_isSelected(base)) return '';
    return _sort!.endsWith('asc') ? ' ↑' : ' ↓';
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final explore = AppScope.of(context).explore;
      final response = await explore.list(
        category: widget.category,
        sort: _sort,
        page: 1,
        limit: 20,
      );
      if (!mounted) return;
      setState(() {
        _places = response.data;
        _meta = response.meta;
        _loading = false;
        _error = null;
      });
    } catch (e, st) {
      developer.log('Failed to load category', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Daten konnten nicht geladen werden.';
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _meta == null || !_meta!.hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final explore = AppScope.of(context).explore;
      final response = await explore.list(
        category: widget.category,
        sort: _sort,
        page: _meta!.page + 1,
        limit: 20,
      );
      if (!mounted) return;
      setState(() {
        _places.addAll(response.data);
        _meta = response.meta;
        _loadingMore = false;
      });
    } catch (e, st) {
      developer.log('Failed to load more', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _searchByLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      final explore = AppScope.of(context).explore;
      final response = await explore.search(
        category: widget.category,
        lat: position.latitude,
        lon: position.longitude,
        radius: 5000,
      );
      if (!mounted) return;
      setState(() {
        _searchResults = response.data;
        _searchMeta = response.meta;
        _lastSearch = (
          mode: 'geolocation',
          query: '',
          category: widget.category,
          radius: 5000,
        );
      });
    } catch (e, st) {
      developer.log('Failed to search by location', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _error = 'Standort konnte nicht ermittelt werden.');
    }
  }

  Future<void> _openSearch() async {
    final result = await Navigator.push<ExploreListResponse>(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ExploreSearchOverlay(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOutCubic,
                  ),
                ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.3),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _searchResults = result.data;
        _searchMeta = result.meta;
      });
    }
  }

  void _clearSearch() {
    setState(() {
      _searchResults = null;
      _searchMeta = null;
      _loadingMoreSearch = false;
      _lastSearch = null;
    });
  }

  Future<void> _loadMoreSearch() async {
    if (_loadingMoreSearch ||
        _searchMeta == null ||
        !_searchMeta!.hasMore ||
        _lastSearch == null) {
      return;
    }

    setState(() => _loadingMoreSearch = true);
    try {
      final explore = AppScope.of(context).explore;
      final params = _lastSearch!;
      final response = params.mode == 'name'
          ? await explore.search(
              q: params.query,
              category: params.category,
              page: _searchMeta!.page + 1,
              limit: 20,
            )
          : await explore.search(
              location: params.query,
              radius: params.radius.round(),
              category: params.category,
              page: _searchMeta!.page + 1,
              limit: 20,
            );
      if (!mounted) return;
      setState(() {
        _searchResults!.addAll(response.data);
        _searchMeta = response.meta;
        _loadingMoreSearch = false;
      });
    } catch (e, st) {
      developer.log(
        'Failed to load more search results',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      setState(() => _loadingMoreSearch = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
                    child: InkWell(
                      onTap: _openSearch,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: colorScheme.outline),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Orte, Städte, Kategorien…',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _searchByLocation,
                    icon: const Icon(Icons.my_location_rounded),
                    tooltip: 'In meiner Nähe',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_searchResults != null)
                Row(
                  children: [
                    Text(
                      'Suchergebnisse',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _clearSearch,
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Schließen'),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    for (final opt in _sortOptions)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: SortChip(
                          label: '${opt.$2}${_sortLabel(opt.$1)}',
                          selected: _isSelected(opt.$1),
                          onTap: () => _setSort(opt.$1),
                        ),
                      ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => setState(() => _showMap = !_showMap),
                      icon: Icon(
                        _showMap ? Icons.list_rounded : Icons.map_rounded,
                      ),
                      tooltip: _showMap ? 'Liste' : 'Karte',
                    ),
                  ],
                ),
            ],
          ),
        ),
        if (_searchResults != null && _searchResults!.isNotEmpty)
          Expanded(child: _buildSearchResults(theme, crossAxisCount))
        else if (_searchResults != null)
          Expanded(child: _buildSearchEmpty(theme))
        else if (_showMap)
          Expanded(child: ExploreMap(places: _places))
        else
          Expanded(child: _buildList(theme, crossAxisCount)),
      ],
    );
  }

  Widget _buildSearchResults(ThemeData theme, int crossAxisCount) {
    return CustomScrollView(
      controller: _searchScrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: crossAxisCount > 1 ? 1.5 : 2.5,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= _searchResults!.length) {
                  return const Center(child: CircularProgressIndicator());
                }
                return PlaceCard(place: _searchResults![index]);
              },
              childCount: _searchResults!.length + (_loadingMoreSearch ? 1 : 0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchEmpty(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'Keine Ergebnisse gefunden.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: _clearSearch,
            child: const Text('Zurück'),
          ),
        ],
      ),
    );
  }

  Widget _buildList(ThemeData theme, int crossAxisCount) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 8),
            Text(_error!, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: _load,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    if (_places.isEmpty) {
      return Center(
        child: Text(
          'Keine Einträge in dieser Kategorie.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: crossAxisCount > 1 ? 1.5 : 2.5,
        ),
        itemCount: _places.length + (_loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _places.length) {
            return const Center(child: CircularProgressIndicator());
          }
          return PlaceCard(place: _places[index]);
        },
      ),
    );
  }
}

class SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const SortChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
