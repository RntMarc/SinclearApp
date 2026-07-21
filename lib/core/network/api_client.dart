import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String errorCode;
  final String? message;
  final int statusCode;
  final int? responseSize;
  final String? responsePreview;

  const ApiException({
    required this.errorCode,
    this.message,
    required this.statusCode,
    this.responseSize,
    this.responsePreview,
  });

  @override
  String toString() {
    final parts = ['ApiException($statusCode): $errorCode'];
    if (message != null) parts.add('message=$message');
    if (responseSize != null) parts.add('size=${responseSize}B');
    if (responsePreview != null) parts.add('preview=$responsePreview');
    return parts.join(' | ');
  }
}

class ApiClient {
  final String baseUrl;
  final http.Client _client;
  final Duration timeout;
  final int maxGetAttempts;

  ApiClient({
    required this.baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 30),
    this.maxGetAttempts = 3,
  }) : _client = client ?? http.Client();

  Map<String, String> _headers({String? token}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    if (kDebugMode) {
      debugPrint(
        '[api_client] POST $uri body=${body != null ? _truncateJson(body) : 'null'}',
      );
    }
    for (var attempt = 1; attempt <= maxGetAttempts; attempt++) {
      try {
        final response = await _client
            .post(
              uri,
              headers: _headers(token: token),
              body: body != null ? jsonEncode(body) : null,
            )
            .timeout(timeout);
        if (kDebugMode) {
          _logResponse('POST', response);
        }
        if (!_shouldRetry(response.statusCode) || attempt == maxGetAttempts) {
          return _handleResponse(response);
        }
      } on TimeoutException {
        if (kDebugMode) {
          debugPrint(
            '[api_client] POST $uri timed out (attempt $attempt/$maxGetAttempts)',
          );
        }
        if (attempt == maxGetAttempts) rethrow;
      } on http.ClientException {
        if (kDebugMode) {
          debugPrint(
            '[api_client] POST $uri client error (attempt $attempt/$maxGetAttempts)',
          );
        }
        if (attempt == maxGetAttempts) rethrow;
      }
      await Future<void>.delayed(Duration(milliseconds: 250 * attempt));
    }
    throw StateError('POST retry loop exited unexpectedly.');
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
    String? token,
  }) async {
    var uri = Uri.parse('$baseUrl$path');
    if (queryParams != null) {
      uri = uri.replace(queryParameters: queryParams);
    }
    if (kDebugMode) {
      debugPrint('[api_client] GET $uri');
    }
    for (var attempt = 1; attempt <= maxGetAttempts; attempt++) {
      try {
        final response = await _client
            .get(uri, headers: _headers(token: token))
            .timeout(timeout);
        if (kDebugMode) {
          _logResponse('GET', response);
        }
        if (!_shouldRetry(response.statusCode) || attempt == maxGetAttempts) {
          return _handleResponse(response);
        }
      } on TimeoutException {
        if (kDebugMode) {
          debugPrint(
            '[api_client] GET $uri timed out (attempt $attempt/$maxGetAttempts)',
          );
        }
        if (attempt == maxGetAttempts) rethrow;
      } on http.ClientException {
        if (kDebugMode) {
          debugPrint(
            '[api_client] GET $uri client error (attempt $attempt/$maxGetAttempts)',
          );
        }
        if (attempt == maxGetAttempts) rethrow;
      }

      await Future<void>.delayed(Duration(milliseconds: 250 * attempt));
    }

    throw StateError('GET retry loop exited unexpectedly.');
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    if (kDebugMode) {
      final bodyPreview = body != null ? _truncateJson(body) : 'null';
      debugPrint('[api_client] PUT $uri body=$bodyPreview');
    }
    final encodedBody = body != null ? jsonEncode(body) : null;
    final response = await _client
        .put(
          uri,
          headers: _headers(token: token),
          body: encodedBody,
        )
        .timeout(timeout);
    if (kDebugMode) {
      debugPrint(
        '[api_client] PUT response status=${response.statusCode} body=${response.body.length > 500 ? '${response.body.substring(0, 500)}...' : response.body}',
      );
    }
    return _handleResponse(response);
  }

  String _truncateJson(Map<String, dynamic> json) {
    final buffer = StringBuffer('{');
    var first = true;
    for (final entry in json.entries) {
      if (!first) buffer.write(', ');
      first = false;
      buffer.write('"${entry.key}": ');
      if (entry.key == 'image' && entry.value is String) {
        final str = entry.value as String;
        final preview = str.length > 80 ? '${str.substring(0, 80)}...' : str;
        buffer.write('"<base64: len=${str.length}, preview=$preview>"');
      } else {
        buffer.write(entry.value.toString());
      }
    }
    buffer.write('}');
    return buffer.toString();
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    if (kDebugMode) {
      final bodyPreview = body != null ? _truncateJson(body) : 'null';
      debugPrint('[api_client] PATCH $uri body=$bodyPreview');
    }
    final encodedBody = body != null ? jsonEncode(body) : null;
    final response = await _client
        .send(
          http.Request('PATCH', uri)
            ..headers.addAll(_headers(token: token))
            ..body = encodedBody ?? '',
        )
        .timeout(timeout);
    final httpResponse = await http.Response.fromStream(response);
    if (kDebugMode) {
      debugPrint(
        '[api_client] PATCH response status=${httpResponse.statusCode}',
      );
    }
    return _handleResponse(httpResponse);
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? body,
    String? token,
    bool parseResponse = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    if (kDebugMode) {
      debugPrint('[api_client] DELETE $uri');
    }
    for (var attempt = 1; attempt <= maxGetAttempts; attempt++) {
      try {
        final request = http.Request('DELETE', uri);
        request.headers.addAll(_headers(token: token));
        if (body != null) {
          request.body = jsonEncode(body);
        }
        final streamed = await _client.send(request).timeout(timeout);
        final response = await http.Response.fromStream(streamed);
        if (kDebugMode) {
          _logResponse('DELETE', response);
        }
        if (response.statusCode == 204) return <String, dynamic>{};
        if (!_shouldRetry(response.statusCode) || attempt == maxGetAttempts) {
          return _handleResponse(response);
        }
      } on TimeoutException {
        if (kDebugMode) {
          debugPrint(
            '[api_client] DELETE $uri timed out (attempt $attempt/$maxGetAttempts)',
          );
        }
        if (attempt == maxGetAttempts) rethrow;
      } on http.ClientException {
        if (kDebugMode) {
          debugPrint(
            '[api_client] DELETE $uri client error (attempt $attempt/$maxGetAttempts)',
          );
        }
        if (attempt == maxGetAttempts) rethrow;
      }
      await Future<void>.delayed(Duration(milliseconds: 250 * attempt));
    }
    throw StateError('DELETE retry loop exited unexpectedly.');
  }

  void _logResponse(String method, http.Response response) {
    final bodyPreview = response.body.length > 500
        ? '${response.body.substring(0, 500)}...'
        : response.body;
    debugPrint('[api_client] $method ${response.statusCode} body=$bodyPreview');
  }

  bool _shouldRetry(int statusCode) {
    return statusCode == 408 || statusCode == 429 || statusCode >= 500;
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw ApiException(
      errorCode: body['error'] as String? ?? 'unknown_error',
      message: body['message'] as String?,
      statusCode: response.statusCode,
      responseSize: response.bodyBytes.length,
      responsePreview: response.body.length > 500
          ? '${response.body.substring(0, 500)}...'
          : response.body,
    );
  }

  void dispose() {
    _client.close();
  }
}
