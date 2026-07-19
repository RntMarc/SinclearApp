import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_app_bar.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../models/subscription_models.dart';
import '../widgets/subscription_member_row.dart';

/// Sub-page that shows full details of a single subscription.
///
/// Displays an info box (name, period, total price, member count) and a
/// compact member list inside a single card. Designed as a sub-page with
/// its own [DesignAppBar] including a back button.
class SubscriptionDetailScreen extends StatefulWidget {
  const SubscriptionDetailScreen({super.key, required this.subscription});

  final Subscription subscription;

  @override
  State<SubscriptionDetailScreen> createState() =>
      _SubscriptionDetailScreenState();
}

class _SubscriptionDetailScreenState extends State<SubscriptionDetailScreen> {
  List<SubscriptionParticipant> _participants = [];
  bool _loading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = AppScope.of(context).subscription;
      final data = await service.participants(widget.subscription.id);
      if (!mounted) return;
      setState(() {
        _participants = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Mitglieder konnten nicht geladen werden.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final sub = widget.subscription;

    return DesignSurface(
      child: Column(
        children: [
          DesignAppBar(
            title: sub.name,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Icon(
                Icons.arrow_back_rounded,
                color: tokens.textHigh,
                size: 24,
              ),
            ),
          ),
          Expanded(child: _buildBody(tokens, sub)),
        ],
      ),
    );
  }

  Widget _buildBody(DesignTokens tokens, Subscription sub) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(tokens.spaceXl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DesignText(_error!, style: DesignTextStyle.body),
                  SizedBox(height: tokens.spaceMd),
                  GestureDetector(
                    onTap: _load,
                    child: DesignText(
                      'Erneut versuchen',
                      style: DesignTextStyle.label,
                      color: tokens.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final period =
        '${_formatDate(sub.billingPeriodStart)} – ${_formatDate(sub.billingPeriodEnd)}';

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          tokens.spaceLg,
          tokens.spaceSm,
          tokens.spaceLg,
          tokens.spaceXxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DesignCard(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: EdgeInsets.all(tokens.spaceLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DesignText(sub.name, style: DesignTextStyle.subtitle),
                    SizedBox(height: tokens.spaceMd),
                    _infoRow(tokens, 'Zeitraum', period),
                    SizedBox(height: tokens.spaceSm),
                    _infoRow(
                      tokens,
                      'Gesamtpreis',
                      '${sub.basePrice.toStringAsFixed(2)} €',
                    ),
                    SizedBox(height: tokens.spaceSm),
                    _infoRow(tokens, 'Mitglieder', '${_participants.length}'),
                  ],
                ),
              ),
            ),
            SizedBox(height: tokens.spaceXl),
            const DesignText('Mitglieder', style: DesignTextStyle.subtitle),
            SizedBox(height: tokens.spaceMd),
            DesignCard(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.spaceLg,
                  vertical: tokens.spaceSm,
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < _participants.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: tokens.border.withValues(alpha: 0.3),
                        ),
                      SubscriptionMemberRow(participant: _participants[i]),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(DesignTokens tokens, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DesignText(label, style: DesignTextStyle.label, color: tokens.textLow),
        DesignText(value, style: DesignTextStyle.body),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }
}
