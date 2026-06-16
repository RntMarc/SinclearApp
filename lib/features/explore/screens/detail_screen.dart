import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/app_scope.dart';
import '../models/explore_models.dart';

class DetailScreen extends StatefulWidget {
  final String id;

  const DetailScreen({super.key, required this.id});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  ExplorePlace? _place;
  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  bool? _bookmarked;
  bool _bookmarkToggling = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final explore = AppScope.of(context).explore;
      final results = await Future.wait([
        explore.get(widget.id),
        explore.bookmarkStatus(widget.id),
      ]);
      if (!mounted) return;
      setState(() {
        _place = results[0] as ExplorePlace;
        _bookmarked = results[1] as bool;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Ort konnte nicht geladen werden.';
      });
    }
  }

  Future<void> _toggleBookmark() async {
    if (_bookmarkToggling || _bookmarked == null) return;
    setState(() => _bookmarkToggling = true);
    try {
      final explore = AppScope.of(context).explore;
      if (_bookmarked!) {
        await explore.removeBookmark(widget.id);
      } else {
        await explore.setBookmark(widget.id);
      }
      if (!mounted) return;
      setState(() {
        _bookmarked = !_bookmarked!;
        _bookmarkToggling = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _bookmarkToggling = false);
    }
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      final explore = AppScope.of(context).explore;
      final place = await explore.update(widget.id);
      if (!mounted) return;
      setState(() {
        _place = place;
        _refreshing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OSM-Daten aktualisiert.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _refreshing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aktualisierung fehlgeschlagen.')),
      );
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ort löschen'),
        content: Text('${_place?.name} wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;
    try {
      final explore = AppScope.of(context).explore;
      await explore.delete(widget.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ort gelöscht.')),
      );
      if (!mounted) return;
      context.pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Löschen fehlgeschlagen.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null || _place == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48,
                color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 8),
            Text(_error ?? 'Unbekannter Fehler'),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: _load,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    final isWide = MediaQuery.of(context).size.width >= 600;
    final place = _place!;
    final auth = AppScope.of(context).auth;
    final isOwner = auth.userId == place.creatorId;
    final canDelete = isOwner || auth.isAdmin;

    if (isWide) {
      return _WideDetail(
        place: place,
        canDelete: canDelete,
        refreshing: _refreshing,
        bookmarked: _bookmarked ?? false,
        bookmarkToggling: _bookmarkToggling,
        onRefresh: _refresh,
        onDelete: _delete,
        onToggleBookmark: _toggleBookmark,
      );
    }
    return _NarrowDetail(
      place: place,
      canDelete: canDelete,
      refreshing: _refreshing,
      bookmarked: _bookmarked ?? false,
      bookmarkToggling: _bookmarkToggling,
      onRefresh: _refresh,
      onDelete: _delete,
      onToggleBookmark: _toggleBookmark,
    );
  }
}

class _WideDetail extends StatelessWidget {
  final ExplorePlace place;
  final bool canDelete;
  final bool refreshing;
  final bool bookmarked;
  final bool bookmarkToggling;
  final VoidCallback onRefresh;
  final VoidCallback onDelete;
  final VoidCallback onToggleBookmark;

  const _WideDetail({
    required this.place,
    required this.canDelete,
    required this.refreshing,
    required this.bookmarked,
    required this.bookmarkToggling,
    required this.onRefresh,
    required this.onDelete,
    required this.onToggleBookmark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: _InfoContent(place: place)),
          const SizedBox(width: 24),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _MapCard(place: place),
                const SizedBox(height: 16),
                _ActionsCard(
                  canDelete: canDelete,
                  refreshing: refreshing,
                  bookmarked: bookmarked,
                  bookmarkToggling: bookmarkToggling,
                  onRefresh: onRefresh,
                  onDelete: onDelete,
                  onToggleBookmark: onToggleBookmark,
                ),
                const SizedBox(height: 16),
                // TODO: Bewertungen integrieren, sobald API-Endpunkt verfügbar
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Bewertungen erscheinen hier.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NarrowDetail extends StatelessWidget {
  final ExplorePlace place;
  final bool canDelete;
  final bool refreshing;
  final bool bookmarked;
  final bool bookmarkToggling;
  final VoidCallback onRefresh;
  final VoidCallback onDelete;
  final VoidCallback onToggleBookmark;

  const _NarrowDetail({
    required this.place,
    required this.canDelete,
    required this.refreshing,
    required this.bookmarked,
    required this.bookmarkToggling,
    required this.onRefresh,
    required this.onDelete,
    required this.onToggleBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: const [
              Tab(text: 'Info'),
              Tab(text: 'Bewertungen'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _InfoContent(place: place),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: _MapCard(place: place),
                      ),
                      const SizedBox(height: 16),
                      _ActionsCard(
                        canDelete: canDelete,
                        refreshing: refreshing,
                        bookmarked: bookmarked,
                        bookmarkToggling: bookmarkToggling,
                        onRefresh: onRefresh,
                        onDelete: onDelete,
                        onToggleBookmark: onToggleBookmark,
                      ),
                    ],
                  ),
                ),
                // TODO: Bewertungen integrieren, sobald API-Endpunkt verfügbar
                Center(
                  child: Text(
                    'Bewertungen erscheinen hier.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoContent extends StatelessWidget {
  final ExplorePlace place;
  const _InfoContent({required this.place});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(place.name, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 16),
        if (place.address != null) _InfoRow(Icons.location_on_rounded, place.address!),
        if (place.phone != null) _InfoRow(Icons.phone_rounded, place.phone!),
        if (place.website != null) _InfoRow(Icons.language_rounded, place.website!),
        if (place.email != null) _InfoRow(Icons.email_rounded, place.email!),
        if (place.cuisine != null) _InfoRow(Icons.restaurant_rounded, place.cuisine!),
        if (place.openingHours != null) _InfoRow(Icons.schedule_rounded, place.openingHours!),
        const SizedBox(height: 16),
        _MetaRow('Kategorie', place.category == 'gastronomy' ? 'Gastronomie' : 'Freizeit'),
        _MetaRow('OSM-ID', '${place.osmType ?? "?"}/${place.osmId ?? "?"}'),
        _MetaRow('Erstellt', place.createdAt.substring(0, 10)),
        _MetaRow('Letzte Aktualisierung', place.lastUpdated.substring(0, 10)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetaRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            )),
          ),
          Text(value, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  final ExplorePlace place;
  const _MapCard({required this.place});

  @override
  Widget build(BuildContext context) {
    if (place.latitude == null || place.longitude == null) {
      return const Card(
        child: SizedBox(
          height: 200,
          child: Center(child: Text('Keine Koordinaten verfügbar')),
        ),
      );
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 200,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(place.latitude!, place.longitude!),
            initialZoom: 15,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.sinclearapp',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(place.latitude!, place.longitude!),
                  child: const Icon(Icons.location_on, color: Colors.red, size: 36),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionsCard extends StatelessWidget {
  final bool canDelete;
  final bool refreshing;
  final bool bookmarked;
  final bool bookmarkToggling;
  final VoidCallback onRefresh;
  final VoidCallback onDelete;
  final VoidCallback onToggleBookmark;

  const _ActionsCard({
    required this.canDelete,
    required this.refreshing,
    required this.bookmarked,
    required this.bookmarkToggling,
    required this.onRefresh,
    required this.onDelete,
    required this.onToggleBookmark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.tonalIcon(
              onPressed: bookmarkToggling ? null : onToggleBookmark,
              icon: bookmarkToggling
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      bookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                    ),
              label: Text(
                bookmarkToggling
                    ? '…'
                    : bookmarked
                        ? 'Lesezeichen entfernen'
                        : 'Lesezeichen setzen',
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: refreshing ? null : onRefresh,
              icon: refreshing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
              label: Text(refreshing ? 'Aktualisiere…' : 'OSM-Daten aktualisieren'),
            ),
            if (canDelete) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_rounded),
                label: const Text('Ort löschen'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
