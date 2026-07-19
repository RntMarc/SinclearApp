import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/di/app_scope.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_chip.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../models/explore_models.dart';
import '../widgets/explore_map.dart';
import '../widgets/explore_search_overlay.dart';
import '../widgets/category_widgets.dart';
import '../widgets/explore_widgets.dart';

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
  final ValueNotifier<bool> _showMap = ValueNotifier(false);
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
    final tokens = DesignTheme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 600;
    final crossAxisCount = isWide ? (width >= 900 ? 3 : 2) : 1;

    return DesignSurface(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              tokens.spaceLg,
              tokens.spaceLg,
              tokens.spaceLg,
              tokens.spaceSm,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    DesignIconButton(
                      icon: Icons.arrow_back_rounded,
                      onPressed: () => Navigator.pop(context),
                    ),
                    SizedBox(width: tokens.spaceSm),
                    Expanded(
                      child: DesignCard(
                        onTap: _openSearch,
                        padding: EdgeInsets.symmetric(
                          horizontal: tokens.spaceLg,
                          vertical: tokens.spaceMd,
                        ),
                        margin: EdgeInsets.zero,
                        child: Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              color: tokens.textLow,
                            ),
                            SizedBox(width: tokens.spaceMd),
                            Flexible(
                              child: DesignText(
                                'Orte, Städte, Kategorien…',
                                style: DesignTextStyle.body,
                                color: tokens.textLow,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: tokens.spaceSm),
                    DesignIconButton(
                      icon: Icons.my_location_rounded,
                      onPressed: _searchByLocation,
                    ),
                    SizedBox(width: tokens.spaceXs),
                    ValueListenableBuilder<bool>(
                      valueListenable: _showMap,
                      builder: (context, showMap, child) =>
                          DesignIconButton(
                        icon: showMap
                            ? Icons.list_rounded
                            : Icons.map_rounded,
                        onPressed: () =>
                            _showMap.value = !_showMap.value,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: tokens.spaceSm),
                if (_searchResults != null)
                  Row(
                    children: [
                      DesignText(
                        'Suchergebnisse',
                        style: DesignTextStyle.subtitle,
                        color: tokens.textHigh,
                      ),
                      const Spacer(),
                      DesignButton(
                        variant: DesignButtonVariant.text,
                        icon: Icons.close_rounded,
                        label: 'Schließen',
                        onPressed: _clearSearch,
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
                            padding: EdgeInsets.only(right: tokens.spaceSm),
                            child: DesignChip(
                              label: '${opt.$2}${_sortLabel(opt.$1)}',
                              selected: _isSelected(opt.$1),
                              onTap: () => _setSort(opt.$1),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _showMap,
            builder: (context, showMap, child) {
              if (_searchResults != null && _searchResults!.isNotEmpty) {
                return Expanded(
                  child: ExploreSearchResults(
                    results: _searchResults!,
                    crossAxisCount: crossAxisCount,
                    loadingMore: _loadingMoreSearch,
                    scrollController: _searchScrollController,
                    onClear: _clearSearch,
                  ),
                );
              }
              if (_searchResults != null) {
                return Expanded(
                  child: ExploreSearchEmpty(onBack: _clearSearch),
                );
              }
              if (showMap) {
                return Expanded(
                  child: ExploreMap(places: _places),
                );
              }
              return Expanded(
                child: CategoryPlaceList(
                  loading: _loading,
                  places: _places,
                  crossAxisCount: crossAxisCount,
                  error: _error,
                  loadingMore: _loadingMore,
                  scrollController: _scrollController,
                  onRetry: _load,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

}
