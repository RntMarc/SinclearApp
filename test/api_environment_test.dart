import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sinclear_beyond/features/settings/models/api_environment.dart';

void main() {
  group('ApiEnvironmentPreference', () {
    test('defaults to release and roundtrips', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await ApiEnvironmentPreference.load(), ApiEnvironment.release);

      await ApiEnvironmentPreference.save(ApiEnvironment.preview);
      expect(await ApiEnvironmentPreference.load(), ApiEnvironment.preview);

      await ApiEnvironmentPreference.save(ApiEnvironment.release);
      expect(await ApiEnvironmentPreference.load(), ApiEnvironment.release);
    });
  });

  group('resolveApiBaseUrl', () {
    const release = 'https://prod.example/api/v2';
    const preview = 'https://preview.example/api/v2';

    test('uses release when selection is not allowed', () {
      expect(
        resolveApiBaseUrl(
          selected: ApiEnvironment.preview,
          releaseUrl: release,
          previewUrl: preview,
          allowSelection: false,
        ),
        release,
      );
    });

    test('honours the selected environment when allowed', () {
      expect(
        resolveApiBaseUrl(
          selected: ApiEnvironment.preview,
          releaseUrl: release,
          previewUrl: preview,
          allowSelection: true,
        ),
        preview,
      );
      expect(
        resolveApiBaseUrl(
          selected: ApiEnvironment.release,
          releaseUrl: release,
          previewUrl: preview,
          allowSelection: true,
        ),
        release,
      );
    });

    test('falls back to release for an unknown preview URL', () {
      expect(
        resolveApiBaseUrl(
          selected: ApiEnvironment.preview,
          releaseUrl: release,
          previewUrl: release,
          allowSelection: true,
        ),
        release,
      );
    });
  });
}
