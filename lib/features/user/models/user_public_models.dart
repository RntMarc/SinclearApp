class UserBasePublic {
  final String id;
  final String? email;
  final String displayName;
  final String? image;
  final String? discordId;
  final String? discordAvatarHash;
  final bool syncAvatarFromDiscord;
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
    this.discordAvatarHash,
    this.syncAvatarFromDiscord = true,
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
      discordAvatarHash: json['discordAvatarHash'] as String?,
      syncAvatarFromDiscord: _coerceBool(
        json['syncAvatarFromDiscord'],
        defaultValue: true,
      ),
      isAdmin: json['isAdmin'] as bool,
      createdAt: json['createdAt'] as String,
      onboardingCompleted: _coerceBool(
        json['onboardingCompleted'],
        defaultValue: false,
      ),
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
      if (unsplashHandle != null)
        SocialEntry(
          'Unsplash',
          unsplashHandle!,
          'https://unsplash.com/@$unsplashHandle',
        ),
      if (instagramHandle != null)
        SocialEntry(
          'Instagram',
          instagramHandle!,
          'https://instagram.com/$instagramHandle',
        ),
      if (mastodonUser != null && mastodonServer != null)
        SocialEntry(
          'Mastodon',
          '@$mastodonUser@$mastodonServer',
          'https://$mastodonServer/@$mastodonUser',
        ),
      if (pixelfedUser != null && pixelfedServer != null)
        SocialEntry(
          'Pixelfed',
          '@$pixelfedUser@$pixelfedServer',
          'https://$pixelfedServer/$pixelfedUser',
        ),
      if (blueskyHandle != null)
        SocialEntry(
          'Bluesky',
          blueskyHandle!,
          'https://bsky.app/profile/$blueskyHandle',
        ),
      if (youtubeHandle != null)
        SocialEntry(
          'YouTube',
          youtubeHandle!,
          'https://youtube.com/@$youtubeHandle',
        ),
      if (twitchHandle != null)
        SocialEntry('Twitch', twitchHandle!, 'https://twitch.tv/$twitchHandle'),
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
          ? UserSocialInfoPublic.fromJson(
              json['social'] as Map<String, dynamic>,
            )
          : const UserSocialInfoPublic(),
      contact: json['contact'] != null
          ? UserContactInfoPublic.fromJson(
              json['contact'] as Map<String, dynamic>,
            )
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

/// Coerces the API's boolean-like values (which may arrive as `bool` or as
/// `int` `1`/`0`) into a Dart `bool`.
bool _coerceBool(Object? value, {required bool defaultValue}) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is num) return value != 0;
  return defaultValue;
}
