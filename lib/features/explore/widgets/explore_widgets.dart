import 'package:flutter/material.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../models/explore_models.dart';
import 'place_card.dart';

class ExploreSearchResults extends StatelessWidget {
  final List<ExplorePlace> results;
  final int crossAxisCount;
  final bool loadingMore;
  final ScrollController scrollController;
  final VoidCallback onClear;

  const ExploreSearchResults({
    super.key,
    required this.results,
    required this.crossAxisCount,
    required this.loadingMore,
    required this.scrollController,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                DesignText(
                  'Suchergebnisse',
                  style: DesignTextStyle.subtitle,
                  color: tokens.textHigh,
                ),
                const Spacer(),
                DesignButton(
                  variant: DesignButtonVariant.text,
                  icon: Icons.close_rounded,
                  label: 'Schließen',
                  onPressed: onClear,
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            tokens.spaceLg,
            tokens.spaceSm,
            tokens.spaceLg,
            tokens.spaceLg,
          ),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: crossAxisCount > 1 ? 2.0 : 3.5,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= results.length) {
                  return Center(
                    child: CircularProgressIndicator(color: tokens.primary),
                  );
                }
                return PlaceCard(place: results[index]);
              },
              childCount: results.length + (loadingMore ? 1 : 0),
            ),
          ),
        ),
      ],
    );
  }
}

class ExploreSearchEmpty extends StatelessWidget {
  final VoidCallback onBack;

  const ExploreSearchEmpty({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 48,
            color: tokens.textLow,
          ),
          SizedBox(height: tokens.spaceSm),
          DesignText(
            'Keine Ergebnisse gefunden.',
            style: DesignTextStyle.body,
            color: tokens.textLow,
          ),
          SizedBox(height: tokens.spaceLg),
          DesignButton(
            variant: DesignButtonVariant.filled,
            label: 'Zurück',
            onPressed: onBack,
          ),
        ],
      ),
    );
  }
}

class ExploreSuggestionsList extends StatelessWidget {
  final bool loading;
  final List<ExplorePlace> suggestions;
  final int crossAxisCount;
  final String? error;
  final bool loadingBookmarks;
  final bool bookmarksError;
  final List<ExplorePlace> bookmarks;
  final VoidCallback onRetry;
  final VoidCallback onRetryBookmarks;

  const ExploreSuggestionsList({
    super.key,
    required this.loading,
    required this.suggestions,
    required this.crossAxisCount,
    this.error,
    required this.loadingBookmarks,
    required this.bookmarksError,
    required this.bookmarks,
    required this.onRetry,
    required this.onRetryBookmarks,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    if (loading) {
      return Center(child: CircularProgressIndicator(color: tokens.primary));
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: tokens.danger),
            SizedBox(height: tokens.spaceSm),
            DesignText(error!, style: DesignTextStyle.body, color: tokens.textHigh),
            SizedBox(height: tokens.spaceLg),
            DesignButton(
              variant: DesignButtonVariant.filled,
              label: 'Erneut versuchen',
              onPressed: onRetry,
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
          sliver: SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: tokens.spaceSm),
              child: DesignText(
                'Vorschläge',
                style: DesignTextStyle.subtitle,
                color: tokens.textHigh,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: crossAxisCount > 1 ? 2.0 : 3.5,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => PlaceCard(place: suggestions[index]),
              childCount: suggestions.length,
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            tokens.spaceLg,
            tokens.spaceXl,
            tokens.spaceLg,
            tokens.spaceLg,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DesignText(
                  'Lesezeichen',
                  style: DesignTextStyle.subtitle,
                  color: tokens.textHigh,
                ),
                SizedBox(height: tokens.spaceSm),
                if (loadingBookmarks)
                  Padding(
                    padding: EdgeInsets.all(tokens.spaceXl),
                    child: Center(
                      child: CircularProgressIndicator(color: tokens.primary),
                    ),
                  )
                else if (bookmarksError)
                  DesignCard(
                    padding: EdgeInsets.all(tokens.spaceXl),
                    margin: EdgeInsets.zero,
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 24,
                            color: tokens.danger,
                          ),
                          SizedBox(height: tokens.spaceSm),
                          DesignText(
                            'Lesezeichen konnten nicht geladen werden.',
                            style: DesignTextStyle.body,
                            color: tokens.danger,
                          ),
                          SizedBox(height: tokens.spaceSm),
                          DesignButton(
                            variant: DesignButtonVariant.text,
                            label: 'Erneut versuchen',
                            onPressed: onRetryBookmarks,
                          ),
                        ],
                      ),
                    ),
                  )
                else if (bookmarks.isEmpty)
                  DesignCard(
                    padding: EdgeInsets.all(tokens.spaceXl),
                    margin: EdgeInsets.zero,
                    child: Center(
                      child: DesignText(
                        'Keine Lesezeichen vorhanden.',
                        style: DesignTextStyle.body,
                        color: tokens.textLow,
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 200,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.zero,
                      itemCount: bookmarks.length,
                      separatorBuilder: (_, _) => SizedBox(width: tokens.spaceSm),
                      itemBuilder: (context, index) => SizedBox(
                        width: 260,
                        child: PlaceCard(place: bookmarks[index]),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
