class UserPreferences {
  final String id;
  final String userId;
  final String? language;
  final String? theme;
  final String? primaryColor;
  final String? timezone;
  final int emailVisibility;
  final int birthdayVisibility;
  final bool syncAvatarFromDiscord;
  final bool onboardingCompleted;
  final int discordVisibility;
  final int fluxerVisibility;
  final int matrixVisibility;
  final int signalVisibility;
  final int whatsappVisibility;
  final int unsplashVisibility;
  final int instagramVisibility;
  final int mastodonVisibility;
  final int pixelfedVisibility;
  final int blueskyVisibility;
  final int youtubeVisibility;
  final int twitchVisibility;
  final String createdAt;
  final String updatedAt;

  const UserPreferences({
    required this.id,
    required this.userId,
    this.language,
    this.theme,
    this.primaryColor,
    this.timezone,
    this.emailVisibility = 1,
    this.birthdayVisibility = 1,
    this.syncAvatarFromDiscord = true,
    this.onboardingCompleted = false,
    this.discordVisibility = 1,
    this.fluxerVisibility = 1,
    this.matrixVisibility = 1,
    this.signalVisibility = 1,
    this.whatsappVisibility = 1,
    this.unsplashVisibility = 1,
    this.instagramVisibility = 1,
    this.mastodonVisibility = 1,
    this.pixelfedVisibility = 1,
    this.blueskyVisibility = 1,
    this.youtubeVisibility = 1,
    this.twitchVisibility = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      id: json['id'] as String,
      userId: json['userId'] as String,
      language: json['language'] as String?,
      theme: json['theme'] as String?,
      primaryColor: json['primaryColor'] as String?,
      timezone: json['timezone'] as String?,
      emailVisibility: (json['emailVisibility'] as num?)?.toInt() ?? 1,
      birthdayVisibility: (json['birthdayVisibility'] as num?)?.toInt() ?? 1,
      syncAvatarFromDiscord: json['syncAvatarFromDiscord'] as bool? ?? true,
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
      discordVisibility: (json['discordVisibility'] as num?)?.toInt() ?? 1,
      fluxerVisibility: (json['fluxerVisibility'] as num?)?.toInt() ?? 1,
      matrixVisibility: (json['matrixVisibility'] as num?)?.toInt() ?? 1,
      signalVisibility: (json['signalVisibility'] as num?)?.toInt() ?? 1,
      whatsappVisibility: (json['whatsappVisibility'] as num?)?.toInt() ?? 1,
      unsplashVisibility: (json['unsplashVisibility'] as num?)?.toInt() ?? 1,
      instagramVisibility: (json['instagramVisibility'] as num?)?.toInt() ?? 1,
      mastodonVisibility: (json['mastodonVisibility'] as num?)?.toInt() ?? 1,
      pixelfedVisibility: (json['pixelfedVisibility'] as num?)?.toInt() ?? 1,
      blueskyVisibility: (json['blueskyVisibility'] as num?)?.toInt() ?? 1,
      youtubeVisibility: (json['youtubeVisibility'] as num?)?.toInt() ?? 1,
      twitchVisibility: (json['twitchVisibility'] as num?)?.toInt() ?? 1,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    if (language != null) 'language': language,
    if (theme != null) 'theme': theme,
    if (primaryColor != null) 'primaryColor': primaryColor,
    if (timezone != null) 'timezone': timezone,
    if (emailVisibility != 1) 'emailVisibility': emailVisibility,
    if (birthdayVisibility != 1) 'birthdayVisibility': birthdayVisibility,
    if (syncAvatarFromDiscord != true)
      'syncAvatarFromDiscord': syncAvatarFromDiscord,
    if (onboardingCompleted != false)
      'onboardingCompleted': onboardingCompleted,
    if (discordVisibility != 1) 'discordVisibility': discordVisibility,
    if (fluxerVisibility != 1) 'fluxerVisibility': fluxerVisibility,
    if (matrixVisibility != 1) 'matrixVisibility': matrixVisibility,
    if (signalVisibility != 1) 'signalVisibility': signalVisibility,
    if (whatsappVisibility != 1) 'whatsappVisibility': whatsappVisibility,
    if (unsplashVisibility != 1) 'unsplashVisibility': unsplashVisibility,
    if (instagramVisibility != 1) 'instagramVisibility': instagramVisibility,
    if (mastodonVisibility != 1) 'mastodonVisibility': mastodonVisibility,
    if (pixelfedVisibility != 1) 'pixelfedVisibility': pixelfedVisibility,
    if (blueskyVisibility != 1) 'blueskyVisibility': blueskyVisibility,
    if (youtubeVisibility != 1) 'youtubeVisibility': youtubeVisibility,
    if (twitchVisibility != 1) 'twitchVisibility': twitchVisibility,
  };
}

class UserPreferencesResponse {
  final UserPreferences data;

  const UserPreferencesResponse({required this.data});

  factory UserPreferencesResponse.fromJson(Map<String, dynamic> json) {
    return UserPreferencesResponse(
      data: UserPreferences.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}
