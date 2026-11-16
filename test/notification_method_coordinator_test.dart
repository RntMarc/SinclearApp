import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/core/network/api_client.dart';
import 'package:sinclear_beyond/features/notifications/models/notification_item.dart';
import 'package:sinclear_beyond/features/notifications/services/fcm_push_service.dart';
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

class _FakeFcmPush extends FcmPushService {
  _FakeFcmPush(ApiClient api, {this.setupResult = true}) : super(api: api);

  final bool setupResult;
  bool unregistered = false;

  @override
  Future<bool> setup({
    required Future<String> Function() getToken,
    required Future<void> Function() onWakeup,
  }) async => setupResult;

  @override
  Future<void> unregister({String? token}) async {
    unregistered = true;
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
    bool fcmSetupResult = true,
  }) {
    final api = ApiClient(baseUrl: 'http://test');
    return NotificationMethodCoordinator(
      unifiedPush: _FakeUnifiedPush(
        api,
        distributor: distributor,
        distributors: distributors,
        selectFails: selectFails,
      ),
      fcmPush: _FakeFcmPush(api, setupResult: fcmSetupResult),
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

  test('FCM mit Berechtigung und erfolgreichem Setup → applied', () async {
    final outcome = await build(
      fcmSetupResult: true,
    ).apply(NotificationMethod.fcm);
    expect(outcome, NotificationMethodOutcome.applied);
  });

  test('FCM ohne Berechtigung → permissionDenied', () async {
    final outcome = await build(
      permissionGranted: false,
    ).apply(NotificationMethod.fcm);
    expect(outcome, NotificationMethodOutcome.permissionDenied);
  });

  test('FCM bei fehlgeschlagenem Setup → unavailable', () async {
    final outcome = await build(
      fcmSetupResult: false,
    ).apply(NotificationMethod.fcm);
    expect(outcome, NotificationMethodOutcome.unavailable);
  });
}
