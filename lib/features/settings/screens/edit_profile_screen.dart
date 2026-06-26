import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/di/app_scope.dart';
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

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final user = await AppScope.of(context).user.getMeBase();
      if (!mounted) return;
      setState(() {
        _displayNameController.text = user.displayName;
        _birthday = user.birthday;
        _existingImage = user.image;
        _imageBytes = null;
        _removeImage = false;
        _loading = false;
      });
    } catch (e, st) {
      developer.log('Failed to load profile', error: e, stackTrace: st);
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

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await AppScope.of(context).user.updateProfile(
        ProfileUpdateRequest(
          image: _imageBytes != null ? base64Encode(_imageBytes!) : null,
          removeImage: _removeImage,
          displayName: displayName,
          birthday: _birthday,
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
      showCupertinoDialog<void>(
        context: context,
        builder: (_) => const CupertinoAlertDialog(
          content: Text('Profil gespeichert'),
        ),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message ?? 'Fehler beim Speichern.');
    } catch (e, st) {
      developer.log('Failed to save profile', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _error = 'Netzwerkfehler. Bitte prüfe deine Verbindung.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _birthday != null ? DateTime.tryParse(_birthday!) : null;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Abbrechen'),
                ),
                CupertinoButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fertig'),
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initial ?? DateTime(2000, 1, 1),
                minimumYear: 1900,
                maximumYear: now.year,
                onDateTimeChanged: (picked) {
                  final formatted =
                      '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                  setState(() => _birthday = formatted);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showImagePicker() async {
    final hasImage =
        _imageBytes != null || (_existingImage != null && !_removeImage);

    final source = await showCupertinoModalPopup<ImageSource>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Profilbild ändern'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.camera_fill, size: 20),
                SizedBox(width: 8),
                Text('Foto aufnehmen'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.photo_fill, size: 20),
                SizedBox(width: 8),
                Text('Aus Gallery wählen'),
              ],
            ),
          ),
          if (hasImage)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _imageBytes = null;
                  _removeImage = true;
                });
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.trash_fill, size: 20),
                  SizedBox(width: 8),
                  Text('Profilbild entfernen'),
                ],
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
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

    final bytes = await picked.readAsBytes();
    if (bytes.length > 200 * 1024) {
      setState(() => _error = 'Bild darf maximal 200 KB groß sein.');
      return;
    }

    setState(() {
      _imageBytes = bytes;
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
    final theme = CupertinoTheme.of(context);

    if (_loading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    final preview = _resolvePreview();
    final hasImage =
        _imageBytes != null || (_existingImage != null && !_removeImage);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Profil bearbeiten'),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Stack(
                  children: [
                    ClipOval(
                      child: Container(
                        width: 112,
                        height: 112,
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: preview != null
                            ? Image(image: preview, fit: BoxFit.cover)
                            : Center(
                                child: Text(
                                  _displayNameController.text.isNotEmpty
                                      ? _displayNameController.text[0]
                                          .toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w600,
                                    color: theme.primaryColor,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.camera_fill,
                          size: 20,
                          color: CupertinoColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: CupertinoButton(
                  onPressed: _showImagePicker,
                  child: Text(
                    hasImage ? 'Profilbild ändern' : 'Profilbild hinzufügen',
                    style: TextStyle(color: theme.primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              CupertinoTextField(
                controller: _displayNameController,
                placeholder: 'Anzeigename',
                prefix: const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Icon(CupertinoIcons.person, size: 20),
                ),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.gift, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _birthday != null ? _birthday! : 'Nicht angegeben',
                          style: TextStyle(
                            fontSize: 16,
                            color: _birthday != null
                                ? theme.textTheme.textStyle.color
                                : theme.textTheme.textStyle.color
                                      ?.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                      const Icon(
                        CupertinoIcons.calendar,
                        size: 20,
                        color: CupertinoColors.systemGrey,
                      ),
                    ],
                  ),
                ),
              ),
              if (_birthday != null) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => setState(() => _birthday = null),
                    child: const Text(
                      'Geburtstag entfernen',
                      style: TextStyle(
                        fontSize: 13,
                        color: CupertinoColors.destructiveRed,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      fontSize: 15,
                      color: CupertinoColors.destructiveRed,
                    ),
                  ),
                ),
              CupertinoButton.filled(
                onPressed: _saving ? null : _save,
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: _saving
                    ? const CupertinoActivityIndicator(
                        color: CupertinoColors.white,
                      )
                    : const Text('Speichern'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
