import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/explore_models.dart';

class NominatimService {
  static const _baseUrl = 'https://nominatim.openstreetmap.org';
  static const _userAgent = 'SinclearBeyondApp/1.0 (https://sinclear.app)';

  final http.Client _client;

  NominatimService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<NominatimResult>> search(String query, {int limit = 5}) async {
    final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: {
      'q': query,
      'format': 'json',
      'limit': limit.toString(),
      'addressdetails': '1',
    });

    final response = await _client.get(
      uri,
      headers: {'User-Agent': _userAgent},
    );

    if (response.statusCode != 200) return [];

    final list = jsonDecode(response.body) as List;
    return list
        .map((e) => NominatimResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void dispose() {
    _client.close();
  }
}
