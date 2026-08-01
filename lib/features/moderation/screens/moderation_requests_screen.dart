import 'dart:developer' as developer;
import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/utils/date_utils.dart' as app_date;
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_divider.dart';
import '../models/moderation_models.dart';

/// Eigene Meldungen und Anfragen inklusive Status und Admin-Kommentar.
class ModerationRequestsScreen extends StatefulWidget {
  const ModerationRequestsScreen({super.key});

  @override
  State<ModerationRequestsScreen> createState() =>
      _ModerationRequestsScreenState();
}

class _ModerationRequestsScreenState extends State<ModerationRequestsScreen> {
  final List<ModerationRequest> _requests = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  String? _error;

  bool _didLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoad) {
      _didLoad = true;
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await AppScope.of(context).moderation.listMine();
      if (!mounted) return;
      setState(() {
        _requests
          ..clear()
          ..addAll(response.data);
        _hasMore = response.meta.hasMore;
        _loading = false;
      });
    } catch (e, st) {
      developer.log(
        'Failed to load moderation requests',
        name: 'moderation',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Anfragen konnten nicht geladen werden.';
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final page = _requests.length ~/ 20 + 1;
      final response = await AppScope.of(
        context,
      ).moderation.listMine(page: page);
      if (!mounted) return;
      setState(() {
        _requests.addAll(response.data);
        _hasMore = response.meta.hasMore;
        _loadingMore = false;
      });
    } catch (e, st) {
      developer.log(
        'Failed to load more moderation requests',
        name: 'moderation',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return DesignSurface(child: _buildBody(tokens));
  }

  Widget _buildBody(DesignTokens tokens) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: tokens.primary));
    }

    if (_error != null) {
      return RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: tokens.spaceXl),
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
            ),
          ),
        ),
      );
    }

    if (_requests.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: tokens.spaceXl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flag_outlined, size: 48, color: tokens.textLow),
                  SizedBox(height: tokens.spaceSm),
                  DesignText(
                    'Noch keine Anfragen.',
                    style: DesignTextStyle.body,
                    color: tokens.textHigh,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: EdgeInsets.all(tokens.spaceLg),
        itemCount: _requests.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _requests.length) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: tokens.spaceSm),
              child: Center(
                child: _loadingMore
                    ? CircularProgressIndicator(color: tokens.primary)
                    : DesignButton(
                        variant: DesignButtonVariant.outlined,
                        label: 'Mehr laden',
                        onPressed: _loadMore,
                      ),
              ),
            );
          }
          return _RequestCard(request: _requests[index]);
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final ModerationRequest request;

  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final statusColor = switch (request.status) {
      ModerationRequestStatus.accepted => tokens.success,
      ModerationRequestStatus.denied => tokens.danger,
      _ => tokens.textLow,
    };

    return Padding(
      padding: EdgeInsets.only(bottom: tokens.spaceMd),
      child: DesignCard(
        margin: EdgeInsets.zero,
        padding: EdgeInsets.all(tokens.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(request.requestType.icon, size: 20, color: tokens.primary),
                SizedBox(width: tokens.spaceSm),
                Expanded(
                  child: DesignText(
                    '${request.requestType.label} · '
                    '${request.objectType.label}',
                    style: DesignTextStyle.label,
                    color: tokens.textHigh,
                  ),
                ),
                DesignText(
                  request.status.label,
                  style: DesignTextStyle.label,
                  color: statusColor,
                ),
              ],
            ),
            SizedBox(height: tokens.spaceXs),
            DesignText(
              app_date.formatDateTime(app_date.parseApiDate(request.createdAt)),
              style: DesignTextStyle.label,
              color: tokens.textLow.withValues(alpha: 0.6),
            ),
            SizedBox(height: tokens.spaceSm),
            DesignText(
              request.message,
              style: DesignTextStyle.body,
              color: tokens.textHigh,
            ),
            if (request.adminComment != null) ...[
              SizedBox(height: tokens.spaceSm),
              const DesignDivider(),
              SizedBox(height: tokens.spaceSm),
              DesignText(
                'Antwort des Admins: ${request.adminComment}',
                style: DesignTextStyle.body,
                color: tokens.textLow,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
