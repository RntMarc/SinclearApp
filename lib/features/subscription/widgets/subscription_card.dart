import 'package:flutter/material.dart';

import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_grid_card.dart';
import '../models/subscription_models.dart';

/// Thin adapter that maps a [Subscription] model onto a [DesignGridCard].
class SubscriptionCard extends StatelessWidget {
  const SubscriptionCard({
    super.key,
    required this.subscription,
    this.onTap,
  });

  final Subscription subscription;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final period =
        '${_formatDate(subscription.billingPeriodStart)} – ${_formatDate(subscription.billingPeriodEnd)}';

    return DesignGridCard(
      title: subscription.name,
      period: period,
      amount: '${subscription.basePrice.toStringAsFixed(2)} €',
      amountColor: subscription.hasPaid ? tokens.success : tokens.danger,
      onTap: onTap,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }
}
