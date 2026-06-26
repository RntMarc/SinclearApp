import 'dart:developer' as developer;
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/app_scope.dart';
import '../models/explore_models.dart';
import '../widgets/explore_map.dart';
import '../widgets/explore_search_overlay.dart';
import '../widgets/place_card.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  List<ExplorePlace> _suggestions = [];
  List<ExplorePlace> _bookmarks = [];
  bool _loading = true;
  bool _loadingBookmarks = true;
  bool _bookmarksError = false;
  bool _showMap = false;
  String? _error;
  bool _hasLoaded = false;

  List<ExplorePlace>? _searchResults;
  PaginationMeta? _searchMeta;
  bool _loadingMoreSearch = false;
  final _searchScrollController = ScrollController();
  ({String mode, String query, String? category, double radius})? _lastSearch;

  @override
  void initState() {
    super.initState();
    _searchScrollController.addListener(_onSearchScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      _hasLoaded = true;
      _loadSuggestions();
      _loadBookmarks();
    }
  }

  @override
  void dispose() {
    _searchScrollController.removeListener(_onSearchScroll);
    _searchScrollController.dispose();
    super.dispose();
  }

  void _onSearchScroll() {
    if (_searchScrollController.position.pixels >=
            _searchScrollController.position.maxScrollExtent - 200 &&
        !_loadingMoreSearch &&
        _searchMeta?.hasMore == true) {
      _loadMoreSearch();
    }
  }

  Future<void> _loadSuggestions() async {
    setState(() => _loading = true);
    try {
      final explore = AppScope.of(context).explore;
      final response = await explore.random(limit: 20);
      if (!mounted) return;
      setState(() {
        _suggestions = response.data;
        _loading = false;
        _error = null;
      });
    } catch (e, st) {
      developer.log('Failed to load suggestions', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Vorschlage konnten nicht geladen werden.';
      });
    }
  }

  Future<void> _loadBookmarks() async {
    setState(() {
      _loadingBookmarks = true;
      _bookmarksError = false;
    });
    try {
      final explore = AppScope.of(context).explore;
      final response = await explore.getBookmarks(limit: 20);
      if (!mounted) return;
      setState(() {
        _bookmarks = response.data;
        _loadingBookmarks = false;
      });
    } catch (e, st) {
      developer.log('Failed to load bookmarks', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loadingBookmarks = false;
        _bookmarksError = true;
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
        _searchResults = response.data;
        _searchMeta = response.meta;
        _lastSearch = (
          mode: 'geolocation',
          query: '',
          category: null,
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
                  const SizedBox(width: 8),
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _CategoryButton(
                      icon: CupertinoIcons.square_grid_2x2,
                      label: 'Gastronomie',
                      onTap: () => context.go('/entdecken/gastronomie'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CategoryButton(
                      icon: CupertinoIcons.leaf_arrow_circlepath,
                      label: 'Freizeit',
                      onTap: () => context.go('/entdecken/freizeit'),
                    ),
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
          Expanded(child: ExploreMap(places: _suggestions, zoom: 6))
        else
          Expanded(child: _buildSuggestionsList(theme, crossAxisCount)),
      ],
    );
  }

  Widget _buildSearchResults(CupertinoThemeData theme, int crossAxisCount) {
    return CustomScrollView(
      controller: _searchScrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Text(
                  'Suchergebnisse',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.textStyle.color,
                  ),
                ),
                const Spacer(),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _clearSearch,
                  child: const Text('Schliessen'),
                ),
              ],
            ),
          ),
        ),
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
          Icon(
            CupertinoIcons.search,
            size: 48,
            color: CupertinoColors.systemGrey,
          ),
          const SizedBox(height: 8),
          Text(
            'Keine Ergebnisse gefunden.',
            style: TextStyle(
              fontSize: 16,
              color: CupertinoColors.systemGrey,
            ),
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

  Widget _buildSuggestionsList(CupertinoThemeData theme, int crossAxisCount) {
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
              onPressed: _loadSuggestions,
              child: const Text('Erneut versuchen'),
            ),
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
                'Vorschlage',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.textStyle.color,
                ),
              ),
            ),
          ),
        ),
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
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.textStyle.color,
                  ),
                ),
                const SizedBox(height: 8),
                if (_loadingBookmarks)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CupertinoActivityIndicator()),
                  )
                else if (_bookmarksError)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(
                            CupertinoIcons.exclamationmark_triangle,
                            size: 24,
                            color: CupertinoColors.destructiveRed,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Lesezeichen konnten nicht geladen werden.',
                            style: TextStyle(
                              color: CupertinoColors.destructiveRed,
                            ),
                          ),
                          const SizedBox(height: 8),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: _loadBookmarks,
                            child: const Text('Erneut versuchen'),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_bookmarks.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'Keine Lesezeichen vorhanden.',
                        style: TextStyle(color: CupertinoColors.systemGrey),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 200,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.zero,
                      itemCount: _bookmarks.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) => SizedBox(
                        width: 260,
                        child: PlaceCard(place: _bookmarks[index]),
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
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: CupertinoColors.systemGrey6,
      onPressed: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: CupertinoTheme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: CupertinoTheme.of(context).textTheme.textStyle.color,
            ),
          ),
        ],
      ),
    );
  }
}
