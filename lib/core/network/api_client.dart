import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

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

/// Beschreibt einen beim API-Zugriff aufgetretenen Fehler für die UI.
///
/// Im Gegensatz zu einer pauschalen Meldung nennt sie bei [ApiException] den
/// HTTP-Status und den Fehlercode (z. B. `rate_limit_exceeded`), damit
/// auffällt, was tatsächlich fehlschlägt. Netzwerk- und Timeout-Fehler haben
/// eigene, verständliche Texte.
String describeApiError(
  Object error, {
  String fallback = 'Die Anfrage ist fehlgeschlagen.',
}) {
  if (error is ApiException) {
    final code = error.errorCode;
    final detail = error.message?.isNotEmpty == true
        ? ' — ${error.message}'
        : '';
    return 'Fehler ${error.statusCode} ($code)$detail';
  }
  if (error is TimeoutException) {
    return 'Zeitüberschreitung: Der Server hat nicht rechtzeitig geantwortet.';
  }
  if (error is http.ClientException) {
    return 'Netzwerkfehler: ${error.message}';
  }
  return fallback;
}

class ApiClient {
  final String baseUrl;
  final http.Client _client;
  final Duration timeout;
  final int maxGetAttempts;
  final Logger _log = Logger('api_client');

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
      _log.fine(
        'POST $uri body=${body != null ? _truncateJson(body) : 'null'}',
      );
    }
    for (var attempt = 1; attempt <= maxGetAttempts; attempt++) {
      http.Response? retryResponse;
      try {
        final response = await _client
            .post(
              uri,
              headers: _headers(token: token),
              body: body != null ? jsonEncode(body) : null,
            )
            .timeout(timeout);
        if (kDebugMode) {
          _logResponse('POST', uri.toString(), response);
        }
        if (!_shouldRetry('POST', response.statusCode, path) ||
            attempt == maxGetAttempts) {
          return _handleResponse(response);
        }
        retryResponse = response;
      } on TimeoutException {
        if (kDebugMode) {
          _log.fine('POST $uri timed out (attempt $attempt/$maxGetAttempts)');
        }
        if (attempt == maxGetAttempts) rethrow;
      } on http.ClientException {
        if (kDebugMode) {
          _log.fine(
            'POST $uri client error (attempt $attempt/$maxGetAttempts)',
          );
        }
        if (attempt == maxGetAttempts) rethrow;
      }
      await Future<void>.delayed(_retryDelay(retryResponse, attempt));
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
      _log.fine('GET $uri');
    }
    for (var attempt = 1; attempt <= maxGetAttempts; attempt++) {
      http.Response? retryResponse;
      try {
        final response = await _client
            .get(uri, headers: _headers(token: token))
            .timeout(timeout);
        if (kDebugMode) {
          _logResponse('GET', uri.toString(), response);
        }
        if (!_shouldRetry('GET', response.statusCode, path) ||
            attempt == maxGetAttempts) {
          return _handleResponse(response);
        }
        retryResponse = response;
      } on TimeoutException {
        if (kDebugMode) {
          _log.fine('GET $uri timed out (attempt $attempt/$maxGetAttempts)');
        }
        if (attempt == maxGetAttempts) rethrow;
      } on http.ClientException {
        if (kDebugMode) {
          _log.fine('GET $uri client error (attempt $attempt/$maxGetAttempts)');
        }
        if (attempt == maxGetAttempts) rethrow;
      }

      await Future<void>.delayed(_retryDelay(retryResponse, attempt));
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
      _log.fine('PUT $uri body=$bodyPreview');
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
      _log.fine(
        'PUT response status=${response.statusCode} body=${response.body.length > 500 ? '${response.body.substring(0, 500)}...' : response.body}',
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
      if ((entry.key == 'image' || entry.key == 'photo') &&
          entry.value is String) {
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
      _log.fine('PATCH $uri body=$bodyPreview');
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
      _log.fine('PATCH response status=${httpResponse.statusCode}');
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
      _log.fine('DELETE $uri');
    }
    for (var attempt = 1; attempt <= maxGetAttempts; attempt++) {
      http.Response? retryResponse;
      try {
        final request = http.Request('DELETE', uri);
        request.headers.addAll(_headers(token: token));
        if (body != null) {
          request.body = jsonEncode(body);
        }
        final streamed = await _client.send(request).timeout(timeout);
        final response = await http.Response.fromStream(streamed);
        if (kDebugMode) {
          _logResponse('DELETE', uri.toString(), response);
        }
        if (response.statusCode == 204) return <String, dynamic>{};
        if (!_shouldRetry('DELETE', response.statusCode, path) ||
            attempt == maxGetAttempts) {
          return _handleResponse(response);
        }
        retryResponse = response;
      } on TimeoutException {
        if (kDebugMode) {
          _log.fine('DELETE $uri timed out (attempt $attempt/$maxGetAttempts)');
        }
        if (attempt == maxGetAttempts) rethrow;
      } on http.ClientException {
        if (kDebugMode) {
          _log.fine(
            'DELETE $uri client error (attempt $attempt/$maxGetAttempts)',
          );
        }
        if (attempt == maxGetAttempts) rethrow;
      }
      await Future<void>.delayed(_retryDelay(retryResponse, attempt));
    }
    throw StateError('DELETE retry loop exited unexpectedly.');
  }

  void _logResponse(String method, String uri, http.Response response) {
    final bodyText = utf8.decode(response.bodyBytes);
    final bodyPreview = bodyText.length > 500
        ? '${bodyText.substring(0, 500)}...'
        : bodyText;
    _log.fine('$method $uri ${response.statusCode} body=$bodyPreview');
  }

  /// Ob ein Request erneut versucht werden soll.
  ///
  /// `408` und `5xx` sind transient und werden erneut versucht. `429` (Too
  /// Many Requests) wird nur für idempotente Lesezugriffe wiederholt —
  /// Schreiboperationen erneut zu senden würde das Rate-Limit verstärken bzw.
  /// doppelte Schreibvorgänge riskieren.
  ///
  /// `/auth/refresh` und `/auth/logout` werden NIE wiederholt: Ein Refresh-Token
  /// ist Single-Use — ein automatischer Re-Send nach Timeout/5xx würde den
  /// bereits rotierten Token erneut senden und damit `401` + Logout auslösen.
  bool _shouldRetry(String method, int statusCode, String path) {
    if (path == '/auth/refresh' || path == '/auth/logout') return false;
    if (statusCode == 408 || statusCode >= 500) return true;
    return statusCode == 429 && method == 'GET';
  }

  /// Backoff zwischen Retries. Respektiert den `Retry-After`-Header
  /// (Sekunden) und fällt sonst auf einen kurzen, exponentiell wachsenden
  /// Abstand zurück.
  Duration _retryDelay(http.Response? response, int attempt) {
    final retryAfter = response?.headers['retry-after'];
    final seconds = retryAfter == null ? null : int.tryParse(retryAfter.trim());
    if (seconds != null && seconds > 0) {
      return Duration(seconds: seconds);
    }
    return Duration(milliseconds: 250 * attempt);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    // JSON ist laut RFC 8259 immer UTF-8. `response.body` dekodiert dagegen
    // mit dem charset aus dem Content-Type-Header (Default: latin1) — APIs
    // ohne `charset=utf-8` liefern so Mojibake für ä/ö/ü/ß. Daher explizit
    // als UTF-8 dekodieren.
    final decoded = utf8.decode(response.bodyBytes);
    final body = decoded.isNotEmpty
        ? jsonDecode(decoded) as Map<String, dynamic>
        : <String, dynamic>{};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw ApiException(
      errorCode: body['error'] as String? ?? 'unknown_error',
      message: body['message'] as String?,
      statusCode: response.statusCode,
      responseSize: response.bodyBytes.length,
      responsePreview: decoded.length > 500
          ? '${decoded.substring(0, 500)}...'
          : decoded,
    );
  }

  void dispose() {
    _client.close();
  }
}
