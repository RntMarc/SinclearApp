import 'package:flutter/material.dart';

import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_chip.dart';
import '../../../design/widgets/primitives/design_text_field.dart';
import '../../user/models/user_models.dart';

/// Auswahl-Sheet zum Einladen mehrerer Nutzer (Mehrfachauswahl mit Suche).
///
/// Gibt über `Navigator.pop` die Liste der gewählten Nutzer-IDs zurück.
class PollUserPickerSheet extends StatefulWidget {
  const PollUserPickerSheet({
    required this.users,
    required this.excludedIds,
    super.key,
  });

  final List<UserBasePublic> users;
  final Set<String> excludedIds;

  @override
  State<PollUserPickerSheet> createState() => _PollUserPickerSheetState();
}

class _PollUserPickerSheetState extends State<PollUserPickerSheet> {
  final Set<String> _selected = {};
  final TextEditingController _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final query = _query.text.trim().toLowerCase();
    final candidates = widget.users.where((user) {
      if (widget.excludedIds.contains(user.id)) return false;
      if (query.isEmpty) return true;
      return user.displayName.toLowerCase().contains(query);
    }).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DesignText(
          'Nutzer einladen',
          style: DesignTextStyle.subtitle,
          color: tokens.textHigh,
        ),
        SizedBox(height: tokens.spaceMd),
        DesignTextField(
          hint: 'Suchen',
          controller: _query,
          prefixIcon: Icons.search_rounded,
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(height: tokens.spaceMd),
        SizedBox(
          height: 260,
          child: candidates.isEmpty
              ? Center(
                  child: DesignText(
                    'Keine Nutzer gefunden.',
                    style: DesignTextStyle.body,
                    color: tokens.textLow,
                  ),
                )
              : ListView.builder(
                  itemCount: candidates.length,
                  itemBuilder: (context, index) {
                    final user = candidates[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: tokens.spaceSm),
                      child: DesignChip(
                        label: user.displayName,
                        selected: _selected.contains(user.id),
                        onTap: () => setState(() {
                          if (!_selected.add(user.id)) {
                            _selected.remove(user.id);
                          }
                        }),
                      ),
                    );
                  },
                ),
        ),
        SizedBox(height: tokens.spaceMd),
        DesignButton(
          label: 'Einladen',
          fullWidth: true,
          onPressed: _selected.isEmpty
              ? null
              : () => Navigator.pop(context, _selected.toList()),
        ),
      ],
    );
  }
}
