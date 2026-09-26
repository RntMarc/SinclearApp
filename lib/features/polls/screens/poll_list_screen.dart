import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/network/api_client.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_chip.dart';
import '../../../design/widgets/primitives/design_fab.dart';
import '../models/poll_models.dart';
import '../poll_error_messages.dart';
import '../widgets/poll_card.dart';

/// Liste aller für den Nutzer sichtbaren Umfragen mit Typ-/Status-Filter.
class PollListScreen extends StatefulWidget {
  const PollListScreen({super.key});

  @override
  State<PollListScreen> createState() => _PollListScreenState();
}

class _PollListScreenState extends State<PollListScreen> {
  static const _pageSize = 20;

  final ScrollController _scrollController = ScrollController();
  final List<Poll> _polls = [];
  PollType? _typeFilter;
  PollStatus? _statusFilter;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load(reset: true);
      _refreshUnread();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _load();
    }
  }

  Future<void> _refreshUnread() async {
    try {
      final scope = AppScope.of(context);
      await scope.notification.refreshUnread(
        token: await scope.auth.getAccessToken(),
      );
    } catch (e) {
      developer.log('refreshUnread failed', error: e);
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _polls.clear();
        _hasMore = true;
      });
    } else {
      if (_loadingMore || !_hasMore) return;
      setState(() => _loadingMore = true);
    }

    try {
      final response = await AppScope.of(context).polls.list(
        type: _typeFilter,
        status: _statusFilter,
        page: reset ? 1 : (_polls.length ~/ _pageSize) + 1,
        limit: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        if (reset) _polls.clear();
        _polls.addAll(response.data);
        _hasMore = response.meta.hasMore;
        _loading = false;
        _loadingMore = false;
      });
    } on ApiException catch (e, st) {
      developer.log('Failed to load polls', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = pollErrorMessage(e);
      });
    } catch (e, st) {
      developer.log('Failed to load polls', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = 'Umfragen konnten nicht geladen werden.';
      });
    }
  }

  void _applyFilter({PollType? type, PollStatus? status, bool clear = false}) {
    setState(() {
      if (clear) {
        _typeFilter = null;
        _statusFilter = null;
      } else {
        _typeFilter = type;
        _statusFilter = status;
      }
    });
    _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return DesignSurface(
      child: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              _buildFilters(tokens),
              Expanded(child: _buildBody(tokens)),
            ],
          ),
          Positioned(
            bottom: tokens.spaceLg,
            right: tokens.spaceLg,
            child: DesignFab(
              icon: Icons.add_rounded,
              tooltip: 'Neue Umfrage',
              onPressed: () => context.go('/umfragen/neu'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(DesignTokens tokens) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceLg,
        vertical: tokens.spaceSm,
      ),
      child: Row(
        children: <Widget>[
          DesignChip(
            label: 'Alle',
            selected: _typeFilter == null && _statusFilter == null,
            onTap: () => _applyFilter(clear: true),
          ),
          SizedBox(width: tokens.spaceSm),
          for (final type in PollType.values) ...<Widget>[
            DesignChip(
              label: type.label,
              selected: _typeFilter == type,
              onTap: () => _applyFilter(type: type),
            ),
            SizedBox(width: tokens.spaceSm),
          ],
          DesignChip(
            label: 'Offen',
            selected: _statusFilter == PollStatus.open,
            onTap: () => _applyFilter(status: PollStatus.open),
          ),
          SizedBox(width: tokens.spaceSm),
          DesignChip(
            label: 'Geschlossen',
            selected: _statusFilter == PollStatus.closed,
            onTap: () => _applyFilter(status: PollStatus.closed),
          ),
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
          children: <Widget>[
            Icon(Icons.error_outline, size: 48, color: tokens.danger),
            SizedBox(height: tokens.spaceSm),
            DesignText(
              _error!,
              style: DesignTextStyle.body,
              color: tokens.textHigh,
            ),
            SizedBox(height: tokens.spaceLg),
            DesignButton(
              label: 'Erneut versuchen',
              onPressed: () => _load(reset: true),
            ),
          ],
        ),
      );
    }

    return ListenableBuilder(
      listenable: AppScope.of(context).notification,
      builder: (context, _) {
        final unread = AppScope.of(context).notification.unreadPollIds;
        return RefreshIndicator(
          onRefresh: () async {
            await _load(reset: true);
            await _refreshUnread();
          },
          child: _polls.isEmpty
              ? SingleChildScrollView(
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.4,
                    child: Center(
                      child: DesignText(
                        'Keine Umfragen vorhanden.',
                        style: DesignTextStyle.body,
                        color: tokens.textLow,
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(
                    top: tokens.spaceXs,
                    bottom: tokens.spaceXxl * 2,
                  ),
                  itemCount: _polls.length + (_loadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= _polls.length) {
                      return Padding(
                        padding: EdgeInsets.all(tokens.spaceLg),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: tokens.primary,
                          ),
                        ),
                      );
                    }
                    final poll = _polls[index];
                    return PollCard(
                      poll: poll,
                      hasUnread: unread.contains(poll.id),
                      onTap: () => context.go('/umfragen/${poll.id}'),
                    );
                  },
                ),
        );
      },
    );
  }
}
