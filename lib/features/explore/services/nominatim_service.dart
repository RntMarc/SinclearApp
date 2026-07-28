import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/explore_models.dart';

class NominatimService {
  static const _baseUrl = 'https://nominatim.openstreetmap.org';
  static const _userAgent = 'SinclearBeyondApp/1.0 (https://sinclear.app)';
  static const _minRequestInterval = Duration(seconds: 1);

  final http.Client _client;
  DateTime _lastRequest = DateTime(0);

  NominatimService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<NominatimResult>> search(String query, {int limit = 5}) async {
    final now = DateTime.now();
    final elapsed = now.difference(_lastRequest);
    if (elapsed < _minRequestInterval) {
      await Future.delayed(_minRequestInterval - elapsed);
    }

    final uri = Uri.parse('$_baseUrl/search').replace(
      queryParameters: {
        'q': query,
        'format': 'json',
        'limit': limit.toString(),
        'addressdetails': '1',
      },
    );

    final response = await _client.get(
      uri,
      headers: {'User-Agent': _userAgent},
    );

    _lastRequest = DateTime.now();
    if (response.statusCode != 200) return [];

    final list = jsonDecode(response.body) as List;
    return list
        .map((e) => NominatimResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>?> lookup(int osmId, String osmType) async {
    final now = DateTime.now();
    final elapsed = now.difference(_lastRequest);
    if (elapsed < _minRequestInterval) {
      await Future.delayed(_minRequestInterval - elapsed);
    }

    const typeMap = {'node': 'N', 'way': 'W', 'relation': 'R'};
    final typeLetter = typeMap[osmType] ?? osmType.toUpperCase();
    final osmIds = '$typeLetter$osmId';

    final uri = Uri.parse('$_baseUrl/lookup').replace(
      queryParameters: {
        'osm_ids': osmIds,
        'format': 'json',
        'addressdetails': '1',
        'extratags': '1',
      },
    );

    final response = await _client.get(
      uri,
      headers: {'User-Agent': _userAgent},
    );

    _lastRequest = DateTime.now();
    if (response.statusCode != 200) return null;

    final list = jsonDecode(response.body) as List;
    if (list.isEmpty) return null;
    return list[0] as Map<String, dynamic>;
  }

  void dispose() {
    _client.close();
  }
}
