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
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Meine Foren'),
              Tab(text: 'Alle Foren'),
            ],
          ),
          Expanded(child: _buildBody(context, myForums)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, List<Forum> myForums) {
    if (_loading) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(child: CircularProgressIndicator()),
          ],
        ),
      );
    }
    if (_error != null) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
            Center(
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
            ),
          ],
        ),
      );
    }

    return TabBarView(
      children: [
        _ForumList(
          forums: myForums,
          emptyText: 'Du bist noch keinem Forum beigetreten.',
          onForumTap: (forum) => context.go('/forum/${forum.id}'),
          onRefresh: _load,
        ),
        _ForumList(
          forums: _allForums,
          emptyText: 'Keine Foren vorhanden.',
          onForumTap: (forum) => context.go('/forum/${forum.id}'),
          onRefresh: _load,
        ),
      ],
    );
  }
}

class _ForumList extends StatelessWidget {
  final List<Forum> forums;
  final String emptyText;
  final ValueChanged<Forum> onForumTap;
  final Future<void> Function() onRefresh;

  const _ForumList({
    required this.forums,
    required this.emptyText,
    required this.onForumTap,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: forums.isEmpty
          ? ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.3,
                ),
                Center(
                  child: Text(
                    emptyText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: forums.length,
              itemBuilder: (context, index) {
                final forum = forums[index];
                return ForumCard(
                  forum: forum,
                  onTap: () => onForumTap(forum),
                );
              },
            ),
    );
  }
}
