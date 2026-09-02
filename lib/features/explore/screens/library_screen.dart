import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/app_scope.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../models/explore_models.dart';
import '../widgets/place_card.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<ExplorePlace> _bookmarks = [];
  List<ExplorePlace> _myPlaces = [];
  bool _loadingBookmarks = true;
  bool _loadingMyPlaces = true;
  String? _bookmarksError;
  String? _myPlacesError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadingBookmarks) _loadBookmarks();
    if (_loadingMyPlaces) _loadMyPlaces();
  }

  Future<void> _loadBookmarks() async {
    setState(() {
      _loadingBookmarks = true;
      _bookmarksError = null;
    });
    try {
      final explore = AppScope.of(context).explore;
      final response = await explore.getBookmarks(limit: 50);
      if (!mounted) return;
      setState(() {
        _bookmarks = response.data;
        _loadingBookmarks = false;
      });
    } catch (e, st) {
      developer.log('Failed to load bookmarks', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loadingBookmarks = false;
        _bookmarksError = 'Lesezeichen konnten nicht geladen werden.';
      });
    }
  }

  Future<void> _loadMyPlaces() async {
    setState(() {
      _loadingMyPlaces = true;
      _myPlacesError = null;
    });
    try {
      final explore = AppScope.of(context).explore;
      final response = await explore.list(mine: true, limit: 50);
      if (!mounted) return;
      setState(() {
        _myPlaces = response.data;
        _loadingMyPlaces = false;
      });
    } catch (e, st) {
      developer.log('Failed to load my places', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loadingMyPlaces = false;
        _myPlacesError = 'Eigene Orte konnten nicht geladen werden.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return DesignSurface(
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            DesignSubpageHeader(
              leading: DesignIconButton(
                icon: Icons.arrow_back_rounded,
                onPressed: () => context.pop(),
              ),
              title: 'Sammlung',
            ),
            TabBar(
              labelColor: tokens.primary,
              unselectedLabelColor: tokens.textLow,
              indicatorColor: tokens.primary,
              labelStyle: TextStyle(
                fontFamily: tokens.fontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: TextStyle(
                fontFamily: tokens.fontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              tabs: const [
                Tab(text: 'Lesezeichen'),
                Tab(text: 'Meine Orte'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildBookmarksTab(tokens),
                  _buildMyPlacesTab(tokens),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarksTab(DesignTokens tokens) {
    if (_loadingBookmarks) {
      return Center(child: CircularProgressIndicator(color: tokens.primary));
    }
    if (_bookmarksError != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(tokens.spaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: tokens.danger),
              SizedBox(height: tokens.spaceSm),
              DesignText(
                _bookmarksError!,
                style: DesignTextStyle.body,
                color: tokens.textHigh,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: tokens.spaceLg),
              DesignButton(
                variant: DesignButtonVariant.filled,
                label: 'Erneut versuchen',
                onPressed: _loadBookmarks,
              ),
            ],
          ),
        ),
      );
    }
    if (_bookmarks.isEmpty) {
      return Center(
        child: DesignText(
          'Keine Lesezeichen vorhanden.',
          style: DesignTextStyle.body,
          color: tokens.textLow,
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(tokens.spaceLg),
      itemCount: _bookmarks.length,
      itemBuilder: (context, index) => PlaceCard(place: _bookmarks[index]),
    );
  }

  Widget _buildMyPlacesTab(DesignTokens tokens) {
    if (_loadingMyPlaces) {
      return Center(child: CircularProgressIndicator(color: tokens.primary));
    }
    if (_myPlacesError != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(tokens.spaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: tokens.danger),
              SizedBox(height: tokens.spaceSm),
              DesignText(
                _myPlacesError!,
                style: DesignTextStyle.body,
                color: tokens.textHigh,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: tokens.spaceLg),
              DesignButton(
                variant: DesignButtonVariant.filled,
                label: 'Erneut versuchen',
                onPressed: _loadMyPlaces,
              ),
            ],
          ),
        ),
      );
    }
    if (_myPlaces.isEmpty) {
      return Center(
        child: DesignText(
          'Du hast noch keine Orte hinzugefügt.',
          style: DesignTextStyle.body,
          color: tokens.textLow,
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(tokens.spaceLg),
      itemCount: _myPlaces.length,
      itemBuilder: (context, index) => PlaceCard(place: _myPlaces[index]),
    );
  }
}
