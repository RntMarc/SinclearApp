class UserBasePublic {
  final String id;
  final String? email;
  final String displayName;
  final String? image;
  final String? discordId;
  final bool isAdmin;
  final String createdAt;
  final bool onboardingCompleted;
  final String? birthday;

  const UserBasePublic({
    required this.id,
    this.email,
    required this.displayName,
    this.image,
    this.discordId,
    required this.isAdmin,
    required this.createdAt,
    required this.onboardingCompleted,
    this.birthday,
  });

  factory UserBasePublic.fromJson(Map<String, dynamic> json) {
    return UserBasePublic(
      id: json['id'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String,
      image: json['image'] as String?,
      discordId: json['discordId'] as String?,
      isAdmin: json['isAdmin'] as bool,
      createdAt: json['createdAt'] as String,
      onboardingCompleted: json['onboardingCompleted'] as bool,
      birthday: json['birthday'] as String?,
    );
  }
}

class UserSocialInfoPublic {
  final String? unsplashHandle;
  final String? instagramHandle;
  final String? mastodonUser;
  final String? mastodonServer;
  final String? pixelfedUser;
  final String? pixelfedServer;
  final String? blueskyHandle;
  final String? youtubeHandle;
  final String? twitchHandle;

  const UserSocialInfoPublic({
    this.unsplashHandle,
    this.instagramHandle,
    this.mastodonUser,
    this.mastodonServer,
    this.pixelfedUser,
    this.pixelfedServer,
    this.blueskyHandle,
    this.youtubeHandle,
    this.twitchHandle,
  });

  factory UserSocialInfoPublic.fromJson(Map<String, dynamic> json) {
    return UserSocialInfoPublic(
      unsplashHandle: json['unsplashHandle'] as String?,
      instagramHandle: json['instagramHandle'] as String?,
      mastodonUser: json['mastodonUser'] as String?,
      mastodonServer: json['mastodonServer'] as String?,
      pixelfedUser: json['pixelfedUser'] as String?,
      pixelfedServer: json['pixelfedServer'] as String?,
      blueskyHandle: json['blueskyHandle'] as String?,
      youtubeHandle: json['youtubeHandle'] as String?,
      twitchHandle: json['twitchHandle'] as String?,
    );
  }

  List<SocialEntry> toList() {
    return [
      if (unsplashHandle != null) SocialEntry('Unsplash', unsplashHandle!, 'https://unsplash.com/@$unsplashHandle'),
      if (instagramHandle != null) SocialEntry('Instagram', instagramHandle!, 'https://instagram.com/$instagramHandle'),
      if (mastodonUser != null && mastodonServer != null) SocialEntry('Mastodon', '@$mastodonUser@$mastodonServer', 'https://$mastodonServer/@$mastodonUser'),
      if (pixelfedUser != null && pixelfedServer != null) SocialEntry('Pixelfed', '@$pixelfedUser@$pixelfedServer', 'https://$pixelfedServer/$pixelfedUser'),
      if (blueskyHandle != null) SocialEntry('Bluesky', blueskyHandle!, 'https://bsky.app/profile/$blueskyHandle'),
      if (youtubeHandle != null) SocialEntry('YouTube', youtubeHandle!, 'https://youtube.com/@$youtubeHandle'),
      if (twitchHandle != null) SocialEntry('Twitch', twitchHandle!, 'https://twitch.tv/$twitchHandle'),
    ];
  }
}

class SocialEntry {
  final String platform;
  final String handle;
  final String? url;
  const SocialEntry(this.platform, this.handle, this.url);
}

class UserContactInfoPublic {
  final String? discordHandle;
  final String? fluxerHandle;
  final String? signalNumber;
  final String? whatsappNumber;
  final String? matrixUser;
  final String? matrixHomeserver;

  const UserContactInfoPublic({
    this.discordHandle,
    this.fluxerHandle,
    this.signalNumber,
    this.whatsappNumber,
    this.matrixUser,
    this.matrixHomeserver,
  });

  factory UserContactInfoPublic.fromJson(Map<String, dynamic> json) {
    return UserContactInfoPublic(
      discordHandle: json['discordHandle'] as String?,
      fluxerHandle: json['fluxerHandle'] as String?,
      signalNumber: json['signalNumber'] as String?,
      whatsappNumber: json['whatsappNumber'] as String?,
      matrixUser: json['matrixUser'] as String?,
      matrixHomeserver: json['matrixHomeserver'] as String?,
    );
  }
}

class UserDetailPublic {
  final UserBasePublic base;
  final UserSocialInfoPublic social;
  final UserContactInfoPublic contact;

  const UserDetailPublic({
    required this.base,
    this.social = const UserSocialInfoPublic(),
    this.contact = const UserContactInfoPublic(),
  });

  factory UserDetailPublic.fromJson(Map<String, dynamic> json) {
    return UserDetailPublic(
      base: UserBasePublic.fromJson(json),
      social: json['social'] != null
          ? UserSocialInfoPublic.fromJson(json['social'] as Map<String, dynamic>)
          : const UserSocialInfoPublic(),
      contact: json['contact'] != null
          ? UserContactInfoPublic.fromJson(json['contact'] as Map<String, dynamic>)
          : const UserContactInfoPublic(),
    );
  }
}

class UserListResponse {
  final List<UserBasePublic> data;

  const UserListResponse({required this.data});

  factory UserListResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['data'] as List)
        .map((e) => UserBasePublic.fromJson(e as Map<String, dynamic>))
        .toList();
    return UserListResponse(data: list);
  }
}

class UserDetailPublicResponse {
  final UserDetailPublic data;

  const UserDetailPublicResponse({required this.data});

  factory UserDetailPublicResponse.fromJson(Map<String, dynamic> json) {
    return UserDetailPublicResponse(
      data: UserDetailPublic.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

// ─── Private (own profile) models ────────────────────────────────────────

class UserBase {
  final String id;
  final String email;
  final int emailVisibility;
  final String displayName;
  final String? image;
  final String? discordId;
  final bool isAdmin;
  final String createdAt;
  final bool onboardingCompleted;
  final String? birthday;
  final int birthdayVisibility;

  const UserBase({
    required this.id,
    required this.email,
    required this.emailVisibility,
    required this.displayName,
    this.image,
    this.discordId,
    required this.isAdmin,
    required this.createdAt,
    required this.onboardingCompleted,
    this.birthday,
    required this.birthdayVisibility,
  });

  factory UserBase.fromJson(Map<String, dynamic> json) {
    return UserBase(
      id: json['id'] as String,
      email: json['email'] as String,
      emailVisibility: (json['emailVisibility'] as num).toInt(),
      displayName: json['displayName'] as String,
      image: json['image'] as String?,
      discordId: json['discordId'] as String?,
      isAdmin: json['isAdmin'] as bool,
      createdAt: json['createdAt'] as String,
      onboardingCompleted: json['onboardingCompleted'] as bool,
      birthday: json['birthday'] as String?,
      birthdayVisibility: (json['birthdayVisibility'] as num).toInt(),
    );
  }
}

class UserSocialInfo {
  final String? unsplashHandle;
  final int unsplashVisibility;
  final String? instagramHandle;
  final int instagramVisibility;
  final String? mastodonUser;
  final String? mastodonServer;
  final int mastodonVisibility;
  final String? pixelfedUser;
  final String? pixelfedServer;
  final int pixelfedVisibility;
  final String? blueskyHandle;
  final int blueskyVisibility;
  final String? youtubeHandle;
  final int youtubeVisibility;
  final String? twitchHandle;
  final int twitchVisibility;

  const UserSocialInfo({
    this.unsplashHandle,
    this.unsplashVisibility = 1,
    this.instagramHandle,
    this.instagramVisibility = 1,
    this.mastodonUser,
    this.mastodonServer,
    this.mastodonVisibility = 1,
    this.pixelfedUser,
    this.pixelfedServer,
    this.pixelfedVisibility = 1,
    this.blueskyHandle,
    this.blueskyVisibility = 1,
    this.youtubeHandle,
    this.youtubeVisibility = 1,
    this.twitchHandle,
    this.twitchVisibility = 1,
  });

  factory UserSocialInfo.fromJson(Map<String, dynamic> json) {
    return UserSocialInfo(
      unsplashHandle: json['unsplashHandle'] as String?,
      unsplashVisibility: (json['unsplashVisibility'] as num?)?.toInt() ?? 1,
      instagramHandle: json['instagramHandle'] as String?,
      instagramVisibility: (json['instagramVisibility'] as num?)?.toInt() ?? 1,
      mastodonUser: json['mastodonUser'] as String?,
      mastodonServer: json['mastodonServer'] as String?,
      mastodonVisibility: (json['mastodonVisibility'] as num?)?.toInt() ?? 1,
      pixelfedUser: json['pixelfedUser'] as String?,
      pixelfedServer: json['pixelfedServer'] as String?,
      pixelfedVisibility: (json['pixelfedVisibility'] as num?)?.toInt() ?? 1,
      blueskyHandle: json['blueskyHandle'] as String?,
      blueskyVisibility: (json['blueskyVisibility'] as num?)?.toInt() ?? 1,
      youtubeHandle: json['youtubeHandle'] as String?,
      youtubeVisibility: (json['youtubeVisibility'] as num?)?.toInt() ?? 1,
      twitchHandle: json['twitchHandle'] as String?,
      twitchVisibility: (json['twitchVisibility'] as num?)?.toInt() ?? 1,
    );
  }
}

class UserContactInfo {
  final String? discordHandle;
  final int discordVisibility;
  final String? fluxerHandle;
  final int fluxerVisibility;
  final String? signalNumber;
  final int signalVisibility;
  final String? whatsappNumber;
  final int whatsappVisibility;
  final String? matrixUser;
  final String? matrixHomeserver;
  final int matrixVisibility;

  const UserContactInfo({
    this.discordHandle,
    this.discordVisibility = 1,
    this.fluxerHandle,
    this.fluxerVisibility = 1,
    this.signalNumber,
    this.signalVisibility = 1,
    this.whatsappNumber,
    this.whatsappVisibility = 1,
    this.matrixUser,
    this.matrixHomeserver,
    this.matrixVisibility = 1,
  });

  factory UserContactInfo.fromJson(Map<String, dynamic> json) {
    return UserContactInfo(
      discordHandle: json['discordHandle'] as String?,
      discordVisibility: (json['discordVisibility'] as num?)?.toInt() ?? 1,
      fluxerHandle: json['fluxerHandle'] as String?,
      fluxerVisibility: (json['fluxerVisibility'] as num?)?.toInt() ?? 1,
      signalNumber: json['signalNumber'] as String?,
      signalVisibility: (json['signalVisibility'] as num?)?.toInt() ?? 1,
      whatsappNumber: json['whatsappNumber'] as String?,
      whatsappVisibility: (json['whatsappVisibility'] as num?)?.toInt() ?? 1,
      matrixUser: json['matrixUser'] as String?,
      matrixHomeserver: json['matrixHomeserver'] as String?,
      matrixVisibility: (json['matrixVisibility'] as num?)?.toInt() ?? 1,
    );
  }
}

class UserMe {
  final UserBase base;
  final UserSocialInfo social;
  final UserContactInfo contact;

  const UserMe({
    required this.base,
    this.social = const UserSocialInfo(),
    this.contact = const UserContactInfo(),
  });

  factory UserMe.fromJson(Map<String, dynamic> json) {
    return UserMe(
      base: UserBase.fromJson(json),
      social: json['social'] != null
          ? UserSocialInfo.fromJson(json['social'] as Map<String, dynamic>)
          : const UserSocialInfo(),
      contact: json['contact'] != null
          ? UserContactInfo.fromJson(json['contact'] as Map<String, dynamic>)
          : const UserContactInfo(),
    );
  }
}

// ─── Request models ─────────────────────────────────────────────────────

class ProfileUpdateRequest {
  final String? displayName;
  final String? birthday;
  final String? discordHandle;
  final String? fluxerHandle;
  final String? signalNumber;
  final String? whatsappNumber;
  final String? matrixUser;
  final String? matrixHomeserver;
  final String? unsplashHandle;
  final String? instagramHandle;
  final String? mastodonUser;
  final String? mastodonServer;
  final String? pixelfedUser;
  final String? pixelfedServer;
  final String? blueskyHandle;
  final String? youtubeHandle;
  final String? twitchHandle;

  const ProfileUpdateRequest({
    this.displayName,
    this.birthday,
    this.discordHandle,
    this.fluxerHandle,
    this.signalNumber,
    this.whatsappNumber,
    this.matrixUser,
    this.matrixHomeserver,
    this.unsplashHandle,
    this.instagramHandle,
    this.mastodonUser,
    this.mastodonServer,
    this.pixelfedUser,
    this.pixelfedServer,
    this.blueskyHandle,
    this.youtubeHandle,
    this.twitchHandle,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (displayName != null) map['displayName'] = displayName;
    if (birthday != null) map['birthday'] = birthday;
    if (discordHandle != null) map['discordHandle'] = discordHandle;
    if (fluxerHandle != null) map['fluxerHandle'] = fluxerHandle;
    if (signalNumber != null) map['signalNumber'] = signalNumber;
    if (whatsappNumber != null) map['whatsappNumber'] = whatsappNumber;
    if (matrixUser != null) map['matrixUser'] = matrixUser;
    if (matrixHomeserver != null) map['matrixHomeserver'] = matrixHomeserver;
    if (unsplashHandle != null) map['unsplashHandle'] = unsplashHandle;
    if (instagramHandle != null) map['instagramHandle'] = instagramHandle;
    if (mastodonUser != null) map['mastodonUser'] = mastodonUser;
    if (mastodonServer != null) map['mastodonServer'] = mastodonServer;
    if (pixelfedUser != null) map['pixelfedUser'] = pixelfedUser;
    if (pixelfedServer != null) map['pixelfedServer'] = pixelfedServer;
    if (blueskyHandle != null) map['blueskyHandle'] = blueskyHandle;
    if (youtubeHandle != null) map['youtubeHandle'] = youtubeHandle;
    if (twitchHandle != null) map['twitchHandle'] = twitchHandle;
    return map;
  }
}

class VisibilityUpdateRequest {
  final int? emailVisibility;
  final int? birthdayVisibility;
  final int? discordVisibility;
  final int? fluxerVisibility;
  final int? matrixVisibility;
  final int? signalVisibility;
  final int? whatsappVisibility;
  final int? unsplashVisibility;
  final int? instagramVisibility;
  final int? mastodonVisibility;
  final int? pixelfedVisibility;
  final int? blueskyVisibility;
  final int? youtubeVisibility;
  final int? twitchVisibility;

  const VisibilityUpdateRequest({
    this.emailVisibility,
    this.birthdayVisibility,
    this.discordVisibility,
    this.fluxerVisibility,
    this.matrixVisibility,
    this.signalVisibility,
    this.whatsappVisibility,
    this.unsplashVisibility,
    this.instagramVisibility,
    this.mastodonVisibility,
    this.pixelfedVisibility,
    this.blueskyVisibility,
    this.youtubeVisibility,
    this.twitchVisibility,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (emailVisibility != null) map['emailVisibility'] = emailVisibility;
    if (birthdayVisibility != null) map['birthdayVisibility'] = birthdayVisibility;
    if (discordVisibility != null) map['discordVisibility'] = discordVisibility;
    if (fluxerVisibility != null) map['fluxerVisibility'] = fluxerVisibility;
    if (matrixVisibility != null) map['matrixVisibility'] = matrixVisibility;
    if (signalVisibility != null) map['signalVisibility'] = signalVisibility;
    if (whatsappVisibility != null) map['whatsappVisibility'] = whatsappVisibility;
    if (unsplashVisibility != null) map['unsplashVisibility'] = unsplashVisibility;
    if (instagramVisibility != null) map['instagramVisibility'] = instagramVisibility;
    if (mastodonVisibility != null) map['mastodonVisibility'] = mastodonVisibility;
    if (pixelfedVisibility != null) map['pixelfedVisibility'] = pixelfedVisibility;
    if (blueskyVisibility != null) map['blueskyVisibility'] = blueskyVisibility;
    if (youtubeVisibility != null) map['youtubeVisibility'] = youtubeVisibility;
    if (twitchVisibility != null) map['twitchVisibility'] = twitchVisibility;
    return map;
  }
}

class EmailChangeRequest {
  final String newEmail;

  const EmailChangeRequest({required this.newEmail});

  Map<String, dynamic> toJson() => {'newEmail': newEmail};
}

class EmailChangeVerifyRequest {
  final String code;
  final String newEmail;

  const EmailChangeVerifyRequest({required this.code, required this.newEmail});

  Map<String, dynamic> toJson() => {'code': code, 'newEmail': newEmail};
}

class DiscordVerifyRequest {
  final String code;

  const DiscordVerifyRequest({required this.code});

  Map<String, dynamic> toJson() => {'code': code};
}

class MessageResponse {
  final String message;

  const MessageResponse({required this.message});

  factory MessageResponse.fromJson(Map<String, dynamic> json) {
    return MessageResponse(message: json['message'] as String);
  }
}
