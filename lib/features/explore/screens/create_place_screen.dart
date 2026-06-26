import 'dart:developer' as developer;
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/network/api_client.dart';
import '../models/explore_models.dart';

class CreatePlaceScreen extends StatefulWidget {
  const CreatePlaceScreen({super.key});

  @override
  State<CreatePlaceScreen> createState() => _CreatePlaceScreenState();
}

class _CreatePlaceScreenState extends State<CreatePlaceScreen> {
  final _searchController = TextEditingController();
  List<NominatimResult> _results = [];
  bool _searching = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _searching = true;
      _error = null;
      _results = [];
    });

    try {
      final nominatim = AppScope.of(context).nominatim;
      final results = await nominatim.search(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _searching = false;
      });
    } catch (e, st) {
      developer.log('Failed to search OSM', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _searching = false;
        _error = 'Suche fehlgeschlagen. Bitte versuche es erneut.';
      });
    }
  }

  Future<void> _submit(NominatimResult result) async {
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final explore = AppScope.of(context).explore;
      final place = await explore.create(
        osmId: result.osmId,
        osmType: result.osmType,
      );
      if (!mounted) return;
      showCupertinoDialog<void>(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          content: Text('${place.name} wurde hinzugefugt!'),
        ),
      );
      context.go('/entdecken/${place.id}');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = switch (e.errorCode) {
          'place_already_exists' => 'Dieser Ort existiert bereits.',
          _ => 'Fehler beim Hinzufugen.',
        };
      });
    } catch (e, st) {
      developer.log('Failed to create place', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Netzwerkfehler. Bitte versuche es erneut.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CupertinoTextField(
            controller: _searchController,
            placeholder: 'Name oder Ort suchen...',
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
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              onPressed: _searching ? null : _search,
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: _searching
                  ? const CupertinoActivityIndicator(
                      color: CupertinoColors.white,
                    )
                  : const Text('Suchen'),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: CupertinoColors.destructiveRed),
            ),
          ],
          const SizedBox(height: 16),
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: Text(
                      'Gib einen Namen oder Ort ein, um nach Einträgen zu suchen.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (_, _) => Container(height: 1, color: CupertinoColors.systemGrey4),
                    itemBuilder: (context, index) {
                      final result = _results[index];
                      return GestureDetector(
                        onTap: _submitting ? null : () => _submit(result),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                result.osmType == 'N'
                                    ? CupertinoIcons.location
                                    : result.osmType == 'W'
                                        ? CupertinoIcons.arrow_right_arrow_left
                                        : CupertinoIcons.layers_fill,
                                color: theme.primaryColor,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      result.displayName,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                    Text(
                                      'OSM-ID: ${result.osmId}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: CupertinoColors.systemGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_submitting)
                                const CupertinoActivityIndicator()
                              else
                                Icon(
                                  CupertinoIcons.plus_circle,
                                  color: theme.primaryColor,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
