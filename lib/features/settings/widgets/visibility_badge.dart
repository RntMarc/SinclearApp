import 'package:flutter/cupertino.dart';

const _labels = <int, String>{0: 'Nur ich', 1: 'Alle', 2: 'Freunde'};
const _icons = <int, IconData>{
  0: CupertinoIcons.lock_fill,
  1: CupertinoIcons.globe,
  2: CupertinoIcons.person_2_fill,
};

class VisibilityBadge extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const VisibilityBadge({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final label = _labels[value] ?? 'Unbekannt';
    final icon = _icons[value] ?? CupertinoIcons.question;

    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: theme.primaryColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: theme.primaryColor,
              ),
            ),
            Icon(
              CupertinoIcons.chevron_down,
              size: 12,
              color: theme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Sichtbarkeit'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              onChanged(0);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.lock_fill, size: 20),
                SizedBox(width: 8),
                Text('Nur ich'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              onChanged(1);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.globe, size: 20),
                SizedBox(width: 8),
                Text('Alle'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              onChanged(2);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.person_2_fill, size: 20),
                SizedBox(width: 8),
                Text('Enge Freunde'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
      ),
    );
  }
}
