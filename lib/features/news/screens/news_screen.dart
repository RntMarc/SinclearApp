import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/di/app_scope.dart';
import '../models/news_models.dart';

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

  List<NewsItem> _items = [];
  PaginationMeta? _articlesMeta;
  bool _articlesLoading = true;
  bool _articlesLoadingMore = false;
  String? _articlesError;

  List<NewsItem> _archive = [];
  PaginationMeta? _archiveMeta;
  bool _archiveLoading = true;
  bool _archiveLoadingMore = false;

  Set<String> _votedIds = {};
  Set<String> _votedUrls = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _articlesScrollController.addListener(_onArticlesScroll);
    _archiveScrollController.addListener(_onArchiveScroll);
    _loadArticles();
    _loadArchive();
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
            _articlesScrollController.position.maxScrollExtent - 200 &&
        !_articlesLoadingMore &&
        _articlesMeta?.hasMore == true) {
      _loadMoreArticles();
    }
  }

  void _onArchiveScroll() {
    if (_archiveScrollController.position.pixels >=
            _archiveScrollController.position.maxScrollExtent - 200 &&
        !_archiveLoadingMore &&
        _archiveMeta?.hasMore == true) {
      _loadMoreArchive();
    }
  }

  List<NewsItem> _mergeArticles(
    List<NewsArticle> data,
    List<RssArticle> rss,
  ) {
    final urlToItem = <String, NewsItem>{};

    for (final article in data) {
      urlToItem[article.url] = NewsItem.fromDbArticle(article);
    }

    for (final article in rss) {
      urlToItem.putIfAbsent(
        article.url,
        () => NewsItem.fromRssArticle(article),
      );
    }

    final items = urlToItem.values.toList();
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
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
        _items = _mergeArticles(articlesResp.data, articlesResp.rss);
        _articlesMeta = articlesResp.meta;
        _votedIds = votesResp.data.map((a) => a.id).toSet();
        _votedUrls = votesResp.data.map((a) => a.url).toSet();
        _articlesLoading = false;
      });
    } catch (_) {
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
      final existingUrls = _items.map((e) => e.url).toSet();
      final newItems = response.data
          .map(NewsItem.fromDbArticle)
          .where((item) => !existingUrls.contains(item.url))
          .toList();
      setState(() {
        _items.addAll(newItems);
        _items.sort((a, b) => b.date.compareTo(a.date));
        _articlesMeta = response.meta;
        _articlesLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _articlesLoadingMore = false);
    }
  }

  Future<void> _loadArchive() async {
    setState(() => _archiveLoading = true);
    try {
      final news = AppScope.of(context).news;
      final response = await news.getArchive(page: 1, limit: 20);
      if (!mounted) return;
      setState(() {
        _archive = response.data.map(NewsItem.fromDbArticle).toList();
        _archiveMeta = response.meta;
        _archiveLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _archiveLoading = false);
    }
  }

  Future<void> _loadMoreArchive() async {
    if (_archiveLoadingMore ||
        _archiveMeta == null ||
        !_archiveMeta!.hasMore) {
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
    } catch (_) {
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
      } catch (_) {
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
          final index = _items.indexWhere((i) => i.url == item.url);
          if (index != -1) {
            _items[index] = _items[index].copyWith(id: articleId);
          }
        });
      } catch (_) {
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
            children: [
              _buildArticlesTab(),
              _buildArchiveTab(),
            ],
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
            Icon(Icons.error_outline,
                size: 48, color: theme.colorScheme.error),
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

    if (_items.isEmpty) {
      return Center(
        child: Text(
          'Keine Artikel vorhanden.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadArticles,
      child: ListView.builder(
        controller: _articlesScrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _items.length + (_articlesLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final item = _items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _NewsCard(
              item: item,
              voted: _isVoted(item),
              onToggleVote: () => _toggleVote(item),
            ),
          );
        },
      ),
    );
  }

  Widget _buildArchiveTab() {
    final theme = Theme.of(context);

    if (_archiveLoading) {
      return const Center(child: CircularProgressIndicator());
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

    return RefreshIndicator(
      onRefresh: _loadArchive,
      child: ListView.builder(
        controller: _archiveScrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _archive.length + (_archiveLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _archive.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final item = _archive[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _NewsCard(
              item: item,
              voted: false,
              showVoteButton: false,
            ),
          );
        },
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final NewsItem item;
  final bool voted;
  final bool showVoteButton;
  final VoidCallback? onToggleVote;

  const _NewsCard({
    required this.item,
    required this.voted,
    this.showVoteButton = true,
    this.onToggleVote,
  });

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = _formatDate(item.date);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          final uri = Uri.tryParse(item.url);
          if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: item.sourceIcon != null
                    ? NetworkImage(item.sourceIcon!)
                    : null,
                child: item.sourceIcon == null
                    ? const Icon(Icons.rss_feed_rounded, size: 20)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.sourceName} · $dateStr',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (showVoteButton && onToggleVote != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onToggleVote,
                  icon: Icon(
                    voted
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: voted ? Colors.red : null,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
