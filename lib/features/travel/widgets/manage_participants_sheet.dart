import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/network/api_client.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/composite/design_list_tile.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_avatar.dart';
import '../../../design/widgets/primitives/design_badge.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../models/travel_models.dart';
import '../travel_error_messages.dart';
import 'accommodation_picker_sheet.dart';

/// Modell-unabhängige Zeile eines Reise-/Event-Teilnehmers.
class TravelParticipantEntry {
  final String id;
  final String displayName;
  final String? image;
  final String? role;

  const TravelParticipantEntry({
    required this.id,
    required this.displayName,
    this.image,
    this.role,
  });

  bool get isLeader => role == 'leader';
}

/// Öffnet die Teilnehmer-Verwaltung (Hinzufügen, Rolle setzen, Entfernen).
///
/// Das Sheet lädt die Teilnehmer selbst über [load] und ruft nach jeder
/// Aktion [load] erneut auf. [roleLabel] benennt die Führungsrolle
/// (z. B. „Reiseleiter“ oder „Veranstalter“).
///
/// [setRole] ist optional; ohne Callback werden die Rollen-Aktionen
/// ausgeblendet. [loadCandidates] schränkt die Kandidatenliste ein (z. B. auf
/// die Reiseteilnehmer bei Reise-Events), sonst werden alle Nutzer angeboten.
/// [loadAccommodations] + [assignAccommodation] aktivieren die
/// Unterkunftszuweisung pro Teilnehmer.
Future<void> showManageParticipantsSheet({
  required BuildContext context,
  required String title,
  required String roleLabel,
  required Future<List<TravelParticipantEntry>> Function() load,
  required Future<void> Function(String userId) add,
  required Future<void> Function(String userId) remove,
  Future<void> Function(String userId, String role)? setRole,
  Future<List<TravelParticipantEntry>> Function()? loadCandidates,
  Future<List<TravelAccommodation>> Function()? loadAccommodations,
  Future<void> Function(String userId, String? accommodationId)?
  assignAccommodation,
}) {
  return showDesignSheet<void>(
    context: context,
    child: _ManageParticipantsSheet(
      title: title,
      roleLabel: roleLabel,
      load: load,
      add: add,
      remove: remove,
      setRole: setRole,
      loadCandidates: loadCandidates,
      loadAccommodations: loadAccommodations,
      assignAccommodation: assignAccommodation,
    ),
  );
}

class _ManageParticipantsSheet extends StatefulWidget {
  final String title;
  final String roleLabel;
  final Future<List<TravelParticipantEntry>> Function() load;
  final Future<void> Function(String userId) add;
  final Future<void> Function(String userId) remove;
  final Future<void> Function(String userId, String role)? setRole;
  final Future<List<TravelParticipantEntry>> Function()? loadCandidates;
  final Future<List<TravelAccommodation>> Function()? loadAccommodations;
  final Future<void> Function(String userId, String? accommodationId)?
  assignAccommodation;

  const _ManageParticipantsSheet({
    required this.title,
    required this.roleLabel,
    required this.load,
    required this.add,
    required this.remove,
    this.setRole,
    this.loadCandidates,
    this.loadAccommodations,
    this.assignAccommodation,
  });

  @override
  State<_ManageParticipantsSheet> createState() =>
      _ManageParticipantsSheetState();
}

class _ManageParticipantsSheetState extends State<_ManageParticipantsSheet> {
  List<TravelParticipantEntry> _entries = [];
  bool _loading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading) _load();
  }

  Future<void> _load() async {
    try {
      final entries = await widget.load();
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
        _error = null;
      });
    } catch (e, st) {
      developer.log('Failed to load participants', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Teilnehmer konnten nicht geladen werden.';
      });
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
      if (!mounted) return;
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(travelErrorMessage(e))));
    } catch (e, st) {
      developer.log('Participant action failed', error: e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Aktion fehlgeschlagen.')));
    }
  }

  Future<void> _add() async {
    List<TravelParticipantEntry> candidates;
    if (widget.loadCandidates != null) {
      candidates = await widget.loadCandidates!();
    } else {
      final users = await AppScope.of(context).user.listAll();
      candidates = users
          .map(
            (u) => TravelParticipantEntry(
              id: u.id,
              displayName: u.displayName,
              image: u.image,
            ),
          )
          .toList();
    }
    if (!mounted) return;

    final existing = _entries.map((e) => e.id).toSet();
    final available = candidates.where((c) => !existing.contains(c.id)).toList();

    final picked = await showDesignSheet<String>(
      context: context,
      child: _CandidatePicker(candidates: available),
    );
    if (picked == null || !mounted) return;
    await _run(() => widget.add(picked));
  }

  Future<void> _assignAccommodation(TravelParticipantEntry entry) async {
    final loadAccommodations = widget.loadAccommodations;
    final assign = widget.assignAccommodation;
    if (loadAccommodations == null || assign == null) return;

    try {
      final options = await loadAccommodations();
      if (!mounted) return;
      String? current;
      for (final a in options) {
        if (a.users.any((u) => u.id == entry.id)) current = a.id;
      }
      final chosen = await showAccommodationPicker(
        context,
        options: options,
        selectedId: current,
        allowNone: true,
        title: 'Unterkunft für ${entry.displayName}',
      );
      if (chosen == null || !mounted) return;
      final accommodationId = chosen.isEmpty ? null : chosen;
      await _run(() => assign(entry.id, accommodationId));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(travelErrorMessage(e))));
    } catch (e, st) {
      developer.log('Accommodation assignment failed', error: e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Aktion fehlgeschlagen.')));
    }
  }

  void _openActions(TravelParticipantEntry entry) {
    final tokens = DesignTheme.of(context);
    final self = entry.id == AppScope.of(context).auth.userId;
    final canAssignAccommodation = widget.assignAccommodation != null;
    final canSetRole = widget.setRole != null;
    showDesignSheet(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DesignText(
            entry.displayName,
            style: DesignTextStyle.subtitle,
            color: tokens.textHigh,
          ),
          SizedBox(height: tokens.spaceMd),
          if (canAssignAccommodation)
            DesignListTile(
              leading: Icon(
                Icons.hotel_rounded,
                color: tokens.primary,
                size: 20,
              ),
              title: 'Unterkunft zuweisen',
              onTap: () {
                Navigator.of(context).pop();
                _assignAccommodation(entry);
              },
            ),
          if (!self && !entry.isLeader && canSetRole)
            DesignListTile(
              leading: Icon(
                Icons.workspace_premium_rounded,
                color: tokens.primary,
                size: 20,
              ),
              title: 'Zum ${widget.roleLabel} ernennen',
              onTap: () {
                Navigator.of(context).pop();
                _run(() => widget.setRole!(entry.id, 'leader'));
              },
            ),
          if (!self && entry.isLeader && canSetRole)
            DesignListTile(
              leading: Icon(
                Icons.workspace_premium_outlined,
                color: tokens.textLow,
                size: 20,
              ),
              title: '${widget.roleLabel} entziehen',
              onTap: () {
                Navigator.of(context).pop();
                _run(() => widget.setRole!(entry.id, 'participant'));
              },
            ),
          if (!self)
            DesignListTile(
              leading: Icon(
                Icons.person_remove_rounded,
                color: tokens.danger,
                size: 20,
              ),
              title: 'Entfernen',
              onTap: () {
                Navigator.of(context).pop();
                _confirmRemove(entry);
              },
            ),
          if (self)
            DesignListTile(
              title: 'Das bist du',
              leading: Icon(
                Icons.person_rounded,
                color: tokens.textLow,
                size: 20,
              ),
              onTap: null,
            ),
        ],
      ),
    );
  }

  Future<void> _confirmRemove(TravelParticipantEntry entry) async {
    final tokens = DesignTheme.of(context);
    final confirmed = await showDesignSheet<bool>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DesignText(
            '${entry.displayName} entfernen?',
            style: DesignTextStyle.subtitle,
            color: tokens.textHigh,
          ),
          SizedBox(height: tokens.spaceMd),
          Row(
            children: [
              Expanded(
                child: DesignButton(
                  label: 'Abbrechen',
                  variant: DesignButtonVariant.outlined,
                  onPressed: () => Navigator.pop(context, false),
                ),
              ),
              SizedBox(width: tokens.spaceMd),
              Expanded(
                child: DesignButton(
                  label: 'Entfernen',
                  onPressed: () => Navigator.pop(context, true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed == true) await _run(() => widget.remove(entry.id));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesignText(
          widget.title,
          style: DesignTextStyle.subtitle,
          color: tokens.textHigh,
        ),
        SizedBox(height: tokens.spaceMd),
        if (_loading)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CircularProgressIndicator(color: tokens.primary),
            ),
          )
        else if (_error != null)
          DesignText(_error!, style: DesignTextStyle.body, color: tokens.danger)
        else ...[
          if (_entries.isEmpty)
            DesignText(
              'Noch keine Teilnehmer.',
              style: DesignTextStyle.body,
              color: tokens.textLow,
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _entries.length,
                itemBuilder: (context, index) {
                  final entry = _entries[index];
                  return DesignListTile(
                    leading: DesignAvatar(
                      imageUrl: entry.image,
                      name: entry.displayName,
                      size: 32,
                    ),
                    title: entry.displayName,
                    subtitle: entry.isLeader ? widget.roleLabel : null,
                    trailing: DesignIconButton(
                      icon: Icons.more_vert_rounded,
                      onPressed: () => _openActions(entry),
                    ),
                    padding: EdgeInsets.symmetric(vertical: tokens.spaceSm),
                  );
                },
              ),
            ),
          SizedBox(height: tokens.spaceMd),
          DesignButton(
            label: 'Teilnehmer hinzufügen',
            variant: DesignButtonVariant.outlined,
            icon: Icons.person_add_rounded,
            fullWidth: true,
            onPressed: _add,
          ),
        ],
      ],
    );
  }
}

/// Einfache Einzelauswahl-Liste zum Hinzufügen eines Nutzers.
class _CandidatePicker extends StatelessWidget {
  final List<TravelParticipantEntry> candidates;

  const _CandidatePicker({required this.candidates});

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesignText(
          'Nutzer hinzufügen',
          style: DesignTextStyle.subtitle,
          color: tokens.textHigh,
        ),
        SizedBox(height: tokens.spaceMd),
        if (candidates.isEmpty)
          DesignText(
            'Keine Nutzer verfügbar.',
            style: DesignTextStyle.body,
            color: tokens.textLow,
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: candidates.length,
              itemBuilder: (context, index) {
                final candidate = candidates[index];
                return DesignListTile(
                  leading: DesignAvatar(
                    imageUrl: candidate.image,
                    name: candidate.displayName,
                    size: 32,
                  ),
                  title: candidate.displayName,
                  trailing: DesignBadge(
                    label: 'Hinzufügen',
                    color: tokens.primary,
                  ),
                  padding: EdgeInsets.symmetric(vertical: tokens.spaceSm),
                  onTap: () => Navigator.pop(context, candidate.id),
                );
              },
            ),
          ),
      ],
    );
  }
}
