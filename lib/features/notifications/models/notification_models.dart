class AppNotification {
  final String id;
  final String code;
  final Map<String, dynamic> payload;
  final String createdAt;

  const AppNotification({
    required this.id,
    required this.code,
    required this.payload,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      code: json['code'] as String,
      payload: json['payload'] as Map<String, dynamic>,
      createdAt: json['createdAt'] as String,
    );
  }
}

class NotificationMeta {
  final int unreadCount;

  const NotificationMeta({required this.unreadCount});

  factory NotificationMeta.fromJson(Map<String, dynamic> json) {
    return NotificationMeta(unreadCount: json['unreadCount'] as int);
  }
}

class NotificationListResponse {
  final List<AppNotification> data;
  final NotificationMeta meta;

  const NotificationListResponse({required this.data, required this.meta});

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    final items = (json['data'] as List)
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
    return NotificationListResponse(
      data: items,
      meta: NotificationMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );
  }
}

class Device {
  final String id;
  final String? deviceName;
  final String platform;
  final bool pushEnabled;
  final String lastActiveAt;
  final String createdAt;

  const Device({
    required this.id,
    this.deviceName,
    required this.platform,
    required this.pushEnabled,
    required this.lastActiveAt,
    required this.createdAt,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as String,
      deviceName: json['deviceName'] as String?,
      platform: json['platform'] as String,
      pushEnabled: json['pushEnabled'] as bool,
      lastActiveAt: json['lastActiveAt'] as String,
      createdAt: json['createdAt'] as String,
    );
  }
}

class DeviceRegisterRequest {
  final String token;
  final String platform;
  final String? deviceName;

  const DeviceRegisterRequest({
    required this.token,
    required this.platform,
    this.deviceName,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'token': token,
      'platform': platform,
    };
    if (deviceName != null) map['deviceName'] = deviceName;
    return map;
  }
}
