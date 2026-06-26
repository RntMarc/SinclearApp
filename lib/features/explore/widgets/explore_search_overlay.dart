import 'dart:developer' as developer;
import 'package:flutter/cupertino.dart';
import '../../../core/di/app_scope.dart';
import '../models/explore_models.dart';

class ExploreSearchOverlay extends StatefulWidget {
  const ExploreSearchOverlay({super.key});

  @override
  State<ExploreSearchOverlay> createState() => _ExploreSearchOverlayState();
}

class _ExploreSearchOverlayState extends State<ExploreSearchOverlay> {
  final _queryController = TextEditingController();
  final _focusNode = FocusNode();
  String _searchMode = 'name';
  String? _selectedCategory;
  double _radius = 5000;
  bool _searching = false;

  @override
  void dispose() {
    _queryController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;

    setState(() => _searching = true);

    try {
      final explore = AppScope.of(context).explore;
      final ExploreListResponse response;

      if (_searchMode == 'name') {
        response = await explore.search(q: query, category: _selectedCategory);
      } else {
        response = await explore.search(
          location: query,
          radius: _radius.round(),
          category: _selectedCategory,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, response);
    } catch (e, st) {
      developer.log('Search failed', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _searching = false);
      showCupertinoDialog<void>(
        context: context,
        builder: (_) => const CupertinoAlertDialog(
          content: Text('Suche fehlgeschlagen.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Suchen'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: const Icon(CupertinoIcons.back, size: 22),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CupertinoTextField(
                controller: _queryController,
                focusNode: _focusNode,
                autofocus: true,
                placeholder: _searchMode == 'name'
                    ? 'Orte, Kategorien...'
                    : 'Stadt, Stadtteil...',
                prefix: const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Icon(CupertinoIcons.search, size: 20),
                ),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
              ),
              const SizedBox(height: 20),
              CupertinoSegmentedControl<String>(
                children: const {
                  'name': Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.search, size: 16),
                        SizedBox(width: 6),
                        Text('Name'),
                      ],
                    ),
                  ),
                  'location': Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.location, size: 16),
                        SizedBox(width: 6),
                        Text('Ort/Region'),
                      ],
                    ),
                  ),
                },
                groupValue: _searchMode,
                onValueChanged: (v) {
                  setState(() => _searchMode = v);
                  _focusNode.requestFocus();
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Kategorie',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.textStyle.color
                      ?.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _CategoryChip(
                    label: 'Alle',
                    selected: _selectedCategory == null,
                    onTap: () => setState(() => _selectedCategory = null),
                  ),
                  const SizedBox(width: 8),
                  _CategoryChip(
                    label: 'Gastronomie',
                    selected: _selectedCategory == 'gastronomy',
                    onTap: () =>
                        setState(() => _selectedCategory = 'gastronomy'),
                  ),
                  const SizedBox(width: 8),
                  _CategoryChip(
                    label: 'Freizeit',
                    selected: _selectedCategory == 'leisure',
                    onTap: () =>
                        setState(() => _selectedCategory = 'leisure'),
                  ),
                ],
              ),
              if (_searchMode == 'location') ...[
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Umkreis',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.textStyle.color
                            ?.withValues(alpha: 0.6),
                      ),
                    ),
                    Text(
                      '${(_radius / 1000).round()} km',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.textStyle.color,
                      ),
                    ),
                  ],
                ),
                CupertinoSlider(
                  value: _radius,
                  min: 1000,
                  max: 50000,
                  divisions: 49,
                  onChanged: (v) => setState(() => _radius = v),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '1 km',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.textTheme.textStyle.color
                            ?.withValues(alpha: 0.5),
                      ),
                    ),
                    Text(
                      '50 km',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.textTheme.textStyle.color
                            ?.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 32),
              CupertinoButton.filled(
                onPressed: _searching ? null : _search,
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: _searching
                    ? const CupertinoActivityIndicator(
                        color: CupertinoColors.white,
                      )
                    : const Text('Suchen'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? theme.primaryColor
              : CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: selected
                ? CupertinoColors.white
                : theme.textTheme.textStyle.color,
          ),
        ),
      ),
    );
  }
}
