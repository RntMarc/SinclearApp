import 'dart:math';
import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../models/subscription_models.dart';
import '../widgets/subscription_card.dart';
import 'subscription_detail_screen.dart';

class SubscriptionListScreen extends StatefulWidget {
  const SubscriptionListScreen({super.key});

  @override
  State<SubscriptionListScreen> createState() =>
      _SubscriptionListScreenState();
}

class _SubscriptionListScreenState extends State<SubscriptionListScreen> {
  List<Subscription> _subscriptions = [];
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
      final data = await service.list();
      if (!mounted) return;
      setState(() {
        _subscriptions = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Abonnements konnten nicht geladen werden.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    return DesignSurface(
      padding: EdgeInsets.only(top: tokens.spaceLg),
      child: _buildBody(tokens),
    );
  }

  Widget _buildBody(DesignTokens tokens) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(tokens.spaceXl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!),
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
      );
    }

    if (_subscriptions.isEmpty) {
      return const Center(
        child: DesignText(
          'Keine Abonnements vorhanden.',
          style: DesignTextStyle.body,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = max(1, constraints.maxWidth ~/ 200);
          final aspectRatio = crossAxisCount == 1 ? 1.5 : 0.85;

          return GridView.builder(
            padding: EdgeInsets.fromLTRB(
              tokens.spaceLg,
              tokens.spaceMd,
              tokens.spaceLg,
              tokens.spaceXxl,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: tokens.spaceMd,
              crossAxisSpacing: tokens.spaceMd,
              childAspectRatio: aspectRatio,
            ),
            itemCount: _subscriptions.length,
            itemBuilder: (context, index) {
              final sub = _subscriptions[index];
              return SubscriptionCard(
                subscription: sub,
                onTap: () => _openDetail(sub),
              );
            },
          );
        },
      ),
    );
  }

  void _openDetail(Subscription sub) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubscriptionDetailScreen(subscription: sub),
      ),
    );
  }
}
