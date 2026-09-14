/// Verteilt [items] greedy auf [columnCount] Spalten.
///
/// Jedes Element wird der aktuell kürzesten Spalte zugeordnet; die Höhe
/// wächst um `extentOf(item)`. Für ein Masonry-Grid übergibt der Aufrufer
/// als `extentOf` die auf die Spaltenbreite normierte Höhe (z. B.
/// `1 / aspectRatio`). So entstehen versetzte Kacheln mit natürlichen
/// Seitenverhältnissen, ohne eine zusätzliche Grid-Dependency.
///
/// ponytail: greedy statt optimaler Balancierung — für Fotos ausreichend,
/// bei Bedarf durch `flutter_staggered_grid_view` ersetzbar.
List<List<T>> distributeIntoColumns<T>(
  List<T> items,
  int columnCount,
  double Function(T item) extentOf,
) {
  final columns = _countSafe(columnCount);
  final buckets = List.generate(columns, (_) => <T>[]);
  final heights = List<double>.filled(columns, 0);

  for (final item in items) {
    var shortest = 0;
    for (var i = 1; i < columns; i++) {
      if (heights[i] < heights[shortest]) shortest = i;
    }
    buckets[shortest].add(item);
    heights[shortest] += extentOf(item);
  }
  return buckets;
}

int _countSafe(int columnCount) => columnCount < 1 ? 1 : columnCount;
