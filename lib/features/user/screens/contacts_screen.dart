import 'dart:developer' as developer;
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/app_scope.dart';
import '../models/user_models.dart';
import '../widgets/user_card.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<UserBasePublic>? _users;
  bool _loading = true;
  String? _error;
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
    setState(() => _loading = true);
    try {
      final scope = AppScope.of(context);
      final userId = scope.auth.userId;
      await scope.auth.getAccessToken();
      final users = await scope.user.listAll();
      users.sort((a, b) {
        if (a.id == userId) return -1;
        if (b.id == userId) return 1;
        return a.displayName.compareTo(b.displayName);
      });
      if (!mounted) return;
      setState(() {
        _users = users;
        _loading = false;
        _error = null;
      });
    } catch (e, st) {
      developer.log('Failed to load users', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Benutzer konnten nicht geladen werden.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (_error != null || _users == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 48,
              color: CupertinoColors.destructiveRed,
            ),
            const SizedBox(height: 8),
            Text(_error ?? 'Unbekannter Fehler'),
            const SizedBox(height: 16),
            CupertinoButton(
              onPressed: _load,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    final userId = AppScope.of(context).auth.userId;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _users!.length,
      itemBuilder: (context, index) {
        final user = _users![index];
        final isSelf = user.id == userId;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: UserCard(
            user: user,
            isSelf: isSelf,
            onTap: () => context.go('/kontakte/${user.id}'),
          ),
        );
      },
    );
  }
}
