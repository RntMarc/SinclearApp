import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/image/image_compressor.dart';
import '../../../core/network/api_client.dart';
import '../../user/models/user_models.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  final _birthdayController = TextEditingController();

  int _currentPage = 0;
  bool _aiConsent = false;
  bool _dataConsent = false;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  Uint8List? _imageBytes;
  String? _existingImageUrl;

  static const _totalPages = 6;

  bool get _canProceed {
    return switch (_currentPage) {
      1 => _aiConsent && _dataConsent,
      _ => true,
    };
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final user =
          await AppScope.of(context).user.getMeBase();
      if (!mounted) return;
      setState(() {
        _nameController.text = user.displayName;
        _existingImageUrl = user.image;
        _loading = false;
      });
    } catch (e, st) {
      developer.log(
        'Failed to load profile for onboarding',
        error: e,
        stackTrace: st,
      );
      if (mounted) setState(() => _loading = false);
    }
  }

  void _nextPage() {
    if (!_canProceed) return;
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                'Profilbild auswählen',
                style: TextStyle(fontWeight: FontWeight.bold),
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
      _existingImageUrl = null;
    });
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Geburtstag auswählen',
    );
    if (picked != null && mounted) {
      final formatted =
          '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}';
      setState(() => _birthdayController.text = formatted);
    }
  }

  Future<void> _finish() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final scope = AppScope.of(context);
      await scope.user.updateProfile(
        ProfileUpdateRequest(
          image: _imageBytes != null ? base64Encode(_imageBytes!) : null,
          displayName: _nameController.text.trim().isNotEmpty
              ? _nameController.text.trim()
              : null,
          birthday: _birthdayController.text.isNotEmpty
              ? _birthdayController.text
              : null,
        ),
      );
    } on ApiException catch (e) {
      developer.log(
        'updateProfile failed',
        name: 'onboarding',
        level: 1000,
        error: e,
      );
      if (!mounted) return;
      setState(() => _error = 'Profil speichern fehlgeschlagen: $e');
      return;
    } catch (e, st) {
      developer.log(
        'updateProfile unexpected',
        name: 'onboarding',
        level: 1000,
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      setState(() => _error = 'Profil speichern fehlgeschlagen: $e');
      return;
    }

    try {
      final scope = AppScope.of(context);
      await scope.auth.completeOnboarding();
    } on ApiException catch (e) {
      developer.log(
        'completeOnboarding failed',
        name: 'onboarding',
        level: 1000,
        error: e,
      );
      if (!mounted) return;
      setState(() => _error = 'Onboarding abschließen fehlgeschlagen: $e');
      return;
    } catch (e, st) {
      developer.log(
        'completeOnboarding unexpected',
        name: 'onboarding',
        level: 1000,
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      setState(() => _error = 'Onboarding abschließen fehlgeschlagen: $e');
      return;
    }

    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: [
                  _WelcomePage(theme: theme),
                  _ConsentPage(
                    theme: theme,
                    aiConsent: _aiConsent,
                    dataConsent: _dataConsent,
                    onAiChanged: (v) => setState(() => _aiConsent = v),
                    onDataChanged: (v) => setState(() => _dataConsent = v),
                  ),
                  _ProfilePage(
                    theme: theme,
                    nameController: _nameController,
                    birthdayController: _birthdayController,
                    imageBytes: _imageBytes,
                    existingImageUrl: _existingImageUrl,
                    onPickImage: _pickImage,
                    onPickBirthday: _pickBirthday,
                  ),
                  _SocialHintPage(theme: theme),
                  _PwaHintPage(theme: theme),
                  _DonePage(theme: theme),
                ],
              ),
            ),
            _buildBottomBar(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    final isFirst = _currentPage == 0;
    final isLast = _currentPage == _totalPages - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          Row(
            children: [
              if (!isFirst)
                TextButton(
                  onPressed: _prevPage,
                  child: const Text('Zurück'),
                )
              else
                const SizedBox.shrink(),
              const Spacer(),
              ...List.generate(
                _totalPages,
                (i) => Container(
                  width: i == _currentPage ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: i == _currentPage
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const Spacer(),
              if (isLast)
                FilledButton(
                  onPressed: _saving ? null : _finish,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Los geht\'s!'),
                )
              else
                FilledButton(
                  onPressed: _canProceed ? _nextPage : null,
                  child: const Text('Weiter'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.waving_hand_rounded,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Willkommen bei Beyond!',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Schön, dass du da bist. Lass uns in einigen Schritten '
              'dein Konto einrichten.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsentPage extends StatelessWidget {
  const _ConsentPage({
    required this.theme,
    required this.aiConsent,
    required this.dataConsent,
    required this.onAiChanged,
    required this.onDataChanged,
  });

  final ThemeData theme;
  final bool aiConsent;
  final bool dataConsent;
  final ValueChanged<bool> onAiChanged;
  final ValueChanged<bool> onDataChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Wichtige Hinweise',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.smart_toy_rounded, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Diese App wurde mit Künstlicher Intelligenz '
                          'erstellt. Es können Fehler und '
                          'Sicherheitslücken vorhanden sein.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: aiConsent,
                    onChanged: (v) => onAiChanged(v ?? false),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text(
                      'Ich habe zur Kenntnis genommen, dass die App '
                      'mit KI erstellt wurde.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.shield_rounded, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Alle Angaben im Profil sind freiwillig. '
                          'Teile nur Informationen und Inhalte, '
                          'mit denen du dich wohlfühlst und der App, '
                          'der KI und Marc vertraust.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: dataConsent,
                    onChanged: (v) => onDataChanged(v ?? false),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text(
                      'Ich verstehe und stimme zu.',
                    ),
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

class _ProfilePage extends StatelessWidget {
  const _ProfilePage({
    required this.theme,
    required this.nameController,
    required this.birthdayController,
    required this.imageBytes,
    required this.existingImageUrl,
    required this.onPickImage,
    required this.onPickBirthday,
  });

  final ThemeData theme;
  final TextEditingController nameController;
  final TextEditingController birthdayController;
  final Uint8List? imageBytes;
  final String? existingImageUrl;
  final VoidCallback onPickImage;
  final VoidCallback onPickBirthday;

  @override
  Widget build(BuildContext context) {
    ImageProvider? avatar;
    if (imageBytes != null) {
      avatar = MemoryImage(imageBytes!);
    } else if (existingImageUrl != null &&
        existingImageUrl!.isNotEmpty) {
      avatar = NetworkImage(existingImageUrl!);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Text(
            'Dein Profil',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Alles ist freiwillig. Du kannst dein Profil '
            'später jederzeit in den Einstellungen ändern.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: onPickImage,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 56,
                  backgroundImage: avatar,
                  child: avatar == null
                      ? Icon(
                          Icons.person_rounded,
                          size: 48,
                          color: theme.colorScheme.onPrimaryContainer,
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
                      size: 18,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onPickImage,
            icon: const Icon(Icons.edit_rounded, size: 16),
            label: Text(
              avatar != null ? 'Bild ändern' : 'Profilbild hinzufügen',
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Anzeigename',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_rounded),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: onPickBirthday,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Geburtstag',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.cake_rounded),
                suffixIcon: Icon(Icons.calendar_today_rounded),
              ),
              child: Text(
                birthdayController.text.isNotEmpty
                    ? birthdayController.text
                    : 'Nicht angegeben',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: birthdayController.text.isEmpty
                      ? theme.colorScheme.onSurfaceVariant
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialHintPage extends StatelessWidget {
  const _SocialHintPage({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_rounded,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Social Media & Messenger',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Du kannst deine Social-Media-Profile und '
              'verwendeten Messenger später in den '
              'Einstellungen hinterlegen.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PwaHintPage extends StatelessWidget {
  const _PwaHintPage({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.phone_android_rounded,
            size: 64,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'App-Installation',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Als PWA verwenden',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Öffne Beyond im Browser und füge ihn zur '
                    'Startseite hinzu. So hast du schnellen '
                    'Zugriff – ganz ohne App-Store.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Android-App',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Für das beste Erlebnis steht dir eine '
                    'native Android-App zum Download bereit.',
                    style: theme.textTheme.bodyMedium,
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

class _DonePage extends StatelessWidget {
  const _DonePage({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.celebration_rounded,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Alles fertig!',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Viel Spaß beim Erkunden!',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
