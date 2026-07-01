import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/image/image_compressor.dart';
import '../../../core/image/image_provider_helper.dart';
import '../../../core/network/api_client.dart';
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
    final theme = Theme.of(context);
    final hasImage =
        _imageBytes != null || (_existingImage != null && !_removeImage);

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                'Profilbild ändern',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Foto aufnehmen'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Aus Gallery wählen'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            if (hasImage)
              ListTile(
                leading: Icon(
                  Icons.delete_rounded,
                  color: theme.colorScheme.error,
                ),
                title: Text(
                  'Profilbild entfernen',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _imageBytes = null;
                    _removeImage = true;
                  });
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
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
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final preview = _resolvePreview();
    final hasImage =
        _imageBytes != null || (_existingImage != null && !_removeImage);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil bearbeiten'),
        titleTextStyle: theme.textTheme.titleMedium,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
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
                          ? Text(
                              _displayNameController.text.isNotEmpty
                                  ? _displayNameController.text[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.camera_alt_rounded,
                          size: 20,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _showImagePicker,
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: Text(
                    hasImage ? 'Profilbild ändern' : 'Profilbild hinzufügen',
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Anzeigename',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_rounded),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Geburtstag',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.cake_rounded),
                    suffixIcon: Icon(Icons.calendar_today_rounded),
                  ),
                  child: Text(
                    _birthday != null ? _birthday! : 'Nicht angegeben',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _birthday != null
                          ? null
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              if (_birthday != null) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _birthday = null),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Geburtstag entfernen'),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _error!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(_saving ? 'Wird gespeichert…' : 'Speichern'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
