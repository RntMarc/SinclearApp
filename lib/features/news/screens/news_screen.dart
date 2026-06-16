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

  List<NewsArticle> _articles = [];
  PaginationMeta? _articlesMeta;
  bool _articlesLoading = true;
  bool _articlesLoadingMore = false;
  String? _articlesError;

  List<NewsArticle> _archive = [];
  PaginationMeta? _archiveMeta;
  bool _archiveLoading = true;
  bool _archiveLoadingMore = false;

  Set<String> _votedIds = {};

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
      setState(() {
        final articlesResp = results[0];
        final votesResp = results[1];
        _articles = articlesResp.data;
        _articlesMeta = articlesResp.meta;
        _votedIds = votesResp.data.map((a) => a.id).toSet();
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
      setState(() {
        _articles.addAll(response.data);
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
        _archive = response.data;
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
        _archive.addAll(response.data);
        _archiveMeta = response.meta;
        _archiveLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _archiveLoadingMore = false);
    }
  }

  Future<void> _toggleVote(NewsArticle article) async {
    final isVoted = _votedIds.contains(article.id);
    try {
      final news = AppScope.of(context).news;
      if (isVoted) {
        await news.removeVote(article.id);
        if (!mounted) return;
        setState(() => _votedIds.remove(article.id));
      } else {
        await news.vote(
          url: article.url,
          title: article.title,
          sourceName: article.sourceName,
          sourceIcon: article.sourceIcon,
        );
        if (!mounted) return;
        setState(() => _votedIds.add(article.id));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fehler beim Aktualisieren.')),
      );
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

    if (_articles.isEmpty) {
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
        itemCount: _articles.length + (_articlesLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _articles.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final article = _articles[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _NewsCard(
              article: article,
              voted: _votedIds.contains(article.id),
              onToggleVote: () => _toggleVote(article),
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
          final article = _archive[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _NewsCard(
              article: article,
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
  final NewsArticle article;
  final bool voted;
  final bool showVoteButton;
  final VoidCallback? onToggleVote;

  const _NewsCard({
    required this.article,
    required this.voted,
    this.showVoteButton = true,
    this.onToggleVote,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = article.savedAt.length >= 10
        ? article.savedAt.substring(0, 10)
        : article.savedAt;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          final uri = Uri.tryParse(article.url);
          if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: article.sourceIcon != null
                    ? NetworkImage(article.sourceIcon!)
                    : null,
                child: article.sourceIcon == null
                    ? const Icon(Icons.rss_feed_rounded, size: 20)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${article.sourceName} · $date',
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
                    voted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
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
