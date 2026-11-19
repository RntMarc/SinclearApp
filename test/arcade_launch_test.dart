import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/features/arcade/screens/arcade_screen.dart';

void main() {
  test('arcade games open in the current tab on web', () {
    expect(arcadeWindowName(isWeb: true), '_self');
    expect(arcadeWindowName(isWeb: false), isNull);
  });
}
