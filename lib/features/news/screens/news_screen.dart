import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../../core/di/app_scope.dart';
import '../models/news_models.dart';
import '../widgets/news_card.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _articlesScrollController = ScrollController();
  final _archiveScrollController = ScrollController();

  List<NewsItem> _dbItems = [];
  List<NewsItem> _rssItems = [];
  PaginationMeta? _articlesMeta;
  bool _articlesLoading = true;
  bool _articlesLoadingMore = false;
  String? _articlesError;

  List<NewsItem> _archive = [];
  PaginationMeta? _archiveMeta;
  bool _archiveLoading = true;
  bool _archiveLoadingMore = false;
  String? _archiveError;

  Set<String> _votedIds = {};
  Set<String> _votedUrls = {};
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _articlesScrollController.addListener(_onArticlesScroll);
    _archiveScrollController.addListener(_onArchiveScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      _hasLoaded = true;
      _loadArticles();
      _loadArchive();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _articlesScrollController.dispose();
    _archiveScrollController.dispose();
    super.dispose();
  }

  void _onArticlesScroll() {
    if (_articlesScrollController.position.pixels >=
            _articlesScrollController.position.maxScrollExtent - 300 &&
        !_articlesLoadingMore &&
        _articlesMeta?.hasMore == true) {
      _loadMoreArticles();
    }
  }

  void _onArchiveScroll() {
    if (_archiveScrollController.position.pixels >=
            _archiveScrollController.position.maxScrollExtent - 300 &&
        !_archiveLoadingMore &&
        _archiveMeta?.hasMore == true) {
      _loadMoreArchive();
    }
  }

  Future<void> _loadArticles() async {
    setState(() {
      _articlesLoading = true;
      _articlesError = null;
    });
    try {
      final news = AppScope.of(context).news;
      final results = await Future.wait([
        news.list(page: 1, limit: 20),
        news.getVotes(limit: 999),
      ]);
      if (!mounted) return;
      final articlesResp = results[0];
      final votesResp = results[1];

      setState(() {
        _dbItems = articlesResp.data.map(NewsItem.fromDbArticle).toList();
        _rssItems = articlesResp.rss.map(NewsItem.fromRssArticle).toList();
        _articlesMeta = articlesResp.meta;
        _votedIds = votesResp.data.map((a) => a.id).toSet();
        _votedUrls = votesResp.data.map((a) => a.url).toSet();
        _articlesLoading = false;
      });
    } catch (e, st) {
      developer.log('Failed to load articles', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _articlesLoading = false;
        _articlesError = 'Artikel konnten nicht geladen werden.';
      });
    }
  }

  Future<void> _loadMoreArticles() async {
    if (_articlesLoadingMore ||
        _articlesMeta == null ||
        !_articlesMeta!.hasMore) {
      return;
    }
    setState(() => _articlesLoadingMore = true);
    try {
      final news = AppScope.of(context).news;
      final response = await news.list(
        page: _articlesMeta!.page + 1,
        limit: 20,
      );
      if (!mounted) return;
      final existingUrls = _dbItems.map((e) => e.url).toSet();
      final newItems = response.data
          .map(NewsItem.fromDbArticle)
          .where((item) => !existingUrls.contains(item.url))
          .toList();
      setState(() {
        _dbItems.addAll(newItems);
        _articlesMeta = response.meta;
        _articlesLoadingMore = false;
      });
    } catch (e, st) {
      developer.log('Failed to load more articles', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _articlesLoadingMore = false);
    }
  }

  Future<void> _loadArchive() async {
    setState(() {
      _archiveLoading = true;
      _archiveError = null;
    });
    try {
      final news = AppScope.of(context).news;
      final response = await news.getArchive(page: 1, limit: 20);
      if (!mounted) return;
      setState(() {
        _archive = response.data.map(NewsItem.fromDbArticle).toList();
        _archiveMeta = response.meta;
        _archiveLoading = false;
      });
    } catch (e, st) {
      developer.log('Failed to load archive', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _archiveLoading = false;
        _archiveError = 'Archiv konnte nicht geladen werden.';
      });
    }
  }

  Future<void> _loadMoreArchive() async {
    if (_archiveLoadingMore || _archiveMeta == null || !_archiveMeta!.hasMore) {
      return;
    }
    setState(() => _archiveLoadingMore = true);
    try {
      final news = AppScope.of(context).news;
      final response = await news.getArchive(
        page: _archiveMeta!.page + 1,
        limit: 20,
      );
      if (!mounted) return;
      setState(() {
        _archive.addAll(response.data.map(NewsItem.fromDbArticle));
        _archiveMeta = response.meta;
        _archiveLoadingMore = false;
      });
    } catch (e, st) {
      developer.log('Failed to load more archive', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _archiveLoadingMore = false);
    }
  }

  bool _isVoted(NewsItem item) {
    if (item.id != null && _votedIds.contains(item.id)) return true;
    return _votedUrls.contains(item.url);
  }

  Future<void> _toggleVote(NewsItem item) async {
    if (_isVoted(item)) {
      final id = item.id;
      if (id == null) return;
      try {
        final news = AppScope.of(context).news;
        await news.removeVote(id);
        if (!mounted) return;
        setState(() {
          _votedIds.remove(id);
          _votedUrls.remove(item.url);
        });
      } catch (e, st) {
        developer.log('Failed to remove vote', error: e, stackTrace: st);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fehler beim Aktualisieren.')),
        );
      }
    } else {
      try {
        final news = AppScope.of(context).news;
        final response = await news.vote(
          url: item.url,
          title: item.title,
          sourceName: item.sourceName,
          sourceIcon: item.sourceIcon,
        );
        if (!mounted) return;
        final articleId = response['data']['articleId'] as String;
        setState(() {
          _votedIds.add(articleId);
          _votedUrls.add(item.url);
          final dbIndex = _dbItems.indexWhere((i) => i.url == item.url);
          if (dbIndex != -1) {
            _dbItems[dbIndex] = _dbItems[dbIndex].copyWith(id: articleId);
          }
          final rssIndex = _rssItems.indexWhere((i) => i.url == item.url);
          if (rssIndex != -1) {
            _rssItems[rssIndex] = _rssItems[rssIndex].copyWith(id: articleId);
          }
        });
      } catch (e, st) {
        developer.log('Failed to vote', error: e, stackTrace: st);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fehler beim Aktualisieren.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Neuigkeiten'),
            Tab(text: 'Archiv'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildArticlesTab(), _buildArchiveTab()],
          ),
        ),
      ],
    );
  }

  Widget _buildArticlesTab() {
    final theme = Theme.of(context);

    if (_articlesLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_articlesError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 8),
            Text(_articlesError!, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: _loadArticles,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    if (_dbItems.isEmpty && _rssItems.isEmpty) {
      return Center(
        child: Text(
          'Keine Artikel vorhanden.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final grid = _computeGridLayout(constraints.maxWidth);
        return RefreshIndicator(
          onRefresh: _loadArticles,
          child: CustomScrollView(
            controller: _articlesScrollController,
            slivers: [
              if (_dbItems.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _SectionHeader(title: 'Empfohlene Artikel'),
                ),
                SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: grid.crossAxisCount,
                    mainAxisExtent: grid.mainAxisExtent,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => NewsCard(
                      item: _dbItems[index],
                      voted: _isVoted(_dbItems[index]),
                      onToggleVote: () => _toggleVote(_dbItems[index]),
                    ),
                    childCount: _dbItems.length,
                  ),
                ),
              ],
              if (_rssItems.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _SectionHeader(title: 'Neueste Artikel'),
                ),
                SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: grid.crossAxisCount,
                    mainAxisExtent: grid.mainAxisExtent,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => NewsCard(
                      item: _rssItems[index],
                      voted: _isVoted(_rssItems[index]),
                      onToggleVote: () => _toggleVote(_rssItems[index]),
                    ),
                    childCount: _rssItems.length,
                  ),
                ),
              ],
              SliverToBoxAdapter(child: _buildArticlesFooter(theme)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildArticlesFooter(ThemeData theme) {
    if (_articlesLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 3)),
      );
    }

    if (_articlesMeta?.hasMore == true) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _loadMoreArticles,
            icon: const Icon(Icons.expand_more),
            label: const Text('Mehr laden'),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildArchiveTab() {
    final theme = Theme.of(context);

    if (_archiveLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_archiveError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 8),
            Text(_archiveError!, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: _loadArchive,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    if (_archive.isEmpty) {
      return Center(
        child: Text(
          'Archiv ist leer.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final grid = _computeGridLayout(constraints.maxWidth);
        return RefreshIndicator(
          onRefresh: _loadArchive,
          child: CustomScrollView(
            controller: _archiveScrollController,
            slivers: [
              SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: grid.crossAxisCount,
                  mainAxisExtent: grid.mainAxisExtent,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => NewsCard(
                    item: _archive[index],
                    voted: false,
                    showVoteButton: false,
                  ),
                  childCount: _archive.length,
                ),
              ),
              SliverToBoxAdapter(child: _buildArchiveFooter(theme)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildArchiveFooter(ThemeData theme) {
    if (_archiveLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 3)),
      );
    }

    if (_archiveMeta?.hasMore == true) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _loadMoreArchive,
            icon: const Icon(Icons.expand_more),
            label: const Text('Mehr laden'),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  _GridLayout _computeGridLayout(double width) {
    const padding = 16.0;
    const gap = 12.0;
    int crossAxisCount;
    if (width < 600) {
      crossAxisCount = 1;
    } else if (width < 900) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 3;
    }
    final columnWidth =
        (width - padding * 2 - gap * (crossAxisCount - 1)) / crossAxisCount;
    final imageHeight = columnWidth / 16 * 9;
    const textAreaHeight = 136.0;
    return _GridLayout(
      crossAxisCount: crossAxisCount,
      mainAxisExtent: imageHeight + textAreaHeight,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Icon(Icons.star_rounded, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _GridLayout {
  final int crossAxisCount;
  final double mainAxisExtent;

  const _GridLayout({
    required this.crossAxisCount,
    required this.mainAxisExtent,
  });
}
