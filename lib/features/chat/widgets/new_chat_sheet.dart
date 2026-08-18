import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/app_scope.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_list_tile.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_avatar.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_text_field.dart';
import '../../user/models/user_models.dart';

/// Sheet zum Starten einer neuen 1:1-Unterhaltung: Nutzersuche (Name)
/// und Start per Antippen.
class NewChatSheet extends StatefulWidget {
  const NewChatSheet({super.key});

  @override
  State<NewChatSheet> createState() => _NewChatSheetState();
}

class _NewChatSheetState extends State<NewChatSheet> {
  List<UserBasePublic> _users = [];
  bool _loading = true;
  String? _error;
  String _query = '';
  String? _currentUserId;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final scope = AppScope.of(context);
      final users = await scope.user.listAll();
      if (!mounted) return;
      setState(() {
        _users = users;
        _currentUserId = scope.auth.userId;
        _loading = false;
        _error = null;
      });
    } catch (e, st) {
      developer.log(
        'Loading users for new chat failed',
        error: e,
        stackTrace: st,
        name: 'new_chat_sheet',
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Nutzer konnten nicht geladen werden.';
      });
    }
  }

  Future<void> _startChat(UserBasePublic user) async {
    final scope = AppScope.of(context);
    try {
      final conversation = await scope.chat.openConversation(user.id);
      if (!mounted) return;
      Navigator.pop(context);
      context.push('/chat/${conversation.id}');
    } catch (e, st) {
      developer.log(
        'openConversation failed',
        error: e,
        stackTrace: st,
        name: 'new_chat_sheet',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: DesignText(
            'Chat konnte nicht geöffnet werden.',
            color: DesignTheme.of(context).textOnPrimary,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final query = _query.trim().toLowerCase();
    final candidates = _users
        .where((u) => u.id != _currentUserId)
        .where(
          (u) => query.isEmpty || u.displayName.toLowerCase().contains(query),
        )
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DesignText(
          'Neue Nachricht',
          style: DesignTextStyle.subtitle,
          color: tokens.textHigh,
        ),
        SizedBox(height: tokens.spaceLg),
        DesignTextField(
          hint: 'Nach Name suchen...',
          prefixIcon: Icons.search_rounded,
          onChanged: (value) => setState(() => _query = value),
        ),
        SizedBox(height: tokens.spaceMd),
        if (_loading)
          Padding(
            padding: EdgeInsets.all(tokens.spaceLg),
            child: Center(
              child: CircularProgressIndicator(color: tokens.primary),
            ),
          )
        else if (_error != null)
          Padding(
            padding: EdgeInsets.all(tokens.spaceLg),
            child: Column(
              children: [
                DesignText(_error!, style: DesignTextStyle.body),
                SizedBox(height: tokens.spaceMd),
                DesignButton(
                  label: 'Erneut versuchen',
                  variant: DesignButtonVariant.outlined,
                  onPressed: _load,
                ),
              ],
            ),
          )
        else if (candidates.isEmpty)
          Padding(
            padding: EdgeInsets.all(tokens.spaceLg),
            child: Center(
              child: DesignText(
                'Keine Nutzer gefunden.',
                style: DesignTextStyle.body,
                color: tokens.textLow,
              ),
            ),
          )
        else
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: candidates.length,
              itemBuilder: (context, index) {
                final user = candidates[index];
                return DesignListTile(
                  leading: DesignAvatar(
                    imageUrl: user.image,
                    name: user.displayName,
                    size: 40,
                  ),
                  title: user.displayName,
                  onTap: () => _startChat(user),
                );
              },
            ),
          ),
      ],
    );
  }
}
