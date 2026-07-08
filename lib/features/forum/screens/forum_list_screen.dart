import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/app_scope.dart';
import '../models/forum_models.dart';
import '../widgets/forum_card.dart';

class ForumListScreen extends StatefulWidget {
  const ForumListScreen({super.key});

  @override
  State<ForumListScreen> createState() => _ForumListScreenState();
}

class _ForumListScreenState extends State<ForumListScreen> {
  List<Forum> _allForums = [];
  bool _loading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_allForums.isEmpty && _loading) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final forumService = AppScope.of(context).forum;
      final response = await forumService.list(limit: 20);
      if (!mounted) return;
      setState(() {
        _allForums = response.data;
        _loading = false;
      });
    } catch (e, st) {
      developer.log('Failed to load forums', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Foren konnten nicht geladen werden.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final myForums = _allForums.where((f) {
      return f.memberCount > 0;
    }).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('FORUM'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Meine Foren'),
              Tab(text: 'Alle Foren'),
            ],
          ),
        ),
        body: _buildBody(context, myForums),
      ),
    );
  }

  Widget _buildBody(BuildContext context, List<Forum> myForums) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 8),
            Text(_error!),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: _load,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: TabBarView(
        children: [
          _ForumList(
            forums: myForums,
            emptyText: 'Du bist noch keinem Forum beigetreten.',
            onForumTap: (forum) => context.go('/forum/${forum.id}'),
          ),
          _ForumList(
            forums: _allForums,
            emptyText: 'Keine Foren vorhanden.',
            onForumTap: (forum) => context.go('/forum/${forum.id}'),
          ),
        ],
      ),
    );
  }
}

class _ForumList extends StatelessWidget {
  final List<Forum> forums;
  final String emptyText;
  final ValueChanged<Forum> onForumTap;

  const _ForumList({
    required this.forums,
    required this.emptyText,
    required this.onForumTap,
  });

  @override
  Widget build(BuildContext context) {
    if (forums.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: forums.length,
      itemBuilder: (context, index) {
        final forum = forums[index];
        return ForumCard(
          forum: forum,
          onTap: () => onForumTap(forum),
        );
      },
    );
  }
}
