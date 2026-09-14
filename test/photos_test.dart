import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/features/photos/models/photo_models.dart';
import 'package:sinclear_beyond/features/photos/utils/masonry.dart';

Map<String, dynamic> _photoJson(String id, int width, int height) {
  return {
    'id': id,
    'thumb': 'https://images.unsplash.com/$id?w=400',
    'regular': 'https://images.unsplash.com/$id?w=1080',
    'width': width,
    'height': height,
    'createdAt': '2026-01-01 10:00:00',
    'photographer': {
      'name': 'Jane Doe',
      'username': 'janedoe',
      'url': 'https://unsplash.com/@janedoe',
    },
    'author': {'id': 'user-1', 'displayName': 'Marc', 'avatar': null},
  };
}

void main() {
  group('Photo.fromJson', () {
    test('parst alle Felder inkl. Attribution und Autor', () {
      final photo = Photo.fromJson(_photoJson('p1', 4000, 3000));

      expect(photo.id, 'p1');
      expect(photo.thumb, contains('p1'));
      expect(photo.regular, contains('p1'));
      expect(photo.aspectRatio, closeTo(4 / 3, 0.0001));
      expect(photo.photographer.name, 'Jane Doe');
      expect(photo.photographer.url, contains('unsplash'));
      expect(photo.author.id, 'user-1');
      expect(photo.author.displayName, 'Marc');
    });

    test('fällt bei fehlenden Maßen auf Seitenverhältnis 1.0 zurück', () {
      final json = _photoJson('p2', 0, 0);
      expect(Photo.fromJson(json).aspectRatio, 1.0);
    });
  });

  group('PhotoPage.fromJson', () {
    test('liest Paginierungs-Meta', () {
      final page = PhotoPage.fromJson({
        'data': [_photoJson('p1', 100, 100)],
        'meta': {'page': 2, 'limit': 30, 'total': 45, 'totalPages': 2},
      });

      expect(page.data, hasLength(1));
      expect(page.page, 2);
      expect(page.total, 45);
      expect(page.totalPages, 2);
      expect(page.hasMore, isFalse);
    });

    test('hasMore ist true, solange weitere Seiten existieren', () {
      final page = PhotoPage.fromJson({
        'data': const [],
        'meta': {'page': 1, 'limit': 30, 'total': 45, 'totalPages': 2},
      });
      expect(page.hasMore, isTrue);
    });
  });

  group('distributeIntoColumns', () {
    test('verteilt Elemente auf die aktuell kürzeste Spalte', () {
      final items = [1.0, 2.0, 3.0, 1.0];
      final columns = distributeIntoColumns<double>(items, 2, (value) => value);

      expect(columns, hasLength(2));
      // Erste Spalte: 1.0 + 3.0 (Höhe 4), zweite: 2.0 + 1.0 (Höhe 3).
      expect(columns[0], [1.0, 3.0]);
      expect(columns[1], [2.0, 1.0]);
    });

    test('behandelt columnCount < 1 als eine Spalte', () {
      final columns = distributeIntoColumns<int>([1, 2], 0, (_) => 1);
      expect(columns, hasLength(1));
      expect(columns.single, [1, 2]);
    });

    test('leere Eingabe ergibt leere Spalten', () {
      final columns = distributeIntoColumns<int>([], 3, (_) => 1);
      expect(columns, [[], [], []]);
    });
  });
}
