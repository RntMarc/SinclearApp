import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_avatar.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_chip.dart';
import '../../../design/widgets/composite/design_list_tile.dart';
import '../../../design/widgets/primitives/design_text_field.dart';

class OnboardingWelcomePage extends StatelessWidget {
  const OnboardingWelcomePage({super.key});

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

class OnboardingConsentPage extends StatelessWidget {
  const OnboardingConsentPage({
    super.key,
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

class OnboardingProfilePage extends StatelessWidget {
  const OnboardingProfilePage({
    super.key,
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

class OnboardingSocialHintPage extends StatelessWidget {
  const OnboardingSocialHintPage({super.key});

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

class OnboardingPwaHintPage extends StatelessWidget {
  const OnboardingPwaHintPage({super.key});

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

class OnboardingDonePage extends StatelessWidget {
  const OnboardingDonePage({super.key});

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
