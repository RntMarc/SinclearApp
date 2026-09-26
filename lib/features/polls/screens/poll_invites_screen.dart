import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/network/api_client.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/composite/design_list_tile.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../models/poll_models.dart';
import '../poll_error_messages.dart';
import '../widgets/poll_user_picker_sheet.dart';

/// Verwaltung der Einladungen einer Umfrage (nur Ersteller/Admin).
class PollInvitesScreen extends StatefulWidget {
  const PollInvitesScreen({required this.pollId, super.key});

  final String pollId;

  @override
  State<PollInvitesScreen> createState() => _PollInvitesScreenState();
}

class _PollInvitesScreenState extends State<PollInvitesScreen> {
  List<PollInvite> _invites = [];
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final response = await AppScope.of(
        context,
      ).polls.listInvites(widget.pollId);
      if (!mounted) return;
      setState(() {
        _invites = response.data;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = pollErrorMessage(e);
      });
    } catch (e, st) {
      developer.log('Failed to load invites', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Einladungen konnten nicht geladen werden.';
      });
    }
  }

  Future<void> _addUsers() async {
    setState(() => _busy = true);
    try {
      final scope = AppScope.of(context);
      final all = await scope.user.listAll();
      if (!mounted) return;
      final invitedIds = _invites.map((i) => i.userId).toSet();
      final selected = await showDesignSheet<List<String>>(
        context: context,
        child: PollUserPickerSheet(users: all, excludedIds: invitedIds),
      );
      if (selected == null || selected.isEmpty) return;
      final response = await scope.polls.addInvites(widget.pollId, selected);
      if (!mounted) return;
      setState(() => _invites = response.data);
    } on ApiException catch (e) {
      _showMessage(pollErrorMessage(e));
    } catch (e, st) {
      developer.log('Failed to invite users', error: e, stackTrace: st);
      _showMessage('Einladen fehlgeschlagen.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(PollInvite invite) async {
    setState(() => _busy = true);
    try {
      await AppScope.of(
        context,
      ).polls.removeInvite(widget.pollId, invite.userId);
      await _load();
    } on ApiException catch (e) {
      _showMessage(pollErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return DesignSurface(
      child: Column(
        children: <Widget>[
          DesignSubpageHeader(
            leading: DesignIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: 'Einladungen',
            actions: <Widget>[
              DesignIconButton(
                icon: Icons.person_add_rounded,
                onPressed: _busy ? null : _addUsers,
              ),
            ],
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
        child: DesignText(
          _error!,
          style: DesignTextStyle.body,
          color: tokens.textHigh,
        ),
      );
    }
    if (_invites.isEmpty) {
      return Center(
        child: DesignText(
          'Noch keine Einladungen.',
          style: DesignTextStyle.body,
          color: tokens.textLow,
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceLg,
        vertical: tokens.spaceSm,
      ),
      itemCount: _invites.length,
      itemBuilder: (context, index) {
        final invite = _invites[index];
        return Padding(
          padding: EdgeInsets.only(bottom: tokens.spaceSm),
          child: DesignListTile(
            title: invite.userDisplayName ?? 'Unbekannt',
            subtitle: invite.isIndispensable ? 'Unverzichtbar' : null,
            trailing: DesignIconButton(
              icon: Icons.person_remove_rounded,
              onPressed: _busy ? null : () => _remove(invite),
            ),
          ),
        );
      },
    );
  }
}
