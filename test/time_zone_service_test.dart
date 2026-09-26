import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/core/services/time_zone_service.dart';

void main() {
  test('init fällt ohne Plattformkanal auf UTC zurück', () async {
    final service = TimeZoneService();
    await service.init();

    expect(service.device, TimeZoneService.fallback);
    expect(service.effective, TimeZoneService.fallback);
    expect(service.availableZones, isNotEmpty);
  });

  test('normalize kanonisiert IANA-Namen und lehnt Unbekanntes ab', () async {
    final service = TimeZoneService();
    await service.init();

    expect(service.normalize('Europe/Berlin'), 'Europe/Berlin');
    expect(service.normalize('Nonsense/Zone'), TimeZoneService.fallback);
    expect(service.normalize(null), TimeZoneService.fallback);
  });

  test('Praferenz schlägt Geraetezeitzone, null setzt sie zurück', () async {
    final service = TimeZoneService();
    await service.init();

    service.setPreference('Europe/Berlin');
    expect(service.effective, 'Europe/Berlin');

    service.setPreference(null);
    expect(service.effective, service.device);
  });
}
