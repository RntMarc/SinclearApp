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
      social: json['social'] is Map<String, dynamic>
          ? UserSocialInfo.fromJson(json['social'] as Map<String, dynamic>)
          : const UserSocialInfo(),
      contact: json['contact'] is Map<String, dynamic>
          ? UserContactInfo.fromJson(json['contact'] as Map<String, dynamic>)
          : const UserContactInfo(),
    );
  }
}
