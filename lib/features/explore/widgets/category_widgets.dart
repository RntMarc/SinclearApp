import 'package:flutter/material.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../models/explore_models.dart';
import 'place_card.dart';

class CategoryPlaceList extends StatelessWidget {
  final bool loading;
  final List<ExplorePlace> places;
  final int crossAxisCount;
  final String? error;
  final bool loadingMore;
  final ScrollController scrollController;
  final Future<void> Function() onRetry;

  const CategoryPlaceList({
    super.key,
    required this.loading,
    required this.places,
    required this.crossAxisCount,
    this.error,
    required this.loadingMore,
    required this.scrollController,
    required this.onRetry,
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

    if (places.isEmpty) {
      return Center(
        child: DesignText(
          'Keine Einträge in dieser Kategorie.',
          style: DesignTextStyle.body,
          color: tokens.textLow,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRetry,
      child: GridView.builder(
        controller: scrollController,
        padding: EdgeInsets.all(tokens.spaceLg),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: crossAxisCount > 1 ? 2.0 : 3.5,
        ),
        itemCount: places.length + (loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= places.length) {
            return Center(
              child: CircularProgressIndicator(color: tokens.primary),
            );
          }
          return PlaceCard(place: places[index]);
        },
      ),
    );
  }
}
