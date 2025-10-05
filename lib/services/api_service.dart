import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // --- IMPORTANT: Remember to use your computer's network IP and the port ---
  static const String _baseUrl = "http://10.112.13.230:8000"; // Replace with your IP

  /// Fetches a fertilizer recommendation based on the user's live location and chosen crop.
  static Future<Map<String, dynamic>> getFertilizerFromLocation({
    required double latitude,
    required double longitude,
    required String district,
    required String cropName,
  }) async {
    final url = Uri.parse('$_baseUrl/recommend/fertilizer_from_location');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "latitude": latitude,
          "longitude": longitude,
          "district": district,
          "crop_name": cropName,
        }),
      );

      // The backend now returns a more complex JSON object
      return json.decode(response.body);

    } catch (e) {
      // Return an error in a consistent format (JSON map)
      return {'error': 'Failed to connect to the server. Please check your connection and the server IP.'};
    }
  }

  /// (Your old function can be kept or removed)
  /// Fetches a generic fertilizer recommendation based only on a crop name.
  static Future<String> getFertilizerRecommendationByCrop({
    required String cropName,
  }) async {
    final url = Uri.parse('$_baseUrl/recommend/fertilizer_by_crop');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"crop_name": cropName}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data.containsKey('recommendation')
            ? data['recommendation']
            : 'Error: ${data['error']}';
      } else {
        return 'Error: Server returned status code ${response.statusCode}';
      }
    } catch (e) {
      return 'Failed to connect to the server.';
    }
  }
}

