import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/utils/date_utils.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_pulse_dot.dart';
import '../../../design/widgets/primitives/press_scale.dart';
import '../../forum/models/forum_models.dart';
import '../../forum/services/forum_service.dart';
import '../dashboard_widget.dart';
import '../dashboard_widget_spec.dart';

/// Anzeige-Datensatz eines Foren-Beitrags (über alle Foren gemischt).
class ForumRow implements DashboardRow {
  final String postId;
  final String forumId;
  final String forumName;
  final String createdAt;
  final String? userName;
  final String? title;
  final String? text;

  const ForumRow({
    required this.postId,
    required this.forumId,
    required this.forumName,
    required this.createdAt,
    this.userName,
    this.title,
    this.text,
  });

  factory ForumRow.fromPost(FeedPost post, String forumName) {
    return ForumRow(
      postId: post.id,
      forumId: post.forumId,
      forumName: forumName,
      createdAt: post.createdAt,
      userName: post.userName,
      title: post.title,
      text: post.text,
    );
  }

  factory ForumRow.fromJson(Map<String, dynamic> json) {
    return ForumRow(
      postId: json['postId'] as String,
      forumId: json['forumId'] as String,
      forumName: json['forumName'] as String,
      createdAt: json['createdAt'] as String,
      userName: json['userName'] as String?,
      title: json['title'] as String?,
      text: json['text'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'postId': postId,
    'forumId': forumId,
    'forumName': forumName,
    'createdAt': createdAt,
    'userName': userName,
    'title': title,
    'text': text,
  };
}

/// Widget „Neue Beiträge“ – die neuesten Beiträge aller sichtbaren Foren
/// (öffentliche plus Mitgliedschaften), gemischt und sortiert über den
/// aggregierten Feed-Endpunkt `GET /forums/feed` (ein Request statt N+1).
class ForumWidgetSpec extends DashboardWidgetSpec {
  ForumWidgetSpec(this._service);

  final ForumService _service;

  @override
  DashboardWidgetType get type => DashboardWidgetType.forumPosts;

  @override
  String get listRoute => '/forum';

  @override
  Future<List<DashboardRow>> fetch(int count) async {
    final response = await _service.getFeed(page: 1, limit: count);
    return [
      for (final post in response.data)
        ForumRow.fromPost(post, post.forumName ?? ''),
    ];
  }

  @override
  DashboardRow rowFromJson(Map<String, dynamic> json) =>
      ForumRow.fromJson(json);

  @override
  Widget rowBuilder(
    BuildContext context,
    DashboardRow row,
    VoidCallback? onTap,
  ) {
    final post = row as ForumRow;
    final tokens = DesignTheme.of(context);
    return PressScale(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tokens.surfaceVariant,
              borderRadius: BorderRadius.circular(tokens.radiusMd),
            ),
            child: Icon(Icons.forum_rounded, size: 18, color: tokens.primary),
          ),
          SizedBox(width: tokens.spaceMd),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DesignText(
                  post.title ?? post.text ?? 'Neuer Beitrag',
                  style: DesignTextStyle.body,
                  color: tokens.textHigh,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: tokens.spaceXs),
                DesignText(
                  [
                    post.forumName,
                    if (post.userName != null) post.userName!,
                    formatRelativeDate(post.createdAt),
                  ].join(' · '),
                  style: DesignTextStyle.label,
                  color: tokens.textLow,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ListenableBuilder(
            listenable: AppScope.of(context).notification,
            builder: (context, _) =>
                AppScope.of(
                  context,
                ).notification.unreadIdsForPost(post.postId).isNotEmpty
                ? const DesignPulseDot(size: 8)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  @override
  void onRowTap(BuildContext context, DashboardRow row) {
    final post = row as ForumRow;
    context.go('/forum/${post.forumId}/beitrag/${post.postId}');
  }
}
