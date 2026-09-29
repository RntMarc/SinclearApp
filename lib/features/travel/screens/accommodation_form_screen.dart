import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/network/api_client.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../../design/widgets/primitives/design_text_field.dart';
import '../models/travel_models.dart';
import '../services/travel_service.dart';
import '../travel_error_messages.dart';
import '../widgets/accommodation_picker_sheet.dart';

/// Formular zum Erstellen/Bearbeiten einer Unterkunft innerhalb einer Reise.
class AccommodationFormScreen extends StatefulWidget {
  final String tripId;
  final String? accommodationId;

  const AccommodationFormScreen({
    super.key,
    required this.tripId,
    this.accommodationId,
  });

  @override
  State<AccommodationFormScreen> createState() =>
      _AccommodationFormScreenState();
}

class _AccommodationFormScreenState extends State<AccommodationFormScreen> {
  TravelService get _service => AppScope.of(context).travel;

  final _name = TextEditingController();
  final _description = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _mail = TextEditingController();

  bool _isHotel = false;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  /// Beim Anlegen gewählte vorhandene Unterkunft (Wiederverwendung).
  TravelAccommodation? _reuse;

  bool get _isEdit => widget.accommodationId != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loading) return;
    _loading = false;
    if (_isEdit) _load();
  }

  Future<void> _load() async {
    try {
      final accommodation = await _service.getAccommodationDetail(
        widget.tripId,
        widget.accommodationId!,
      );
      if (!mounted) return;
      setState(() {
        _name.text = accommodation.name;
        _description.text = accommodation.description ?? '';
        _address.text = accommodation.address ?? '';
        _phone.text = accommodation.phone ?? '';
        _mail.text = accommodation.mail ?? '';
        _isHotel = accommodation.ishotel == 1;
      });
    } catch (e, st) {
      developer.log('Failed to load accommodation', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _error = 'Unterkunft konnte nicht geladen werden.');
    }
  }

  Future<void> _pickExisting() async {
    setState(() => _saving = true);
    try {
      final catalog = await _service.listAccommodationCatalog();
      if (!mounted) return;
      final chosen = await showAccommodationPicker(
        context,
        options: catalog,
        selectedId: _reuse?.id,
        title: 'Vorhandene Unterkunft wählen',
      );
      if (!mounted || chosen == null) return;
      for (final a in catalog) {
        if (a.id == chosen) {
          setState(() => _reuse = a);
          break;
        }
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(travelErrorMessage(e))));
    } catch (e, st) {
      developer.log('Failed to load catalog', error: e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Laden fehlgeschlagen.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    if (!_isEdit && _reuse != null) {
      setState(() => _saving = true);
      try {
        await _service.linkAccommodation(widget.tripId, _reuse!.id);
        if (!mounted) return;
        context.pop(true);
      } on ApiException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(travelErrorMessage(e))));
      } catch (e, st) {
        developer.log('Failed to link accommodation', error: e, stackTrace: st);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Fehler beim Speichern.')));
      } finally {
        if (mounted) setState(() => _saving = false);
      }
      return;
    }

    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte gib einen Namen an.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      if (_isEdit) {
        await _service.updateAccommodation(
          widget.tripId,
          widget.accommodationId!,
          name: name,
          description: _description.text.trim(),
          address: _address.text.trim(),
          phone: _phone.text.trim(),
          mail: _mail.text.trim(),
          isHotel: _isHotel,
        );
      } else {
        await _service.createAccommodation(
          widget.tripId,
          name: name,
          description: _description.text.trim().isEmpty
              ? null
              : _description.text.trim(),
          address: _address.text.trim().isEmpty ? null : _address.text.trim(),
          phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
          mail: _mail.text.trim().isEmpty ? null : _mail.text.trim(),
          isHotel: _isHotel,
        );
      }
      if (!mounted) return;
      context.pop(true);
    } on ApiException catch (e) {
      developer.log('Failed to save accommodation', error: e);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(travelErrorMessage(e))));
    } catch (e, st) {
      developer.log('Failed to save accommodation', error: e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fehler beim Speichern.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _address.dispose();
    _phone.dispose();
    _mail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    return DesignSurface(
      child: Column(
        children: [
          DesignSubpageHeader(
            leading: DesignIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => context.pop(),
            ),
            title: _isEdit ? 'Unterkunft bearbeiten' : 'Neue Unterkunft',
          ),
          Expanded(
            child: _error != null
                ? _errorView(tokens)
                : SingleChildScrollView(
                    padding: EdgeInsets.all(tokens.spaceLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!_isEdit) ...[
                          _reuseSection(tokens),
                          if (_reuse == null) ...[
                            SizedBox(height: tokens.spaceXl),
                            DesignText(
                              'Oder neue Unterkunft anlegen',
                              style: DesignTextStyle.subtitle,
                              color: tokens.textHigh,
                            ),
                            SizedBox(height: tokens.spaceLg),
                          ],
                        ],
                        if (_isEdit || _reuse == null) ...[
                          _label(tokens, 'Name'),
                          SizedBox(height: tokens.spaceSm),
                          DesignTextField(
                            hint: 'Name der Unterkunft',
                            controller: _name,
                          ),
                          SizedBox(height: tokens.spaceMd),
                          _label(tokens, 'Beschreibung'),
                          SizedBox(height: tokens.spaceSm),
                          DesignTextField(
                            hint: 'Beschreibung (optional)',
                            controller: _description,
                            maxLines: 3,
                          ),
                          SizedBox(height: tokens.spaceMd),
                          _label(tokens, 'Adresse'),
                          SizedBox(height: tokens.spaceSm),
                          DesignTextField(hint: 'Adresse', controller: _address),
                          SizedBox(height: tokens.spaceMd),
                          _label(tokens, 'Kontakt'),
                          SizedBox(height: tokens.spaceSm),
                          DesignTextField(
                            hint: 'Telefon (optional)',
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                          ),
                          SizedBox(height: tokens.spaceMd),
                          DesignTextField(
                            hint: 'E-Mail (optional)',
                            controller: _mail,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          SizedBox(height: tokens.spaceLg),
                          Row(
                            children: [
                              Expanded(
                                child: DesignText(
                                  'Hotel',
                                  style: DesignTextStyle.body,
                                  color: tokens.textHigh,
                                ),
                              ),
                              Material(
                                type: MaterialType.transparency,
                                child: Switch(
                                  value: _isHotel,
                                  activeThumbColor: tokens.primary,
                                  onChanged: (v) =>
                                      setState(() => _isHotel = v),
                                ),
                              ),
                            ],
                          ),
                        ],
                        SizedBox(height: tokens.spaceXxl),
                        DesignButton(
                          label: _isEdit
                              ? 'Speichern'
                              : (_reuse != null ? 'Übernehmen' : 'Erstellen'),
                          fullWidth: true,
                          loading: _saving,
                          onPressed: _save,
                        ),
                        SizedBox(height: tokens.spaceXl),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _reuseSection(DesignTokens tokens) {
    final reuse = _reuse;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(tokens, 'Vorhandene Unterkunft'),
        SizedBox(height: tokens.spaceSm),
        if (reuse != null) ...[
          Row(
            children: [
              Icon(Icons.check_circle_rounded, color: tokens.primary, size: 20),
              SizedBox(width: tokens.spaceSm),
              Expanded(
                child: DesignText(
                  reuse.name,
                  style: DesignTextStyle.body,
                  color: tokens.textHigh,
                ),
              ),
            ],
          ),
          if (reuse.address != null) ...[
            SizedBox(height: tokens.spaceXs),
            DesignText(
              reuse.address!,
              style: DesignTextStyle.label,
              color: tokens.textLow,
            ),
          ],
          SizedBox(height: tokens.spaceSm),
        ],
        DesignButton(
          label: reuse == null
              ? 'Vorhandene Unterkunft wählen'
              : 'Andere Unterkunft wählen',
          variant: DesignButtonVariant.outlined,
          icon: Icons.search_rounded,
          onPressed: _pickExisting,
        ),
        if (reuse != null) ...[
          SizedBox(height: tokens.spaceSm),
          DesignButton(
            label: 'Stattdessen neue Unterkunft anlegen',
            variant: DesignButtonVariant.text,
            onPressed: () => setState(() => _reuse = null),
          ),
        ],
      ],
    );
  }

  Widget _errorView(DesignTokens tokens) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(tokens.spaceXl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DesignText(
              _error!,
              style: DesignTextStyle.body,
              color: tokens.textHigh,
            ),
            SizedBox(height: tokens.spaceMd),
            DesignButton(
              label: 'Erneut versuchen',
              variant: DesignButtonVariant.outlined,
              onPressed: _load,
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(DesignTokens tokens, String text) {
    return DesignText(
      text,
      style: DesignTextStyle.label,
      color: tokens.textLow,
    );
  }
}
