class Subscription {
  final String id;
  final String name;
  final DateTime billingPeriodStart;
  final DateTime billingPeriodEnd;
  final double basePrice;
  final bool hasPaid;
  final String? userName;

  const Subscription({
    required this.id,
    required this.name,
    required this.billingPeriodStart,
    required this.billingPeriodEnd,
    required this.basePrice,
    required this.hasPaid,
    this.userName,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      name: json['name'] as String,
      billingPeriodStart: _parseDate(json['billingPeriodStart']),
      billingPeriodEnd: _parseDate(json['billingPeriodEnd']),
      basePrice: (json['basePrice'] as num).toDouble(),
      hasPaid: json['hasPaid'] == true || json['hasPaid'] == 1,
      userName: json['userName'] as String?,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    throw ArgumentError('Invalid date value: $value');
  }

  /// Deduplicates a list of subscriptions by [id].
  ///
  /// The API may return multiple entries for the same subscription (e.g. when
  /// non-user participants also match the query). This method keeps only the
  /// first entry per subscription.
  static List<Subscription> deduplicate(List<Subscription> subscriptions) {
    final Map<String, Subscription> unique = {};
    for (final sub in subscriptions) {
      unique.putIfAbsent(sub.id, () => sub);
    }
    return unique.values.toList();
  }
}

class SubscriptionParticipant {
  final String id;
  final String? userId;
  final String? userName;
  final bool isUser;
  final bool hasPaid;
  final String? userDisplayName;
  final String? userImage;

  const SubscriptionParticipant({
    required this.id,
    this.userId,
    this.userName,
    required this.isUser,
    required this.hasPaid,
    this.userDisplayName,
    this.userImage,
  });

  factory SubscriptionParticipant.fromJson(Map<String, dynamic> json) {
    return SubscriptionParticipant(
      id: json['id'] as String,
      userId: json['userId'] as String?,
      userName: json['userName'] as String?,
      isUser: json['isUser'] == true || json['isUser'] == 1,
      hasPaid: json['hasPaid'] == true || json['hasPaid'] == 1,
      userDisplayName: json['userDisplayName'] as String?,
      userImage: json['userImage'] as String?,
    );
  }

  String get displayName =>
      userDisplayName ?? userName ?? (isUser ? 'Unbekannt' : 'Gast');
}
