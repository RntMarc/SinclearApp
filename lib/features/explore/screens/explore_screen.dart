import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/app_scope.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
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
        _error = 'Vorschläge konnten nicht geladen werden.';
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
                      tinted: true,
                      onPressed: _searchByLocation,
                    ),
                  ],
                ),
                SizedBox(height: tokens.spaceMd),
                Row(
                  children: [
                    Expanded(
                      child: DesignButton(
                        variant: DesignButtonVariant.outlined,
                        icon: Icons.restaurant_rounded,
                        label: 'Gastronomie',
                        onPressed: () => context.go('/entdecken/gastronomie'),
                      ),
                    ),
                    SizedBox(width: tokens.spaceMd),
                    Expanded(
                      child: DesignButton(
                        variant: DesignButtonVariant.outlined,
                        icon: Icons.park_rounded,
                        label: 'Freizeit',
                        onPressed: () => context.go('/entdecken/freizeit'),
                      ),
                    ),
                    SizedBox(width: tokens.spaceSm),
                    DesignIconButton(
                      icon: _showMap ? Icons.list_rounded : Icons.map_rounded,
                      onPressed: () =>
                          setState(() => _showMap = !_showMap),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_searchResults != null && _searchResults!.isNotEmpty)
            Expanded(child: _buildSearchResults(tokens, crossAxisCount))
          else if (_searchResults != null)
            Expanded(child: _buildSearchEmpty(tokens))
          else if (_showMap)
            Expanded(child: ExploreMap(places: _suggestions, zoom: 6))
          else
            Expanded(child: _buildSuggestionsList(tokens, crossAxisCount)),
        ],
      ),
    );
  }

  Widget _buildSearchResults(DesignTokens tokens, int crossAxisCount) {
    return CustomScrollView(
      controller: _searchScrollController,
      slivers: [
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
          sliver: SliverToBoxAdapter(
            child: Row(
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
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            tokens.spaceLg,
            tokens.spaceSm,
            tokens.spaceLg,
            tokens.spaceLg,
          ),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: crossAxisCount > 1 ? 2.0 : 3.5,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= _searchResults!.length) {
                  return Center(
                    child: CircularProgressIndicator(color: tokens.primary),
                  );
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

  Widget _buildSearchEmpty(DesignTokens tokens) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 48,
            color: tokens.textLow,
          ),
          SizedBox(height: tokens.spaceSm),
          DesignText(
            'Keine Ergebnisse gefunden.',
            style: DesignTextStyle.body,
            color: tokens.textLow,
          ),
          SizedBox(height: tokens.spaceLg),
          DesignButton(
            variant: DesignButtonVariant.filled,
            label: 'Zurück',
            onPressed: _clearSearch,
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList(DesignTokens tokens, int crossAxisCount) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: tokens.primary));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: tokens.danger),
            SizedBox(height: tokens.spaceSm),
            DesignText(
              _error!,
              style: DesignTextStyle.body,
              color: tokens.textHigh,
            ),
            SizedBox(height: tokens.spaceLg),
            DesignButton(
              variant: DesignButtonVariant.filled,
              label: 'Erneut versuchen',
              onPressed: _loadSuggestions,
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
          sliver: SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: tokens.spaceSm),
              child: DesignText(
                'Vorschläge',
                style: DesignTextStyle.subtitle,
                color: tokens.textHigh,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: crossAxisCount > 1 ? 2.0 : 3.5,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => PlaceCard(place: _suggestions[index]),
              childCount: _suggestions.length,
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            tokens.spaceLg,
            tokens.spaceXl,
            tokens.spaceLg,
            tokens.spaceLg,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DesignText(
                  'Lesezeichen',
                  style: DesignTextStyle.subtitle,
                  color: tokens.textHigh,
                ),
                SizedBox(height: tokens.spaceSm),
                if (_loadingBookmarks)
                  Padding(
                    padding: EdgeInsets.all(tokens.spaceXl),
                    child: Center(
                      child: CircularProgressIndicator(color: tokens.primary),
                    ),
                  )
                else if (_bookmarksError)
                  DesignCard(
                    padding: EdgeInsets.all(tokens.spaceXl),
                    margin: EdgeInsets.zero,
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 24,
                            color: tokens.danger,
                          ),
                          SizedBox(height: tokens.spaceSm),
                          DesignText(
                            'Lesezeichen konnten nicht geladen werden.',
                            style: DesignTextStyle.body,
                            color: tokens.danger,
                          ),
                          SizedBox(height: tokens.spaceSm),
                          DesignButton(
                            variant: DesignButtonVariant.text,
                            label: 'Erneut versuchen',
                            onPressed: _loadBookmarks,
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_bookmarks.isEmpty)
                  DesignCard(
                    padding: EdgeInsets.all(tokens.spaceXl),
                    margin: EdgeInsets.zero,
                    child: Center(
                      child: DesignText(
                        'Keine Lesezeichen vorhanden.',
                        style: DesignTextStyle.body,
                        color: tokens.textLow,
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
                      separatorBuilder: (_, _) => SizedBox(width: tokens.spaceSm),
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
