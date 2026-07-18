import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/app_scope.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
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
    final tokens = DesignTheme.of(context);
    final myForums = _allForums.where((f) {
      return f.memberCount > 0;
    }).toList();

    return DesignSurface(
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              labelColor: tokens.primary,
              unselectedLabelColor: tokens.textLow,
              indicatorColor: tokens.primary,
              labelStyle: TextStyle(
                fontFamily: tokens.fontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: TextStyle(
                fontFamily: tokens.fontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              tabs: const [
                Tab(text: 'Meine Foren'),
                Tab(text: 'Alle Foren'),
              ],
            ),
            Expanded(child: _buildBody(context, myForums, tokens)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<Forum> myForums,
    DesignTokens tokens,
  ) {
    if (_loading) {
      return RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 120),
              Center(child: CircularProgressIndicator(color: tokens.primary)),
            ],
          ),
        ),
      );
    }
    if (_error != null) {
      return RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          child: Column(
            children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: tokens.danger),
                  SizedBox(height: tokens.spaceSm),
                  DesignText(_error!, style: DesignTextStyle.body, color: tokens.textHigh),
                  SizedBox(height: tokens.spaceLg),
                  DesignButton(
                    variant: DesignButtonVariant.filled,
                    label: 'Erneut versuchen',
                    onPressed: _load,
                  ),
                ],
              ),
            ),
          ],
        ),
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
    final tokens = DesignTheme.of(context);
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: forums.isEmpty
          ? SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.3,
                  ),
                  Center(
                    child: DesignText(
                      emptyText,
                      style: DesignTextStyle.body,
                      color: tokens.textLow,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(vertical: tokens.spaceSm),
              itemCount: forums.length,
              itemBuilder: (context, index) {
                final forum = forums[index];
                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: tokens.spaceLg,
                    vertical: tokens.spaceXs,
                  ),
                  child: ForumCard(
                    key: ValueKey(forum.id),
                    forum: forum,
                    onTap: () => onForumTap(forum),
                  ),
                );
              },
            ),
    );
  }
}
