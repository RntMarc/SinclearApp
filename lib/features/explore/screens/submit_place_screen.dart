import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/config/osm_config.dart';
import '../../../core/services/location_service.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/image/image_compressor.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_text_field.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/composite/design_map_marker.dart';
import '../models/explore_models.dart';

class SubmitPlaceScreen extends StatefulWidget {
  final ExploreSubmission? initial;

  const SubmitPlaceScreen({super.key, this.initial});

  @override
  State<SubmitPlaceScreen> createState() => _SubmitPlaceScreenState();
}

class _SubmitPlaceScreenState extends State<SubmitPlaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _websiteController = TextEditingController();
  final _mapLinkController = TextEditingController();
  final _commentController = TextEditingController();
  final _noteController = TextEditingController();
  final _mapController = MapController();

  LatLng? _selectedLocation;
  int _rating = 0;
  Uint8List? _imageBytes;
  bool _submitting = false;
  String? _error;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final s = widget.initial!;
      _nameController.text = s.name;
      _addressController.text = s.address ?? '';
      _websiteController.text = s.website ?? '';
      _mapLinkController.text = s.mapLink ?? '';
      _commentController.text = s.comment ?? '';
      _noteController.text = s.note ?? '';
      _selectedLocation = LatLng(s.latitude, s.longitude);
      _rating = s.rating ?? 0;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    _mapLinkController.dispose();
    _commentController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    final rawBytes = await picked.readAsBytes();
    final compressed = compressImage(rawBytes);
    if (compressed == null) {
      if (!mounted) return;
      setState(() => _error = 'Bild konnte nicht verarbeitet werden.');
      return;
    }
    if (!mounted) return;
    setState(() {
      _imageBytes = compressed;
      _error = null;
    });
  }

  void _showImagePicker() {
    final tokens = DesignTheme.of(context);
    showDesignSheet<bool>(
      context: context,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DesignText(
              'Foto hinzufuegen',
              style: DesignTextStyle.title,
              color: tokens.textHigh,
            ),
            SizedBox(height: tokens.spaceLg),
            DesignButton(
              variant: DesignButtonVariant.outlined,
              icon: Icons.camera_alt_rounded,
              label: 'Kamera',
              fullWidth: true,
              onPressed: () => Navigator.pop(context, true),
            ),
            SizedBox(height: tokens.spaceSm),
            DesignButton(
              variant: DesignButtonVariant.outlined,
              icon: Icons.photo_library_rounded,
              label: 'Galerie',
              fullWidth: true,
              onPressed: () => Navigator.pop(context, false),
            ),
            if (_imageBytes != null) ...[
              SizedBox(height: tokens.spaceSm),
              DesignButton(
                variant: DesignButtonVariant.text,
                icon: Icons.delete_outline_rounded,
                label: 'Foto entfernen',
                fullWidth: true,
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _imageBytes = null);
                },
              ),
            ],
          ],
        ),
      ),
    ).then((useCamera) {
      if (useCamera == null || !mounted) return;
      _pickImage(useCamera ? ImageSource.camera : ImageSource.gallery);
    });
  }

  Future<void> _useCurrentLocation() async {
    try {
      final position = await LocationService.determinePosition();
      if (!mounted) return;
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() => _selectedLocation = latLng);
      _mapController.move(latLng, 15);
    } on LocationServicesOffException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Standortdienste sind deaktiviert.'),
        ),
      );
    } on LocationPermissionDeniedForeverException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Standortzugriff wurde dauerhaft verweigert. '
            'Bitte in den App-Einstellungen aktivieren.',
          ),
          action: SnackBarAction(
            label: 'Einstellungen',
            onPressed: Geolocator.openAppSettings,
          ),
        ),
      );
    } on LocationPermissionDeniedException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Standortzugriff wurde verweigert.'),
        ),
      );
    } catch (e, st) {
      developer.log('Failed to get location', error: e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Standort konnte nicht ermittelt werden.'),
        ),
      );
    }
  }

  Future<void> _submit() async {
    debugPrint('[submit] === _submit() called ===');
    if (!_formKey.currentState!.validate()) {
      debugPrint('[submit] Form validation failed');
      return;
    }
    if (_selectedLocation == null) {
      debugPrint('[submit] No location selected');
      setState(() => _error = 'Bitte waehle einen Standort auf der Karte.');
      return;
    }
    if (_rating == 0) {
      debugPrint('[submit] No rating set');
      setState(() => _error = 'Bitte vergebe eine Bewertung (1-5 Sterne).');
      return;
    }

    debugPrint('[submit] Validation passed, starting submission');
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final explore = AppScope.of(context).explore;
      final photo = _imageBytes != null ? base64Encode(_imageBytes!) : null;
      debugPrint(
        '[submit] explore service obtained, photo.length=${photo?.length ?? 0}',
      );

      if (_isEditing) {
        final request = ExploreSubmissionUpdateRequest(
          name: _nameController.text.trim(),
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
          latitude: _selectedLocation!.latitude,
          longitude: _selectedLocation!.longitude,
          photo: photo,
          mapLink: _mapLinkController.text.trim().isEmpty
              ? null
              : _mapLinkController.text.trim(),
          website: _websiteController.text.trim().isEmpty
              ? null
              : _websiteController.text.trim(),
          rating: _rating,
          comment: _commentController.text.trim().isEmpty
              ? null
              : _commentController.text.trim(),
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        );
        debugPrint('[submit] Calling updateSubmission');
        await explore.updateSubmission(widget.initial!.id, request);
        debugPrint('[submit] updateSubmission succeeded');
      } else {
        final request = ExploreSubmissionCreateRequest(
          name: _nameController.text.trim(),
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
          latitude: _selectedLocation!.latitude,
          longitude: _selectedLocation!.longitude,
          photo: photo,
          mapLink: _mapLinkController.text.trim().isEmpty
              ? null
              : _mapLinkController.text.trim(),
          website: _websiteController.text.trim().isEmpty
              ? null
              : _websiteController.text.trim(),
          rating: _rating,
          comment: _commentController.text.trim().isEmpty
              ? null
              : _commentController.text.trim(),
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        );
        debugPrint('[submit] Calling createSubmission');
        await explore.createSubmission(request);
        debugPrint('[submit] createSubmission succeeded');
      }

      debugPrint('[submit] Checking mounted: $mounted');
      if (!mounted) {
        debugPrint('[submit] Not mounted after API call, returning early');
        return;
      }

      debugPrint('[submit] Showing success snackbar');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Einreichung aktualisiert.'
                : 'Ort eingereicht. Ein Admin prueft deine Meldung.',
          ),
        ),
      );

      debugPrint('[submit] Popping route');
      context.pop();
    } catch (e, st) {
      debugPrint('[submit] === EXCEPTION CAUGHT ===');
      debugPrint('[submit] Type: ${e.runtimeType}');
      debugPrint('[submit] Message: $e');
      debugPrint('[submit] StackTrace: $st');
      developer.log('Failed to submit place', error: e, stackTrace: st);
      if (!mounted) {
        debugPrint('[submit] Not mounted in catch block, returning');
        return;
      }
      setState(() {
        _submitting = false;
        _error = 'Fehler beim Speichern. Bitte versuche es erneut.';
      });
    }
    debugPrint('[submit] === _submit() finished ===');
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return DesignSurface(
      child: Column(
        children: [
          DesignSubpageHeader(
            title: _isEditing ? 'Einreichung bearbeiten' : 'Ort einreichen',
          ),
          Expanded(child: _buildBody(tokens)),
        ],
      ),
    );
  }

  Widget _buildBody(DesignTokens tokens) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.all(tokens.spaceLg),
        children: [
          _buildMapSection(tokens),
          SizedBox(height: tokens.spaceLg),
          _buildImageSection(tokens),
          SizedBox(height: tokens.spaceLg),
          _buildFormFields(tokens),
          SizedBox(height: tokens.spaceLg),
          _buildRatingSection(tokens),
          SizedBox(height: tokens.spaceLg),
          if (_error != null) ...[
            DesignText(
              _error!,
              style: DesignTextStyle.body,
              color: tokens.danger,
            ),
            SizedBox(height: tokens.spaceLg),
          ],
          DesignButton(
            variant: DesignButtonVariant.filled,
            label: _submitting
                ? (_isEditing ? 'Aktualisiere...' : 'Sende ab...')
                : (_isEditing ? 'Aktualisieren' : 'Absenden'),
            fullWidth: true,
            loading: _submitting,
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection(DesignTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            DesignText(
              'Standort',
              style: DesignTextStyle.subtitle,
              color: tokens.textHigh,
            ),
            const Spacer(),
            DesignButton(
              variant: DesignButtonVariant.text,
              icon: Icons.my_location_rounded,
              label: 'Aktueller Standort',
              onPressed: _useCurrentLocation,
            ),
          ],
        ),
        SizedBox(height: tokens.spaceSm),
        DesignText(
          'Tippe auf die Karte, um den Standort waehlen.',
          style: DesignTextStyle.body,
          color: tokens.textLow,
        ),
        SizedBox(height: tokens.spaceSm),
        SizedBox(
          height: 250,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(tokens.radiusMd),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter:
                    _selectedLocation ?? const LatLng(51.1657, 10.4515),
                initialZoom: _selectedLocation != null ? 15 : 6,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                onTap: (tapPosition, latLng) {
                  setState(() => _selectedLocation = latLng);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: OsmConfig.tileUrlTemplate,
                  userAgentPackageName: OsmConfig.tileUserAgent,
                  tileProvider: osmTileProvider(),
                ),
                if (_selectedLocation != null)
                  MarkerLayer(
                    markers: [
                      designMapMarker(
                        point: _selectedLocation!,
                        icon: Icons.location_on_rounded,
                        color: tokens.danger,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        if (_selectedLocation != null) ...[
          SizedBox(height: tokens.spaceSm),
          DesignText(
            '${_selectedLocation!.latitude.toStringAsFixed(5)}, '
            '${_selectedLocation!.longitude.toStringAsFixed(5)}',
            style: DesignTextStyle.label,
            color: tokens.textLow,
          ),
        ],
      ],
    );
  }

  Widget _buildImageSection(DesignTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DesignText(
          'Foto (optional)',
          style: DesignTextStyle.subtitle,
          color: tokens.textHigh,
        ),
        SizedBox(height: tokens.spaceSm),
        if (_imageBytes != null)
          Stack(
            alignment: Alignment.topRight,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(tokens.radiusMd),
                child: Image.memory(
                  _imageBytes!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: tokens.spaceSm,
                right: tokens.spaceSm,
                child: GestureDetector(
                  onTap: () => setState(() => _imageBytes = null),
                  child: Container(
                    padding: EdgeInsets.all(tokens.spaceXs),
                    decoration: BoxDecoration(
                      color: tokens.surface.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: tokens.textHigh,
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          GestureDetector(
            onTap: _showImagePicker,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: tokens.surface,
                borderRadius: BorderRadius.circular(tokens.radiusMd),
                border: Border.all(color: tokens.border, width: 1.5),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_a_photo_rounded,
                      size: 32,
                      color: tokens.textLow,
                    ),
                    SizedBox(height: tokens.spaceSm),
                    DesignText(
                      'Foto hinzufuegen',
                      style: DesignTextStyle.body,
                      color: tokens.textLow,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFormFields(DesignTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DesignTextField(
          controller: _nameController,
          hint: 'Name des Ortes *',
          prefixIcon: Icons.store_rounded,
        ),
        SizedBox(height: tokens.spaceMd),
        DesignTextField(
          controller: _addressController,
          hint: 'Adresse (optional)',
          prefixIcon: Icons.location_on_outlined,
        ),
        SizedBox(height: tokens.spaceMd),
        DesignTextField(
          controller: _websiteController,
          hint: 'Website (optional)',
          prefixIcon: Icons.language_rounded,
        ),
        SizedBox(height: tokens.spaceMd),
        DesignTextField(
          controller: _mapLinkController,
          hint: 'Google Maps Link (optional)',
          prefixIcon: Icons.map_rounded,
        ),
        SizedBox(height: tokens.spaceMd),
        DesignTextField(
          controller: _commentController,
          hint: 'Kommentar (optional)',
          prefixIcon: Icons.comment_outlined,
        ),
        SizedBox(height: tokens.spaceMd),
        DesignTextField(
          controller: _noteController,
          hint: 'Notiz fuer Admins (optional)',
          prefixIcon: Icons.info_outline_rounded,
        ),
      ],
    );
  }

  Widget _buildRatingSection(DesignTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DesignText(
          'Bewertung *',
          style: DesignTextStyle.subtitle,
          color: tokens.textHigh,
        ),
        SizedBox(height: tokens.spaceSm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final filled = i < _rating;
            return GestureDetector(
              onTap: () => setState(() => _rating = i + 1),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: tokens.spaceXs),
                child: Icon(
                  filled ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 40,
                  color: tokens.primary,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
