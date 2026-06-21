class OtpRequest {
  final String email;
  const OtpRequest({required this.email});

  Map<String, dynamic> toJson() => {'email': email};
}

class OtpVerifyRequest {
  final String? email;
  final String code;
  const OtpVerifyRequest({this.email, required this.code});

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'code': code};
    if (email != null) map['email'] = email;
    return map;
  }
}

class OtpSentResponse {
  final String message;
  const OtpSentResponse({required this.message});

  factory OtpSentResponse.fromJson(Map<String, dynamic> json) {
    return OtpSentResponse(message: json['message'] as String);
  }
}

class DiscordStartResponse {
  final String url;
  const DiscordStartResponse({required this.url});

  factory DiscordStartResponse.fromJson(Map<String, dynamic> json) {
    return DiscordStartResponse(url: json['url'] as String);
  }
}

class RefreshTokenResponse {
  final String refreshToken;
  final int expiresAt;
  const RefreshTokenResponse({
    required this.refreshToken,
    required this.expiresAt,
  });

  factory RefreshTokenResponse.fromJson(Map<String, dynamic> json) {
    return RefreshTokenResponse(
      refreshToken: json['refresh_token'] as String,
      expiresAt: json['expires_at'] as int,
    );
  }
}
