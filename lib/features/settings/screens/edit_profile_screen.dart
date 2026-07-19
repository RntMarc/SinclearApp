import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/image/image_compressor.dart';
import '../../../core/image/image_provider_helper.dart';
import '../../../core/network/api_client.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../../design/widgets/primitives/design_text_field.dart';
import '../../user/models/user_models.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _displayNameController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;
  bool _hasLoaded = false;
  String? _birthday;

  String? _existingImage;
  Uint8List? _imageBytes;
  bool _removeImage = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      _hasLoaded = true;
      _load();
    }
  }

  /// Schneidet Zeitanteile ab, sodass nur YYYY-MM-DD übrig bleibt.
  String? _normalizeDate(String? raw) {
    if (raw == null || raw.length < 10) return raw;
    return raw.substring(0, 10);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final user = await AppScope.of(context).user.getMeBase();
      if (!mounted) return;
      final normalized = _normalizeDate(user.birthday);
      if (kDebugMode) {
        debugPrint('[edit_profile] _load: raw birthday="${user.birthday}" normalized="$normalized"');
      }
      setState(() {
        _displayNameController.text = user.displayName;
        _birthday = normalized;
        _existingImage = user.image;
        _imageBytes = null;
        _removeImage = false;
        _loading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('[edit_profile] Failed to load profile: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Profil konnte nicht geladen werden.';
      });
    }
  }

  Future<void> _save() async {
    final displayName = _displayNameController.text.trim();
    if (displayName.isEmpty) {
      setState(() => _error = 'Der Anzeigename darf nicht leer sein.');
      return;
    }

    final birthdayToSend = _normalizeDate(_birthday);

    if (kDebugMode) {
      final imageInfo = _imageBytes != null
          ? 'base64_length=${base64Encode(_imageBytes!).length}, raw_bytes=${_imageBytes!.length}'
          : 'no_image';
      debugPrint(
        '[edit_profile] _save: displayName=$displayName birthday=$birthdayToSend (was "$_birthday") removeImage=$_removeImage image=$imageInfo',
      );
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final request = ProfileUpdateRequest(
        image: _imageBytes != null ? base64Encode(_imageBytes!) : null,
        removeImage: _removeImage,
        displayName: displayName,
        birthday: birthdayToSend,
        removeBirthday: birthdayToSend == null,
      );

      if (kDebugMode) {
        final json = request.toJson();
        final imagePreview = json['image'] is String
            ? 'len=${(json['image'] as String).length}, preview=${(json['image'] as String).substring(0, 80)}...'
            : '${json['image']}';
        debugPrint(
          '[edit_profile] Sending: image=$imagePreview birthday=$birthdayToSend removeImage=${json['removeImage']}',
        );
      }

      await AppScope.of(context).user.updateProfile(request);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profil gespeichert')));
    } on ApiException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[edit_profile] ApiException: status=${e.statusCode} error=${e.errorCode} message=${e.message} preview=${e.responsePreview}',
        );
      }
      setState(() => _error = e.message ?? 'Fehler beim Speichern.');
    } catch (e) {
      if (kDebugMode) debugPrint('[edit_profile] Unexpected error: $e');
      if (!mounted) return;
      setState(() => _error = 'Netzwerkfehler. Bitte prüfe deine Verbindung.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _birthday != null ? DateTime.tryParse(_birthday!) : null;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Geburtstag auswählen',
    );
    if (picked != null && mounted) {
      final formatted =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() => _birthday = formatted);
    }
  }

  Future<void> _showImagePicker() async {
    final tokens = DesignTheme.of(context);
    final hasImage =
        _imageBytes != null || (_existingImage != null && !_removeImage);

    final source = await showDesignSheet<ImageSource>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DesignText('Profilbild ändern', style: DesignTextStyle.title),
          SizedBox(height: tokens.spaceMd),
          GestureDetector(
            onTap: () => Navigator.pop(context, ImageSource.camera),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: tokens.spaceSm),
              child: const Row(
                children: [
                  Icon(Icons.camera_alt_rounded, size: 20),
                  SizedBox(width: 12),
                  DesignText('Foto aufnehmen'),
                ],
              ),
            ),
          ),
          SizedBox(height: tokens.spaceSm),
          GestureDetector(
            onTap: () => Navigator.pop(context, ImageSource.gallery),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: tokens.spaceSm),
              child: const Row(
                children: [
                  Icon(Icons.photo_library_rounded, size: 20),
                  SizedBox(width: 12),
                  DesignText('Aus Gallery wählen'),
                ],
              ),
            ),
          ),
          if (hasImage) ...[
            SizedBox(height: tokens.spaceSm),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _imageBytes = null;
                  _removeImage = true;
                });
              },
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: tokens.spaceSm),
                child: Row(
                  children: [
                    Icon(Icons.delete_rounded, size: 20, color: tokens.danger),
                    const SizedBox(width: 12),
                    DesignText('Profilbild entfernen', color: tokens.danger),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (source == null || !mounted) return;

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
      setState(() => _error = 'Bild konnte nicht verarbeitet werden.');
      return;
    }

    setState(() {
      _imageBytes = compressed;
      _removeImage = false;
      _error = null;
    });
  }

  ImageProvider? _resolvePreview() {
    if (_imageBytes != null) return MemoryImage(_imageBytes!);
    if (!_removeImage && _existingImage != null) {
      return resolveImageProvider(_existingImage);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    if (_loading) {
      return DesignSurface(
        child: Center(
          child: CircularProgressIndicator(color: tokens.primary),
        ),
      );
    }

    final preview = _resolvePreview();
    final hasImage =
        _imageBytes != null || (_existingImage != null && !_removeImage);

    return DesignSurface(
      child: Column(
        children: [
          DesignSubpageHeader(
            leading: DesignIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => context.pop(),
            ),
            title: 'Profil bearbeiten',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(tokens.spaceMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 56,
                          backgroundImage: preview,
                          child: preview == null
                              ? DesignText(
                                  _displayNameController.text.isNotEmpty
                                      ? _displayNameController.text[0].toUpperCase()
                                      : '?',
                                  style: DesignTextStyle.display,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: tokens.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              size: 20,
                              color: tokens.textOnPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: tokens.spaceSm),
                  Center(
                    child: DesignButton(
                      label: hasImage
                          ? 'Profilbild ändern'
                          : 'Profilbild hinzufügen',
                      variant: DesignButtonVariant.text,
                      icon: Icons.edit_rounded,
                      onPressed: _showImagePicker,
                    ),
                  ),
                  SizedBox(height: tokens.spaceLg),
                  DesignTextField(
                    controller: _displayNameController,
                    hint: 'Anzeigename',
                    prefixIcon: Icons.person_rounded,
                  ),
                  SizedBox(height: tokens.spaceMd),
                  Material(
                    type: MaterialType.transparency,
                    child: GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: tokens.spaceMd,
                          vertical: tokens.spaceSm,
                        ),
                        decoration: BoxDecoration(
                          color: tokens.surface,
                          borderRadius: BorderRadius.circular(tokens.radiusMd),
                          border: Border.all(
                            color: tokens.border.withValues(alpha: 0.8),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.cake_rounded, color: tokens.textLow, size: 20),
                            SizedBox(width: tokens.spaceSm),
                            Expanded(
                              child: DesignText(
                                _birthday != null ? _birthday! : 'Nicht angegeben',
                                color: _birthday != null
                                    ? tokens.textHigh
                                    : tokens.textLow,
                              ),
                            ),
                            Icon(
                              Icons.calendar_today_rounded,
                              color: tokens.textLow,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_birthday != null) ...[
                    SizedBox(height: tokens.spaceXs),
                    Align(
                      alignment: Alignment.centerRight,
                      child: DesignButton(
                        label: 'Geburtstag entfernen',
                        variant: DesignButtonVariant.text,
                        icon: Icons.close_rounded,
                        onPressed: () => setState(() => _birthday = null),
                      ),
                    ),
                  ],
                  SizedBox(height: tokens.spaceLg),
                  if (_error != null)
                    Padding(
                      padding: EdgeInsets.only(bottom: tokens.spaceMd),
                      child: DesignText(_error!, color: tokens.danger),
                    ),
                  DesignButton(
                    label: _saving ? 'Wird gespeichert…' : 'Speichern',
                    icon: Icons.save_rounded,
                    loading: _saving,
                    onPressed: _saving ? null : _save,
                    fullWidth: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
