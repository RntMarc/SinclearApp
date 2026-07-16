import 'package:flutter/material.dart';
import '../foundation/design_text.dart';
import '../primitives/design_avatar.dart';
import '../primitives/design_badge.dart';
import '../primitives/design_card.dart';

/// A person/contact row built entirely from catalog primitives.
///
/// It composes [DesignCard], [DesignAvatar], [DesignText] and [DesignBadge] so
/// it follows the active design variant. Feature screens map their model onto
/// these plain parameters through a thin adapter (e.g. `UserCard`).
class DesignUserCard extends StatelessWidget {
  const DesignUserCard({
    this.imageUrl,
    required this.name,
    this.subtitle,
    this.isSelf = false,
    this.onTap,
    super.key,
  });

  final String? imageUrl;
  final String name;
  final String? subtitle;
  final bool isSelf;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return DesignCard(
      onTap: onTap,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: <Widget>[
          DesignAvatar(
            imageUrl: imageUrl,
            name: name,
            size: 48,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DesignText(
                  name,
                  style: DesignTextStyle.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  DesignText(
                    subtitle!,
                    style: DesignTextStyle.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (isSelf) const DesignBadge(label: 'Das bist du'),
        ],
      ),
    );
  }
}
