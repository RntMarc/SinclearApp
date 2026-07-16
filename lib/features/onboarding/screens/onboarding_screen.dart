import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/image/image_compressor.dart';
import '../../../core/network/api_client.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_avatar.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_chip.dart';
import '../../../design/widgets/composite/design_list_tile.dart';
import '../../../design/widgets/primitives/design_text_field.dart';
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
      final user = await AppScope.of(context).user.getMeBase();
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
    final source = await showDesignSheet<ImageSource>(
      context: context,
      child: Column(
        children: <Widget>[
          const DesignText(
            'Profilbild auswählen',
            style: DesignTextStyle.subtitle,
          ),
          const SizedBox(height: 8),
          DesignListTile(
            leading: const Icon(Icons.camera_alt_rounded),
            title: 'Foto aufnehmen',
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          DesignListTile(
            leading: const Icon(Icons.photo_library_rounded),
            title: 'Aus Galerie wählen',
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
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
      final displayName = _nameController.text.trim();
      final birthday = _birthdayController.text.trim();

      await scope.user.updateProfile(
        ProfileUpdateRequest(
          image: _imageBytes != null ? base64Encode(_imageBytes!) : null,
          displayName: displayName.isNotEmpty ? displayName : null,
          birthday: birthday.isNotEmpty ? birthday : null,
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
      setState(
        () => _error = e.message ?? 'Profil speichern fehlgeschlagen.',
      );
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
      setState(
        () => _error = 'Netzwerkfehler. Bitte prüfe deine Verbindung.',
      );
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
      setState(
        () => _error = e.message ?? 'Onboarding abschließen fehlgeschlagen.',
      );
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
      setState(
        () => _error = 'Netzwerkfehler. Bitte prüfe deine Verbindung.',
      );
      return;
    }

    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: DesignSurface(
          child: Center(
            child: CircularProgressIndicator(
              color: DesignTheme.of(context).primary,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: DesignSurface(
        child: SafeArea(
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
                    const _WelcomePage(),
                    _ConsentPage(
                      aiConsent: _aiConsent,
                      dataConsent: _dataConsent,
                      onAiChanged: (v) => setState(() => _aiConsent = v),
                      onDataChanged: (v) => setState(() => _dataConsent = v),
                    ),
                    _ProfilePage(
                      nameController: _nameController,
                      birthdayController: _birthdayController,
                      imageBytes: _imageBytes,
                      existingImageUrl: _existingImageUrl,
                      onPickImage: _pickImage,
                      onPickBirthday: _pickBirthday,
                    ),
                    const _SocialHintPage(),
                    const _PwaHintPage(),
                    const _DonePage(),
                  ],
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final tokens = DesignTheme.of(context);
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
              child: DesignText(
                _error!,
                style: DesignTextStyle.body,
                color: tokens.danger,
              ),
            ),
          Row(
            children: [
              if (!isFirst)
                DesignButton(
                  label: 'Zurück',
                  variant: DesignButtonVariant.text,
                  onPressed: _prevPage,
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
                        ? tokens.primary
                        : tokens.textLow.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const Spacer(),
              if (isLast)
                DesignButton(
                  label: 'Los geht\'s!',
                  loading: _saving,
                  onPressed: _saving ? null : _finish,
                )
              else
                DesignButton(
                  label: 'Weiter',
                  onPressed: _canProceed ? _nextPage : null,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.waving_hand_rounded,
              size: 72,
              color: tokens.primary,
            ),
            const SizedBox(height: 24),
            const DesignText(
              'Willkommen bei Beyond!',
              style: DesignTextStyle.display,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            DesignText(
              'Schön, dass du da bist. Lass uns in einigen Schritten '
              'dein Konto einrichten.',
              style: DesignTextStyle.body,
              color: tokens.textLow,
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
    required this.aiConsent,
    required this.dataConsent,
    required this.onAiChanged,
    required this.onDataChanged,
  });

  final bool aiConsent;
  final bool dataConsent;
  final ValueChanged<bool> onAiChanged;
  final ValueChanged<bool> onDataChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 48,
            color: tokens.primary,
          ),
          const SizedBox(height: 24),
          const DesignText(
            'Wichtige Hinweise',
            style: DesignTextStyle.title,
          ),
          const SizedBox(height: 24),
          DesignCard(
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.smart_toy_rounded, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: DesignText(
                        'Diese App wurde mit Künstlicher Intelligenz '
                        'erstellt. Es können Fehler und '
                        'Sicherheitslücken vorhanden sein.',
                        style: DesignTextStyle.body,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DesignListTile(
                  title: 'Ich habe zur Kenntnis genommen, dass die App '
                      'mit KI erstellt wurde.',
                  trailing: DesignChip(
                    label: aiConsent ? 'Bestätigt' : 'Bestätigen',
                    selected: aiConsent,
                    onTap: () => onAiChanged(!aiConsent),
                  ),
                  onTap: () => onAiChanged(!aiConsent),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          DesignCard(
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.shield_rounded, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: DesignText(
                        'Alle Angaben im Profil sind freiwillig. '
                        'Teile nur Informationen und Inhalte, '
                        'mit denen du dich wohlfühlst und der App, '
                        'der KI und Marc vertraust.',
                        style: DesignTextStyle.body,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DesignListTile(
                  title: 'Ich verstehe und stimme zu.',
                  trailing: DesignChip(
                    label: dataConsent ? 'Bestätigt' : 'Bestätigen',
                    selected: dataConsent,
                    onTap: () => onDataChanged(!dataConsent),
                  ),
                  onTap: () => onDataChanged(!dataConsent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage({
    required this.nameController,
    required this.birthdayController,
    required this.imageBytes,
    required this.existingImageUrl,
    required this.onPickImage,
    required this.onPickBirthday,
  });

  final TextEditingController nameController;
  final TextEditingController birthdayController;
  final Uint8List? imageBytes;
  final String? existingImageUrl;
  final VoidCallback onPickImage;
  final VoidCallback onPickBirthday;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    final String? avatarUrl;
    if (imageBytes != null) {
      avatarUrl = 'data:image/png;base64,${base64Encode(imageBytes!)}';
    } else if (existingImageUrl != null && existingImageUrl!.isNotEmpty) {
      avatarUrl = existingImageUrl;
    } else {
      avatarUrl = null;
    }

    final birthdayText = birthdayController.text.isNotEmpty
        ? birthdayController.text
        : 'Nicht angegeben';
    final birthdayMuted = birthdayController.text.isEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const DesignText(
            'Dein Profil',
            style: DesignTextStyle.title,
          ),
          const SizedBox(height: 8),
          DesignText(
            'Alles ist freiwillig. Du kannst dein Profil '
            'später jederzeit in den Einstellungen ändern.',
            style: DesignTextStyle.body,
            color: tokens.textLow,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: onPickImage,
            child: Stack(
              children: [
                DesignAvatar(
                  imageUrl: avatarUrl,
                  name: nameController.text,
                  size: 112,
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
                      size: 18,
                      color: tokens.textOnPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          DesignButton(
            label: avatarUrl != null
                ? 'Bild ändern'
                : 'Profilbild hinzufügen',
            variant: DesignButtonVariant.text,
            icon: Icons.edit_rounded,
            onPressed: onPickImage,
          ),
          const SizedBox(height: 24),
          DesignTextField(
            controller: nameController,
            hint: 'Anzeigename',
            prefixIcon: Icons.person_rounded,
          ),
          const SizedBox(height: 16),
          DesignListTile(
            leading: const Icon(Icons.cake_rounded),
            title: birthdayText,
            subtitle: birthdayMuted ? null : 'Geburtstag',
            trailing: const Icon(Icons.calendar_today_rounded),
            onTap: onPickBirthday,
          ),
        ],
      ),
    );
  }
}

class _SocialHintPage extends StatelessWidget {
  const _SocialHintPage();

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_rounded,
              size: 64,
              color: tokens.primary,
            ),
            const SizedBox(height: 24),
            const DesignText(
              'Social Media & Messenger',
              style: DesignTextStyle.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            DesignText(
              'Du kannst deine Social-Media-Profile und '
              'verwendeten Messenger später in den '
              'Einstellungen hinterlegen.',
              style: DesignTextStyle.body,
              color: tokens.textLow,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PwaHintPage extends StatelessWidget {
  const _PwaHintPage();

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.phone_android_rounded,
            size: 64,
            color: tokens.primary,
          ),
          const SizedBox(height: 24),
          const DesignText(
            'App-Installation',
            style: DesignTextStyle.title,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          DesignCard(
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DesignText(
                  'Als PWA verwenden',
                  style: DesignTextStyle.subtitle,
                ),
                const SizedBox(height: 8),
                DesignText(
                  'Öffne Beyond im Browser und füge ihn zur '
                  'Startseite hinzu. So hast du schnellen '
                  'Zugriff – ganz ohne App-Store.',
                  style: DesignTextStyle.body,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          DesignCard(
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DesignText(
                  'Android-App',
                  style: DesignTextStyle.subtitle,
                ),
                const SizedBox(height: 8),
                DesignText(
                  'Für das beste Erlebnis steht dir eine '
                  'native Android-App zum Download bereit.',
                  style: DesignTextStyle.body,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DonePage extends StatelessWidget {
  const _DonePage();

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.celebration_rounded,
              size: 72,
              color: tokens.primary,
            ),
            const SizedBox(height: 24),
            const DesignText(
              'Alles fertig!',
              style: DesignTextStyle.display,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            DesignText(
              'Viel Spaß beim Erkunden!',
              style: DesignTextStyle.body,
              color: tokens.textLow,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
