import 'package:flutter/material.dart';

import '../../../core/utils/date_utils.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/press_scale.dart';
import '../../subscription/models/subscription_models.dart';
import '../../subscription/services/subscription_service.dart';
import '../dashboard_widget.dart';
import '../dashboard_widget_spec.dart';

/// Anzeige-Datensatz einer offenen Zahlung (bzw. der „+X weitere“-Zeile).
class PaymentRow implements DashboardRow {
  final String name;
  final DateTime periodEnd;
  final double price;
  final bool isMore;
  final int moreCount;

  const PaymentRow({
    required this.name,
    required this.periodEnd,
    required this.price,
    this.isMore = false,
    this.moreCount = 0,
  });

  factory PaymentRow.fromSubscription(Subscription subscription) {
    return PaymentRow(
      name: subscription.name,
      periodEnd: subscription.billingPeriodEnd,
      price: subscription.basePrice,
    );
  }

  factory PaymentRow.more(int count) {
    return PaymentRow(
      name: '',
      periodEnd: DateTime.fromMillisecondsSinceEpoch(0),
      price: 0,
      isMore: true,
      moreCount: count,
    );
  }

  factory PaymentRow.fromJson(Map<String, dynamic> json) {
    return PaymentRow(
      name: json['name'] as String,
      periodEnd: DateTime.fromMillisecondsSinceEpoch(json['periodEnd'] as int),
      price: (json['price'] as num).toDouble(),
      isMore: json['isMore'] as bool? ?? false,
      moreCount: (json['moreCount'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'name': name,
    'periodEnd': periodEnd.millisecondsSinceEpoch,
    'price': price,
    'isMore': isMore,
    'moreCount': moreCount,
  };
}

/// Widget „Offene Zahlungen“ – Abos, die noch nicht bezahlt wurden.
///
/// Feste Höhe: max. 3 Zeilen; bei mehr offenen Abos zeigt die dritte Zeile
/// „+X weitere offene Zahlungen“. Keine Detail-Route, da `/abos` nur eine
/// Liste ist.
class PaymentsWidgetSpec extends DashboardWidgetSpec {
  PaymentsWidgetSpec(this._service);

  final SubscriptionService _service;

  @override
  DashboardWidgetType get type => DashboardWidgetType.openPayments;

  @override
  String get listRoute => '/abos';

  @override
  Future<List<DashboardRow>> fetch(int count) async {
    final open =
        (await _service.list())
            .where((subscription) => !subscription.hasPaid)
            .toList()
          ..sort((a, b) => a.billingPeriodEnd.compareTo(b.billingPeriodEnd));
    final rows = <PaymentRow>[
      for (final subscription in open.take(2))
        PaymentRow.fromSubscription(subscription),
    ];
    if (open.length > 3) rows.add(PaymentRow.more(open.length - 2));
    return [for (final row in rows) row];
  }

  @override
  DashboardRow rowFromJson(Map<String, dynamic> json) =>
      PaymentRow.fromJson(json);

  @override
  bool get rowsTappable => false;

  @override
  Widget rowBuilder(
    BuildContext context,
    DashboardRow row,
    VoidCallback? onTap,
  ) {
    final payment = row as PaymentRow;
    final tokens = DesignTheme.of(context);
    return PressScale(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tokens.surfaceVariant,
              borderRadius: BorderRadius.circular(tokens.radiusMd),
            ),
            child: Icon(Icons.payments_rounded, size: 18, color: tokens.danger),
          ),
          SizedBox(width: tokens.spaceMd),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DesignText(
                  payment.isMore
                      ? '+${payment.moreCount} weitere offene Zahlungen'
                      : payment.name,
                  style: DesignTextStyle.body,
                  color: tokens.textHigh,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!payment.isMore) ...[
                  SizedBox(height: tokens.spaceXs),
                  DesignText(
                    '${formatDate(payment.periodEnd)} · ${payment.price.toStringAsFixed(2)} €',
                    style: DesignTextStyle.label,
                    color: tokens.textLow,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
