class ProfileUpdateRequest {
  final String? image;
  final bool removeImage;
  final String? displayName;
  final String? birthday;
  final bool removeBirthday;
  final String? discordHandle;
  final bool removeDiscordHandle;
  final String? fluxerHandle;
  final bool removeFluxerHandle;
  final String? signalNumber;
  final bool removeSignalNumber;
  final String? whatsappNumber;
  final bool removeWhatsappNumber;
  final String? matrixUser;
  final bool removeMatrixUser;
  final String? matrixHomeserver;
  final bool removeMatrixHomeserver;
  final String? unsplashHandle;
  final bool removeUnsplashHandle;
  final String? instagramHandle;
  final bool removeInstagramHandle;
  final String? mastodonUser;
  final bool removeMastodonUser;
  final String? mastodonServer;
  final bool removeMastodonServer;
  final String? pixelfedUser;
  final bool removePixelfedUser;
  final String? pixelfedServer;
  final bool removePixelfedServer;
  final String? blueskyHandle;
  final bool removeBlueskyHandle;
  final String? youtubeHandle;
  final bool removeYoutubeHandle;
  final String? twitchHandle;
  final bool removeTwitchHandle;

  const ProfileUpdateRequest({
    this.image,
    this.removeImage = false,
    this.displayName,
    this.birthday,
    this.removeBirthday = false,
    this.discordHandle,
    this.removeDiscordHandle = false,
    this.fluxerHandle,
    this.removeFluxerHandle = false,
    this.signalNumber,
    this.removeSignalNumber = false,
    this.whatsappNumber,
    this.removeWhatsappNumber = false,
    this.matrixUser,
    this.removeMatrixUser = false,
    this.matrixHomeserver,
    this.removeMatrixHomeserver = false,
    this.unsplashHandle,
    this.removeUnsplashHandle = false,
    this.instagramHandle,
    this.removeInstagramHandle = false,
    this.mastodonUser,
    this.removeMastodonUser = false,
    this.mastodonServer,
    this.removeMastodonServer = false,
    this.pixelfedUser,
    this.removePixelfedUser = false,
    this.pixelfedServer,
    this.removePixelfedServer = false,
    this.blueskyHandle,
    this.removeBlueskyHandle = false,
    this.youtubeHandle,
    this.removeYoutubeHandle = false,
    this.twitchHandle,
    this.removeTwitchHandle = false,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    _apply(map, 'image', image, removeImage);
    if (displayName != null) map['displayName'] = displayName;
    _apply(map, 'birthday', birthday, removeBirthday);
    _apply(map, 'discordHandle', discordHandle, removeDiscordHandle);
    _apply(map, 'fluxerHandle', fluxerHandle, removeFluxerHandle);
    _apply(map, 'signalNumber', signalNumber, removeSignalNumber);
    _apply(map, 'whatsappNumber', whatsappNumber, removeWhatsappNumber);
    _apply(map, 'matrixUser', matrixUser, removeMatrixUser);
    _apply(map, 'matrixHomeserver', matrixHomeserver, removeMatrixHomeserver);
    _apply(map, 'unsplashHandle', unsplashHandle, removeUnsplashHandle);
    _apply(map, 'instagramHandle', instagramHandle, removeInstagramHandle);
    _apply(map, 'mastodonUser', mastodonUser, removeMastodonUser);
    _apply(map, 'mastodonServer', mastodonServer, removeMastodonServer);
    _apply(map, 'pixelfedUser', pixelfedUser, removePixelfedUser);
    _apply(map, 'pixelfedServer', pixelfedServer, removePixelfedServer);
    _apply(map, 'blueskyHandle', blueskyHandle, removeBlueskyHandle);
    _apply(map, 'youtubeHandle', youtubeHandle, removeYoutubeHandle);
    _apply(map, 'twitchHandle', twitchHandle, removeTwitchHandle);
    return map;
  }

  void _apply(Map<String, dynamic> map, String key, String? val, bool remove) {
    if (remove) {
      map[key] = null;
    } else if (val != null) {
      map[key] = val;
    }
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
    if (birthdayVisibility != null) {
      map['birthdayVisibility'] = birthdayVisibility;
    }
    if (discordVisibility != null) {
      map['discordVisibility'] = discordVisibility;
    }
    if (fluxerVisibility != null) {
      map['fluxerVisibility'] = fluxerVisibility;
    }
    if (matrixVisibility != null) {
      map['matrixVisibility'] = matrixVisibility;
    }
    if (signalVisibility != null) {
      map['signalVisibility'] = signalVisibility;
    }
    if (whatsappVisibility != null) {
      map['whatsappVisibility'] = whatsappVisibility;
    }
    if (unsplashVisibility != null) {
      map['unsplashVisibility'] = unsplashVisibility;
    }
    if (instagramVisibility != null) {
      map['instagramVisibility'] = instagramVisibility;
    }
    if (mastodonVisibility != null) {
      map['mastodonVisibility'] = mastodonVisibility;
    }
    if (pixelfedVisibility != null) {
      map['pixelfedVisibility'] = pixelfedVisibility;
    }
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
