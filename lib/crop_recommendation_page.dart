import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class CropRecommendationPage extends StatefulWidget {
  const CropRecommendationPage({super.key});
  @override
  State<CropRecommendationPage> createState() => _CropRecommendationPageState();
}

class _CropRecommendationPageState extends State<CropRecommendationPage> {
  bool _isLoading = false;
  String _message = 'Choose an action below';
  // State variables to hold the data for each card
  Map<String, dynamic>? _weatherData;
  Map<String, dynamic>? _predictionData;

  // --- 1. GET BASIC WEATHER ---
  // This function calls your original /get-weather endpoint
  Future<void> _getJustWeather() async {
    setState(() {
      _isLoading = true;
      _weatherData = null; // Clear old data
      _predictionData = null;
      _message = 'Fetching your location for weather...';
    });

    try {
      Position position = await _determinePosition();
      setState(() { _message = '📍 Location found!\nFetching weather data...'; });

      // CRITICAL: REPLACE with your computer's local Wi-Fi IP address
      const String apiUrl = 'http://10.36.169.230:8000/get-weather';

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"lat": position.latitude, "lon": position.longitude}),
      ).timeout(const Duration(seconds: 30));

      if (mounted) {
        final resBody = jsonDecode(response.body);
        if (response.statusCode == 200) {
          setState(() {
            _weatherData = resBody; // Store the weather data
            _message = 'Weather data received successfully.';
          });
        } else {
          setState(() { _message = '❌ Error from server: ${resBody['detail']}'; });
        }
      }
    } catch (e) {
      if (mounted) setState(() { _message = '⚠️ An error occurred: $e'; });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  // --- 2. GET FULL RECOMMENDATION ---
  // This function calls your new /predict_from_location endpoint
  Future<void> _getFullRecommendation() async {
    setState(() {
      _isLoading = true;
      _predictionData = null; // Clear old data
      _weatherData = null;
      _message = 'Fetching your location for analysis...';
    });

    try {
      Position position = await _determinePosition();
      setState(() { _message = '📍 Location found!\nDetermining district...'; });

      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      String? district = placemarks.isNotEmpty ? (placemarks[0].subAdministrativeArea ?? placemarks[0].locality) : null;

      if (district == null) throw Exception("Could not determine your district from GPS.");

      setState(() { _message = '✅ District found: $district\nFetching full analysis...'; });

      // CRITICAL: REPLACE with your computer's local Wi-Fi IP address
      const String apiUrl = 'http://10.112.13.230:8000/predict_from_location';

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"latitude": position.latitude, "longitude": position.longitude, "district": district}),
      ).timeout(const Duration(seconds: 90));

      if (mounted) {
        final resBody = jsonDecode(response.body);
        if (response.statusCode == 200) {
          setState(() {
            _predictionData = resBody; // Store the full prediction data
            _message = 'Analysis complete. See results below.';
          });
        } else {
          setState(() { _message = '❌ Error from server: ${resBody['detail']}'; });
        }
      }
    } catch (e) {
      if (mounted) setState(() { _message = '⚠️ An error occurred: $e'; });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crop Recommendation'), backgroundColor: Colors.green[800]),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Button for Weather Only
                    ElevatedButton.icon(
                      icon: const Icon(Icons.cloud_outlined),
                      label: const Text('Get Weather Only'),
                      onPressed: _getJustWeather,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Button for Full Recommendation
                    ElevatedButton.icon(
                      icon: const Icon(Icons.grass),
                      label: const Text('Get Full Recommendation'),
                      onPressed: _getFullRecommendation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              // Conditionally display the weather card
              if (_weatherData != null) _buildWeatherCard(_weatherData!),
              // Conditionally display the prediction card
              if (_predictionData != null) _buildPredictionCard(_predictionData!),
            ],
          ),
        ),
      ),
    );
  }

  // --- CARD WIDGETS ---

  // Widget to display the simple weather result
  Widget _buildWeatherCard(Map<String, dynamic> data) {
    return Card(
      elevation: 4,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Current Weather", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(thickness: 1, height: 20),
            _buildDataRow('🌡️', 'Temperature', '${data['temperature_celsius']} °C'),
            _buildDataRow('💧', 'Humidity', '${data['humidity_percent']} %'),
            _buildDataRow('🌧️', 'Rainfall (1hr)', '${data['rainfall_mm_last_1h']} mm'),
          ],
        ),
      ),
    );
  }

  // Widget to display the full prediction result
  // Widget _buildPredictionCard(Map<String, dynamic> data) {
  //   String cropName = data['recommended_crop'] ?? 'N/A';
  //   return Card(
  //     elevation: 5,
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
  //     child: Padding(
  //       padding: const EdgeInsets.all(16.0),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           const Text("Soil & Weather Analysis", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
  //           const Divider(thickness: 1, height: 24),
  //           _buildDataRow('🌡️', 'Temperature', '${data['temperature']} °C'),
  //           _buildDataRow('💧', 'Humidity', '${data['humidity']} %'),
  //           _buildDataRow('🌧️', 'Rainfall (1hr)', '${data['rainfall']} mm'),
  //           const SizedBox(height: 12),
  //           _buildDataRow('🌱', 'Nitrogen (N)', '${data['nitrogen']} kg/ha'),
  //           _buildDataRow('🌱', 'Phosphorus (P)', '${data['phosphorus']} kg/ha'),
  //           _buildDataRow('🌱', 'Potassium (K)', '${data['potassium']} kg/ha'),
  //           _buildDataRow('🔬', 'Soil pH', '${data['ph']}'),
  //           const Divider(thickness: 1, height: 24),
  //           Center(
  //             child: Column(
  //               children: [
  //                 const Text("Based on this data, we recommend:", style: TextStyle(fontSize: 16, color: Colors.black87)),
  //                 const SizedBox(height: 8),
  //                 Container(
  //                   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
  //                   decoration: BoxDecoration(
  //                     color: Colors.green.shade100,
  //                     borderRadius: BorderRadius.circular(10),
  //                   ),
  //                   child: Text(
  //                     cropName.toUpperCase(),
  //                     style: TextStyle(
  //                       fontSize: 24,
  //                       fontWeight: FontWeight.bold,
  //                       color: Colors.green[900],
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
  // lib/crop_recommendation_page.dart

// Widget to display the full prediction result
  Widget _buildPredictionCard(Map<String, dynamic> data) {
    // Get the list of crops from the data. The '?? []' prevents errors if the key is missing.
    final List<dynamic> cropList = data['recommended_crops'] ?? [];

    return Card(
      elevation: 5,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Soil & Weather Analysis", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green[900])),
            const Divider(thickness: 1, height: 24),
            _buildDataRow('🌡️', 'Temperature', '${data['temperature']} °C'),
            _buildDataRow('💧', 'Humidity', '${data['humidity']} %'),
            _buildDataRow('🌧️', 'Rainfall (1hr)', '${data['rainfall']} mm'),
            const SizedBox(height: 12),
            _buildDataRow('🌱', 'Nitrogen (N)', '${data['nitrogen']} kg/ha'),
            _buildDataRow('🌱', 'Phosphorus (P)', '${data['phosphorus']} kg/ha'),
            _buildDataRow('🌱', 'Potassium (K)', '${data['potassium']} kg/ha'),
            _buildDataRow('🔬', 'Soil pH', '${data['ph']}'),
            const Divider(thickness: 1, height: 24),

            // --- NEW: Displaying the Top 3 Crops ---
            Center(
              child: Column(
                children: [
                  const Text(
                    "Top Recommended Crop:",
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),

                  // Display the #1 recommendation
                  if (cropList.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.shade200)
                      ),
                      child: Text(
                        (cropList[0] as String).toUpperCase(), // Safely access the first crop
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[900],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Display other suitable crops (#2 and #3)
                  if (cropList.length > 1)
                    const Text(
                      "Other Suitable Options:",
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  const SizedBox(height: 8),

                  if (cropList.length > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Chip for the #2 recommendation
                        if (cropList.length > 1)
                          Chip(
                            label: Text(cropList[1] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                            backgroundColor: Colors.grey.shade200,
                          ),
                        const SizedBox(width: 8),

                        // Chip for the #3 recommendation
                        if (cropList.length > 2)
                          Chip(
                            label: Text(cropList[2] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                            backgroundColor: Colors.grey.shade200,
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for consistent data rows
  Widget _buildDataRow(String icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$icon $label', style: const TextStyle(fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // --- HELPER FUNCTIONS ---

  // Gets the device's current position
  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services are disabled.');
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return Future.error('Location permissions are denied.');
    }
    if (permission == LocationPermission.deniedForever) return Future.error('Location permissions are permanently denied, please enable them in settings.');
    return await Geolocator.getCurrentPosition();
  }
}

