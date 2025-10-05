import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'services/api_service.dart';

class FertilizerRecommendationPage extends StatefulWidget {
  const FertilizerRecommendationPage({super.key});

  @override
  State<FertilizerRecommendationPage> createState() => _FertilizerRecommendationPageState();
}

class _FertilizerRecommendationPageState extends State<FertilizerRecommendationPage> {
  final _formKey = GlobalKey<FormState>();
  final _cropController = TextEditingController();

  // State variables for better UI feedback
  Position? _currentPosition;
  String? _currentDistrict;
  String _message = "Please get your current location";
  Map<String, dynamic>? _resultData;
  String _errorResult = "";
  bool _isLoading = false;

  /// Fetches the device's current GPS location and determines the district.
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _message = "Fetching location...";
      _resultData = null; // Clear previous results
      _errorResult = "";
    });
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() => _message = "Location permission denied. Please enable it in your phone's settings.");
        return;
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

      setState(() {
        _currentPosition = position;
        _currentDistrict = placemarks[0].subAdministrativeArea ?? "Unknown District";
        _message = "✅ Location Found: $_currentDistrict";
      });
    } catch (e) {
      setState(() => _message = "Could not get location. Ensure GPS is on.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Calls the backend API to get a fertilizer recommendation.
  Future<void> _getRecommendation() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please get your location first.'))
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _resultData = null; // Clear previous results
      _errorResult = "";
      _message = "Analyzing soil data for '${_cropController.text}'...";
    });

    final response = await ApiService.getFertilizerFromLocation(
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
      district: _currentDistrict!,
      cropName: _cropController.text,
    );

    setState(() {
      if (response.containsKey('recommendation')) {
        _resultData = response;
        _message = "Analysis complete. See results below.";
      } else {
        _errorResult = response['error'] ?? 'An unknown error occurred.';
        _message = "An error occurred during analysis.";
      }
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _cropController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fertilizer Recommendation'),
        backgroundColor: Colors.green[800],
      ),
      // --- MODIFICATION: The body's Container with the gradient has been removed. ---
      // The Scaffold's default background is white, so no container is needed.
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Status Message ---
                Text(_message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                const SizedBox(height: 24),

                // --- Action Buttons and Form ---
                if (!_isLoading)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // This redundant ListTile has been removed for a cleaner look
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.my_location),
                        label: const Text('Get Current Location'),
                        onPressed: _getCurrentLocation,
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                      ),
                      const Divider(height: 40, color: Colors.grey),
                      TextFormField(
                        controller: _cropController,
                        enabled: _currentPosition != null,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Enter Crop Name (e.g., Rice)',
                          border: const OutlineInputBorder(),
                          filled: _currentPosition == null,
                          fillColor: Colors.grey[200],
                        ),
                        validator: (value) => (value == null || value.isEmpty) ? 'Please enter a crop name' : null,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.science_outlined),
                        label: const Text('Get Recommendation'),
                        onPressed: _currentPosition == null ? null : _getRecommendation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),

                if (_isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())),

                const SizedBox(height: 24),

                // --- Result Display Cards ---
                if (_errorResult.isNotEmpty) _buildErrorCard(_errorResult),
                if (_resultData != null) _buildResultCard(_resultData!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // WIDGET: Builds a structured card to display results
  Widget _buildResultCard(Map<String, dynamic> data) {
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
            Text("Fertilizer Analysis", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green[900])),
            const Divider(thickness: 1, height: 24),
            _buildDataRow('💡', 'Recommendation', data['recommendation']?.replaceAll('**', '') ?? 'N/A', isRecommendation: true),
            const Divider(thickness: 1, height: 24),
            const Text("Soil Nutrient Details (kg/ha)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 12),
            _buildNutrientRow('🌱', "Nitrogen (N)", data['measured_N'], data['ideal_N']),
            _buildNutrientRow('🌱', "Phosphorus (P)", data['measured_P'], data['ideal_P']),
            _buildNutrientRow('🌱', "Potassium (K)", data['measured_K'], data['ideal_K']),
          ],
        ),
      ),
    );
  }

  // WIDGET: Helper for consistent data rows
  Widget _buildDataRow(String icon, String label, String value, {bool isRecommendation = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$icon $label', style: const TextStyle(fontSize: 16, color: Colors.black54)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isRecommendation ? 18 : 16,
              fontWeight: FontWeight.bold,
              color: isRecommendation ? Colors.green[800] : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET: Helper for nutrient comparison rows
  Widget _buildNutrientRow(String icon, String name, dynamic measured, dynamic ideal) {
    final bool isDeficient = (measured != null && ideal != null && measured < ideal);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(
            child: Text('$icon $name', style: const TextStyle(fontSize: 16)),
          ),
          Row(
            children: [
              Text(
                "Measured: $measured",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDeficient ? Colors.red.shade700 : Colors.green.shade700),
              ),
              Text(" (Ideal: $ideal)", style: const TextStyle(fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  // WIDGET: Builds a card to display errors
  Widget _buildErrorCard(String error) {
    return Card(
      elevation: 4,
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          error,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.red.shade900, fontSize: 16),
        ),
      ),
    );
  }
}

