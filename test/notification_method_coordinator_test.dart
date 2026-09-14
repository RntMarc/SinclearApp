import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/core/network/api_client.dart';
import 'package:sinclear_beyond/features/notifications/models/notification_item.dart';
import 'package:sinclear_beyond/features/notifications/services/foreground_polling_service.dart';
import 'package:sinclear_beyond/features/notifications/services/notification_method_coordinator.dart';
import 'package:sinclear_beyond/features/notifications/services/notification_service.dart';
import 'package:sinclear_beyond/features/notifications/services/unified_push_service.dart';
import 'package:sinclear_beyond/features/settings/models/notification_preference.dart';

class _FakeForegroundPolling extends ForegroundPollingService {
  _FakeForegroundPolling({required this.startResult});

  final bool startResult;

  @override
  Future<bool> start({bool requestPermission = true}) async => startResult;

  @override
  Future<void> stop() async {}
}

class _FakeNotificationService extends NotificationService {
  _FakeNotificationService(ApiClient api) : super(api: api);

  bool polling = false;

  @override
  void startPolling({
    required Future<String> Function() getToken,
    Duration interval = const Duration(seconds: 60),
  }) {
    polling = true;
  }

  @override
  void stopPolling() {
    polling = false;
  }
}

class _FakeUnifiedPush extends UnifiedPushService {
  _FakeUnifiedPush(
    ApiClient api, {
    this.distributor,
    this.distributors = const [],
    this.selectFails = false,
  }) : super(api: api);

  final String? distributor;
  final List<String> distributors;
  final bool selectFails;
  bool registered = false;

  @override
  void init({
    required String token,
    void Function(NotificationItem item)? onMessage,
  }) {}

  @override
  Future<String?> registeredDistributor() async => distributor;

  @override
  Future<List<String>> availableDistributors() async => distributors;

  @override
  Future<void> register() async => registered = true;

  @override
  Future<void> selectDistributor(String distributor) async {
    if (selectFails) throw Exception('select failed');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  NotificationMethodCoordinator build({
    bool pollingStarts = true,
    String? distributor,
    List<String> distributors = const [],
    bool permissionGranted = true,
    bool selectFails = false,
  }) {
    final api = ApiClient(baseUrl: 'http://test');
    return NotificationMethodCoordinator(
      unifiedPush: _FakeUnifiedPush(
        api,
        distributor: distributor,
        distributors: distributors,
        selectFails: selectFails,
      ),
      notification: _FakeNotificationService(api),
      foregroundPolling: _FakeForegroundPolling(startResult: pollingStarts),
      getToken: () async => 'token',
      requestPermission: () async => permissionGranted,
    );
  }

  test('Polling ohne Berechtigung → permissionDenied', () async {
    final outcome = await build(
      pollingStarts: false,
    ).apply(NotificationMethod.polling);
    expect(outcome, NotificationMethodOutcome.permissionDenied);
  });

  test('Polling mit Berechtigung → applied', () async {
    final outcome = await build().apply(NotificationMethod.polling);
    expect(outcome, NotificationMethodOutcome.applied);
  });

  test('UnifiedPush ohne Distributor → noDistributor', () async {
    final outcome = await build().apply(NotificationMethod.unifiedPush);
    expect(outcome, NotificationMethodOutcome.noDistributor);
  });

  test('UnifiedPush mit Auswahl → needsDistributor', () async {
    final outcome = await build(
      distributors: ['ntfy', 'Gotify'],
    ).apply(NotificationMethod.unifiedPush);
    expect(outcome, NotificationMethodOutcome.needsDistributor);
  });

  test('UnifiedPush ohne Berechtigung → permissionDenied', () async {
    final outcome = await build(
      distributor: 'ntfy',
      permissionGranted: false,
    ).apply(NotificationMethod.unifiedPush);
    expect(outcome, NotificationMethodOutcome.permissionDenied);
  });

  test('UnifiedPush mit eingerichtetem Distributor → applied', () async {
    final outcome = await build(
      distributor: 'ntfy',
    ).apply(NotificationMethod.unifiedPush);
    expect(outcome, NotificationMethodOutcome.applied);
  });

  test('selectDistributor meldet Fehler als false', () async {
    final coordinator = build(distributor: 'ntfy', selectFails: true);
    expect(await coordinator.selectDistributor('ntfy'), isFalse);
  });
}
