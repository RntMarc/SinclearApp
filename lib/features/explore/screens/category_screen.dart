import 'dart:developer' as developer;
import 'package:flutter/cupertino.dart';
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
  bool _hasLoaded = false;
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
    _scrollController.addListener(_onScroll);
    _searchScrollController.addListener(_onSearchScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      _hasLoaded = true;
      _load();
    }
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
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(
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
        barrierColor: CupertinoColors.black.withValues(alpha: 0.3),
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
    final theme = CupertinoTheme.of(context);
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
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: const Icon(CupertinoIcons.back),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: _openSearch,
                      child: Container(
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey6,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              CupertinoIcons.search,
                              color: CupertinoColors.systemGrey,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Orte, Stadte, Kategorien...',
                              style: TextStyle(
                                fontSize: 16,
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _searchByLocation,
                    child: const Icon(
                      CupertinoIcons.location,
                      color: CupertinoColors.systemBlue,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => setState(() => _showMap = !_showMap),
                    child: Icon(
                      _showMap ? CupertinoIcons.list_bullet : CupertinoIcons.map,
                      color: CupertinoColors.systemBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_searchResults != null)
                Row(
                  children: [
                    const Text(
                      'Suchergebnisse',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _clearSearch,
                      child: const Text('Schliessen'),
                    ),
                  ],
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final opt in _sortOptions)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => _setSort(opt.$1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _isSelected(opt.$1)
                                    ? theme.primaryColor
                                    : CupertinoColors.systemGrey6,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '${opt.$2}${_sortLabel(opt.$1)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _isSelected(opt.$1)
                                      ? CupertinoColors.white
                                      : theme.textTheme.textStyle.color,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
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

  Widget _buildSearchResults(CupertinoThemeData theme, int crossAxisCount) {
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
                  return const Center(child: CupertinoActivityIndicator());
                }
                return PlaceCard(place: _searchResults![index]);
              },
              childCount:
                  _searchResults!.length + (_loadingMoreSearch ? 1 : 0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchEmpty(CupertinoThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            CupertinoIcons.search,
            size: 48,
            color: CupertinoColors.systemGrey,
          ),
          const SizedBox(height: 8),
          const Text(
            'Keine Ergebnisse gefunden.',
            style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey),
          ),
          const SizedBox(height: 16),
          CupertinoButton(
            onPressed: _clearSearch,
            child: const Text('Zuruck'),
          ),
        ],
      ),
    );
  }

  Widget _buildList(CupertinoThemeData theme, int crossAxisCount) {
    if (_loading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 48,
              color: CupertinoColors.destructiveRed,
            ),
            const SizedBox(height: 8),
            Text(_error!),
            const SizedBox(height: 16),
            CupertinoButton(
              onPressed: _load,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    if (_places.isEmpty) {
      return const Center(
        child: Text(
          'Keine Eintrage in dieser Kategorie.',
          style: TextStyle(
            fontSize: 16,
            color: CupertinoColors.systemGrey,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _places.length + (_loadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _places.length) {
          return const Center(child: CupertinoActivityIndicator());
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: PlaceCard(place: _places[index]),
        );
      },
    );
  }
}
