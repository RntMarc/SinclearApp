import 'dart:developer' as developer;
import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../models/recipes_models.dart';
import '../widgets/recipe_card.dart';

class CategoryRecipesScreen extends StatefulWidget {
  final String category;
  final String? initialQuery;

  const CategoryRecipesScreen({
    super.key,
    required this.category,
    this.initialQuery,
  });

  @override
  State<CategoryRecipesScreen> createState() => _CategoryRecipesScreenState();
}

class _CategoryRecipesScreenState extends State<CategoryRecipesScreen> {
  final _scrollController = ScrollController();
  List<RecipeListItem> _recipes = [];
  PaginationMeta? _meta;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  bool _hasLoaded = false;
  String? _sort;

  static const _sortOptions = [
    ('created', 'Neueste'),
    ('rating', 'Bewertung'),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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
        _sort = '${base}_desc';
      } else if (_sort!.endsWith('asc')) {
        _sort = '${base}_desc';
      } else {
        _sort = null;
      }
      _recipes = [];
      _meta = null;
    });
    _load();
  }

  bool _isSelected(String base) => _sort?.startsWith(base) ?? false;

  String _sortLabel(String base) {
    if (!_isSelected(base)) return '';
    return _sort!.endsWith('asc') ? ' ↑' : ' ↓';
  }

  String get _categoryLabel {
    if (_isSearch) return 'Suche: ${widget.initialQuery ?? ''}';
    return recipeCategories[widget.category] ?? widget.category;
  }

  bool get _isSearch => widget.category == 'suche';

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final recipes = AppScope.of(context).recipes;
      final response = await recipes.list(
        search: _isSearch ? widget.initialQuery : null,
        sort: _sort ?? 'created_desc',
        page: 1,
        limit: 20,
      );
      final filtered = _isSearch
          ? response.data
          : response.data
              .where((r) => r.category == widget.category)
              .toList();
      if (!mounted) return;
      setState(() {
        _recipes = filtered;
        _meta = response.meta;
        _loading = false;
        _error = null;
      });
    } catch (e, st) {
      developer.log('Failed to load recipes', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Rezepte konnten nicht geladen werden.';
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _meta == null || !_meta!.hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final recipes = AppScope.of(context).recipes;
      final response = await recipes.list(
        search: _isSearch ? widget.initialQuery : null,
        sort: _sort ?? 'created_desc',
        page: _meta!.page + 1,
        limit: 20,
      );
      final filtered = _isSearch
          ? response.data
          : response.data
              .where((r) => r.category == widget.category)
              .toList();
      if (!mounted) return;
      setState(() {
        _recipes.addAll(filtered);
        _meta = response.meta;
        _loadingMore = false;
      });
    } catch (e, st) {
      developer.log('Failed to load more recipes', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _loadingMore = false);
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
              Text(
                _categoryLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final opt in _sortOptions)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: FilterChip(
                          label: Text('${opt.$2}${_sortLabel(opt.$1)}'),
                          selected: _isSelected(opt.$1),
                          onSelected: (_) => _setSort(opt.$1),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
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

    if (_recipes.isEmpty) {
      return Center(
        child: Text(
          'Keine Rezepte in dieser Kategorie.',
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
        itemCount: _recipes.length + (_loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _recipes.length) {
            return const Center(child: CircularProgressIndicator());
          }
          return RecipeCard(recipe: _recipes[index]);
        },
      ),
    );
  }
}
