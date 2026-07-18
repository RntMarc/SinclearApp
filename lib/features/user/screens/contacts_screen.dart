import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/app_scope.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../models/user_models.dart';
import '../widgets/user_card.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final List<UserBasePublic> users = [];
  bool isLoading = true;
  String? error;
  String? currentUserId;
  bool _hasLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      _hasLoaded = true;
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final scope = AppScope.of(context);
      final loaded = await scope.user.listAll();
      if (!mounted) return;
      setState(() {
        users
          ..clear()
          ..addAll(loaded);
        currentUserId = scope.auth.userId;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = 'Kontakte konnten nicht geladen werden.';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return DesignSurface(
        child: Center(
          child: CircularProgressIndicator(color: DesignTheme.of(context).primary),
        ),
      );
    }

    if (error != null) {
      return DesignSurface(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                DesignText(error!, style: DesignTextStyle.body),
                const SizedBox(height: 16),
                DesignButton(
                  label: 'Erneut versuchen',
                  variant: DesignButtonVariant.outlined,
                  onPressed: _load,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (users.isEmpty) {
      return const DesignSurface(
        child: Center(
          child: DesignText(
            'Keine Kontakte gefunden.',
            style: DesignTextStyle.body,
          ),
        ),
      );
    }

    return DesignSurface(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          final isSelf = user.id == currentUserId;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: UserCard(
              user: user,
              isSelf: isSelf,
              onTap: () => context.push('/kontakte/${user.id}'),
            ),
          );
        },
      ),
    );
  }
}
