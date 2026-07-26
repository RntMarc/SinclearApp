import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/app_scope.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../models/explore_models.dart';

class SubmissionsListScreen extends StatefulWidget {
  const SubmissionsListScreen({super.key});

  @override
  State<SubmissionsListScreen> createState() => _SubmissionsListScreenState();
}

class _SubmissionsListScreenState extends State<SubmissionsListScreen> {
  List<ExploreSubmission> _submissions = [];
  PaginationMeta? _meta;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  bool _hasLoaded = false;
  final _scrollController = ScrollController();

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

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final explore = AppScope.of(context).explore;
      final response = await explore.getSubmissions();
      if (!mounted) return;
      setState(() {
        _submissions = response.data;
        _meta = response.meta;
        _loading = false;
        _error = null;
      });
    } catch (e, st) {
      developer.log('Failed to load submissions', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Einreichungen konnten nicht geladen werden.';
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _meta == null || !_meta!.hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final explore = AppScope.of(context).explore;
      final response = await explore.getSubmissions(page: _meta!.page + 1);
      if (!mounted) return;
      setState(() {
        _submissions.addAll(response.data);
        _meta = response.meta;
        _loadingMore = false;
      });
    } catch (e, st) {
      developer.log(
        'Failed to load more submissions',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  Color _statusColor(DesignTokens tokens, String status) {
    return switch (status) {
      'pending' => tokens.warning,
      'approved' => tokens.success,
      'rejected' => tokens.danger,
      'transferred' => tokens.primary,
      _ => tokens.textLow,
    };
  }

  String _statusLabel(String status) {
    return switch (status) {
      'pending' => 'In Pruefung',
      'approved' => 'Freigegeben',
      'rejected' => 'Abgelehnt',
      'transferred' => 'Uebernommen',
      _ => status,
    };
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return DesignSurface(
      child: Column(
        children: [
          DesignSubpageHeader(
            leading: DesignIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => Navigator.pop(context),
            ),
            title: 'Meine Einreichungen',
          ),
          Expanded(child: _buildBody(tokens)),
        ],
      ),
    );
  }

  Widget _buildBody(DesignTokens tokens) {
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
              onPressed: _load,
            ),
          ],
        ),
      );
    }

    if (_submissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded, size: 48, color: tokens.textLow),
            SizedBox(height: tokens.spaceSm),
            DesignText(
              'Noch keine Einreichungen vorhanden.',
              style: DesignTextStyle.body,
              color: tokens.textLow,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        controller: _scrollController,
        padding: EdgeInsets.all(tokens.spaceLg),
        itemCount: _submissions.length + (_loadingMore ? 1 : 0),
        separatorBuilder: (_, _) => SizedBox(height: tokens.spaceSm),
        itemBuilder: (context, index) {
          if (index >= _submissions.length) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(tokens.spaceLg),
                child: CircularProgressIndicator(color: tokens.primary),
              ),
            );
          }
          return _SubmissionTile(
            submission: _submissions[index],
            statusColor: _statusColor(tokens, _submissions[index].status),
            statusLabel: _statusLabel(_submissions[index].status),
            onTap: () => context
                .push('/entdecken/neu/einreichungen/${_submissions[index].id}')
                .then((result) {
                  if (result == true && mounted) _load();
                }),
          );
        },
      ),
    );
  }
}

class _SubmissionTile extends StatelessWidget {
  final ExploreSubmission submission;
  final Color statusColor;
  final String statusLabel;
  final VoidCallback onTap;

  const _SubmissionTile({
    required this.submission,
    required this.statusColor,
    required this.statusLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return DesignCard(
      onTap: onTap,
      padding: EdgeInsets.all(tokens.spaceMd),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DesignText(
                  submission.name,
                  style: DesignTextStyle.subtitle,
                  color: tokens.textHigh,
                ),
                if (submission.address != null) ...[
                  SizedBox(height: tokens.spaceXs),
                  DesignText(
                    submission.address!,
                    style: DesignTextStyle.label,
                    color: tokens.textLow,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                SizedBox(height: tokens.spaceXs),
                DesignText(
                  _formatDate(submission.createdAt),
                  style: DesignTextStyle.label,
                  color: tokens.textLow,
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spaceSm,
              vertical: tokens.spaceXs,
            ),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(tokens.radiusSm),
            ),
            child: DesignText(
              statusLabel,
              style: DesignTextStyle.label,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String date) {
    try {
      final parts = date.split(' ');
      return parts.first;
    } catch (_) {
      return date;
    }
  }
}
