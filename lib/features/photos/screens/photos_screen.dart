import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../models/photo_models.dart';
import '../utils/masonry.dart';
import '../widgets/photo_tile.dart';
import '../widgets/photo_viewer.dart';

/// Zeigt den Unsplash-Foto-Feed in einem Masonry-Grid (neueste zuerst).
///
/// Die globale Shell-AppBar liefert den Titel „FOTOS"; diese Seite rendert
/// nur den Inhalt. Unterstützt Pull-to-Refresh und seitenweises Nachladen
/// über einen „Mehr laden"-Button.
class PhotosScreen extends StatefulWidget {
  const PhotosScreen({super.key});

  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  static const int _pageSize = 30;

  final List<Photo> _photos = [];
  int _page = 0;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_page == 0 && _loading) {
      _loadFirstPage();
    }
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await AppScope.of(
        context,
      ).photos.feed(page: 1, limit: _pageSize);
      if (!mounted) return;
      setState(() {
        _photos
          ..clear()
          ..addAll(page.data);
        _page = page.page;
        _hasMore = page.hasMore;
        _loading = false;
      });
    } catch (e, st) {
      developer.log('Failed to load photos', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Fotos konnten nicht geladen werden.';
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final page = await AppScope.of(
        context,
      ).photos.feed(page: _page + 1, limit: _pageSize);
      if (!mounted) return;
      setState(() {
        _photos.addAll(page.data);
        _page = page.page;
        _hasMore = page.hasMore;
        _loadingMore = false;
      });
    } catch (e, st) {
      developer.log('Failed to load more photos', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  void _openViewer(Photo photo) {
    final index = _photos.indexOf(photo);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhotoViewer(
          photos: List.of(_photos),
          initialIndex: index < 0 ? 0 : index,
        ),
      ),
    );
  }

  static int _columnsFor(double width) {
    if (width < 600) return 2;
    if (width < 1000) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    return DesignSurface(child: _buildBody(context));
  }

  Widget _buildBody(BuildContext context) {
    final tokens = DesignTheme.of(context);

    if (_loading) {
      return RefreshIndicator(
        onRefresh: _loadFirstPage,
        child: ListView(
          children: [
            const SizedBox(height: 160),
            Center(child: CircularProgressIndicator(color: tokens.primary)),
          ],
        ),
      );
    }

    if (_error != null) {
      return RefreshIndicator(
        onRefresh: _loadFirstPage,
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: tokens.danger),
                  SizedBox(height: tokens.spaceSm),
                  DesignText(
                    _error!,
                    style: DesignTextStyle.body,
                    color: tokens.textHigh,
                  ),
                  SizedBox(height: tokens.spaceLg),
                  DesignButton(
                    variant: DesignButtonVariant.filled,
                    label: 'Erneut versuchen',
                    onPressed: _loadFirstPage,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_photos.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadFirstPage,
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
            Center(
              child: DesignText(
                'Keine Fotos sichtbar.',
                style: DesignTextStyle.body,
                color: tokens.textLow,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFirstPage,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = _columnsFor(constraints.maxWidth);
          final gap = tokens.spaceSm;
          final buckets = distributeIntoColumns<Photo>(
            _photos,
            columns,
            (photo) => 1 / photo.aspectRatio,
          );

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(gap),
            child: Column(
              children: [
                _Masonry(buckets: buckets, gap: gap, onTapPhoto: _openViewer),
                if (_hasMore) ...[
                  SizedBox(height: gap),
                  DesignButton(
                    variant: DesignButtonVariant.outlined,
                    label: 'Mehr laden',
                    loading: _loadingMore,
                    onPressed: _loadMore,
                  ),
                ],
                SizedBox(height: gap),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Baut die versetzten Spalten des Masonry-Grids.
class _Masonry extends StatelessWidget {
  final List<List<Photo>> buckets;
  final double gap;
  final ValueChanged<Photo> onTapPhoto;

  const _Masonry({
    required this.buckets,
    required this.gap,
    required this.onTapPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < buckets.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          Expanded(
            child: Column(
              children: [
                for (var j = 0; j < buckets[i].length; j++) ...[
                  if (j > 0) SizedBox(height: gap),
                  PhotoTile(
                    photo: buckets[i][j],
                    onTap: () => onTapPhoto(buckets[i][j]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
