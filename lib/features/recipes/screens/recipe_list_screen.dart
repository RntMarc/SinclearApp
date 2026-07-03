import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/app_scope.dart';
import '../models/recipes_models.dart';
import '../widgets/recipe_card.dart';

class RecipeListScreen extends StatefulWidget {
  const RecipeListScreen({super.key});

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  final _searchController = TextEditingController();
  List<RecipeListItem> _recentRecipes = [];
  List<RecipeListItem> _bookmarks = [];
  bool _loadingRecent = true;
  bool _loadingBookmarks = true;
  String? _recentError;
  String? _bookmarksError;
  bool _hasLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      _hasLoaded = true;
      _loadRecent();
      _loadBookmarks();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    setState(() {
      _loadingRecent = true;
      _recentError = null;
    });
    try {
      final recipes = AppScope.of(context).recipes;
      final response = await recipes.list(sort: 'created_desc', limit: 10);
      if (!mounted) return;
      setState(() {
        _recentRecipes = response.data;
        _loadingRecent = false;
      });
    } catch (e, st) {
      developer.log('Failed to load recent recipes', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loadingRecent = false;
        _recentError = 'Rezepte konnten nicht geladen werden.';
      });
    }
  }

  Future<void> _loadBookmarks() async {
    setState(() {
      _loadingBookmarks = true;
      _bookmarksError = null;
    });
    try {
      final recipes = AppScope.of(context).recipes;
      final response = await recipes.getBookmarks(limit: 10);
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
        _bookmarksError = 'Lesezeichen konnten nicht geladen werden.';
      });
    }
  }

  void _onSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    context.go('/rezepte/suche?q=${Uri.encodeComponent(query)}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 600;
    final crossAxisCount = isWide ? (width >= 900 ? 3 : 2) : 2;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rezepte suchen…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _onSearch(),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Kategorien',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.8,
              ),
              itemCount: recipeCategories.length,
              itemBuilder: (context, index) {
                final entry = recipeCategories.entries.elementAt(index);
                final icon = recipeCategoryIcons[entry.key] ?? '🍴';
                return _CategoryTile(
                  icon: icon,
                  label: entry.value,
                  onTap: () => context.go('/rezepte/kategorie/${entry.key}'),
                );
              },
            ),
          ),
          if (_loadingBookmarks)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_bookmarksError != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 24,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _bookmarksError!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _loadBookmarks,
                          child: const Text('Erneut versuchen'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else if (_bookmarks.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'Lesezeichen',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _bookmarks.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) => SizedBox(
                  width: 260,
                  child: RecipeCard(recipe: _bookmarks[index]),
                ),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
            child: Row(
              children: [
                Text(
                  'Neueste Rezepte',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_recentRecipes.isNotEmpty)
                  TextButton(
                    onPressed: () => context.go('/rezepte/alle'),
                    child: const Text('Alle'),
                  ),
              ],
            ),
          ),
          if (_loadingRecent)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_recentError != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 24,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _recentError!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _loadRecent,
                          child: const Text('Erneut versuchen'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else if (_recentRecipes.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Noch keine Rezepte vorhanden.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWide ? (width >= 900 ? 3 : 2) : 1,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: isWide ? 1.5 : 2.5,
                ),
                itemCount: _recentRecipes.length,
                itemBuilder: (context, index) => RecipeCard(
                  recipe: _recentRecipes[index],
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
