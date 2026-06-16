import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/di/app_scope.dart';
import '../models/explore_models.dart';
import '../widgets/place_card.dart';
import '../widgets/explore_map.dart';

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
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
    } catch (_) {
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
    } catch (_) {
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
        _places = response.data;
        _meta = response.meta;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Standort konnte nicht ermittelt werden.');
    }
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
          child: Row(
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
                onPressed: _searchByLocation,
                icon: const Icon(Icons.my_location_rounded),
                tooltip: 'In meiner Nähe',
              ),
              IconButton(
                onPressed: () => setState(() => _showMap = !_showMap),
                icon: Icon(
                  _showMap ? Icons.list_rounded : Icons.map_rounded,
                ),
                tooltip: _showMap ? 'Liste' : 'Karte',
              ),
            ],
          ),
        ),
        if (_showMap)
          Expanded(
            child: ExploreMap(places: _places),
          )
        else
          Expanded(child: _buildList(theme, crossAxisCount)),
      ],
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
            Icon(Icons.error_outline, size: 48,
                color: theme.colorScheme.error),
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
