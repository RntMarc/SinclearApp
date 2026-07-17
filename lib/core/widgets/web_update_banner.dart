import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/web_update_service.dart';
import '../../design/theme/design_theme.dart';
import '../../design/widgets/foundation/design_text.dart';
import '../../design/widgets/primitives/design_button.dart';

class WebUpdateBanner extends StatefulWidget {
  final WebUpdateService service;
  final Widget child;

  const WebUpdateBanner({
    super.key,
    required this.service,
    required this.child,
  });

  @override
  State<WebUpdateBanner> createState() => _WebUpdateBannerState();
}

class _WebUpdateBannerState extends State<WebUpdateBanner> {
  @override
  void initState() {
    super.initState();
    widget.service.updateAvailable.addListener(_onUpdate);
  }

  @override
  void didUpdateWidget(WebUpdateBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.service != widget.service) {
      oldWidget.service.updateAvailable.removeListener(_onUpdate);
      widget.service.updateAvailable.addListener(_onUpdate);
    }
  }

  @override
  void dispose() {
    widget.service.updateAvailable.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return widget.child;

    return ValueListenableBuilder<bool>(
      valueListenable: widget.service.updateAvailable,
      builder: (context, available, child) {
        return Column(
          children: [
            if (available) _UpdateBanner(service: widget.service),
            Expanded(child: child!),
          ],
        );
      },
      child: widget.child,
    );
  }
}

class _UpdateBanner extends StatelessWidget {
  final WebUpdateService service;

  const _UpdateBanner({required this.service});

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final version = service.latestVersion;

    return Container(
      color: tokens.primary.withValues(alpha: 0.15),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.system_update_rounded,
                color: tokens.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DesignText(
                  version != null
                      ? 'Update verfügbar (v$version)'
                      : 'Update verfügbar',
                  style: DesignTextStyle.body,
                  color: tokens.primary,
                ),
              ),
              DesignButton(
                variant: DesignButtonVariant.text,
                label: 'Später',
                onPressed: () => service.dismiss(),
              ),
              DesignButton(
                variant: DesignButtonVariant.filled,
                label: 'Aktualisieren',
                onPressed: () => service.reload(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
