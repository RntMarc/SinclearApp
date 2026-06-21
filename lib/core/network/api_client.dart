import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String errorCode;
  final String? message;
  final int statusCode;

  const ApiException({
    required this.errorCode,
    this.message,
    required this.statusCode,
  });

  @override
  String toString() {
    final details = message != null ? ' - $message' : '';
    return 'ApiException($statusCode): $errorCode$details';
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
    final response = await _client
        .post(
          uri,
          headers: _headers(token: token),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(timeout);
    return _handleResponse(response);
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
    for (var attempt = 1; attempt <= maxGetAttempts; attempt++) {
      try {
        final response = await _client
            .get(uri, headers: _headers(token: token))
            .timeout(timeout);
        if (!_shouldRetry(response.statusCode) || attempt == maxGetAttempts) {
          return _handleResponse(response);
        }
      } on TimeoutException {
        if (attempt == maxGetAttempts) rethrow;
      } on http.ClientException {
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
    final response = await _client
        .put(
          uri,
          headers: _headers(token: token),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(timeout);
    return _handleResponse(response);
  }

  Future<void> delete(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.Request('DELETE', uri);
    request.headers.addAll(_headers(token: token));
    if (body != null) {
      request.body = jsonEncode(body);
    }
    final streamed = await _client.send(request).timeout(timeout);
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 204) return;
    _handleResponse(response);
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
    );
  }

  void dispose() {
    _client.close();
  }
}
