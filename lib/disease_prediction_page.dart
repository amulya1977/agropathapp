// lib/disease_prediction_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DiseasePredictionPage extends StatefulWidget {
  const DiseasePredictionPage({super.key});

  @override
  State<DiseasePredictionPage> createState() => _DiseasePredictionPageState();
}

class _DiseasePredictionPageState extends State<DiseasePredictionPage> {
  File? _selectedImage;
  bool _isLoading = false;

  // NEW: State variables for structured results
  String? _diseaseName;
  String? _confidence;
  String? _managementInfo;
  String? _disclaimer;
  String? _errorMessage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        // Clear previous results when a new image is picked
        _diseaseName = null;
        _confidence = null;
        _managementInfo = null;
        _disclaimer = null;
        _errorMessage = null;
      });
    }
  }

  Future<void> _predictDisease() async {
    if (_selectedImage == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear previous errors
    });

    try {
      const String apiUrl = 'http://10.112.13.230:8000/predict-disease';
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.files.add(
        await http.MultipartFile.fromPath('file', _selectedImage!.path),
      );

      var response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final decodedBody = jsonDecode(responseBody);

      if (mounted) {
        if (response.statusCode == 200) {
          // NEW: Update state with all the new data from the server
          setState(() {
            _diseaseName = decodedBody['predicted_disease']?.replaceAll('_', ' ');
            _confidence = decodedBody['confidence_percent'];
            _managementInfo = decodedBody['management_info'];
            _disclaimer = decodedBody['disclaimer'];
          });
        } else {
          setState(() {
            _errorMessage = '❌ Error: ${decodedBody['detail']}';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '⚠️ An error occurred: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // NEW: A dedicated widget to build the result display
  Widget _buildResultWidget() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      // Wrap the String in a Text widget before passing it.
      return _buildResultContainer(Text(_errorMessage!), isError: true);
    }

    if (_diseaseName != null) {
      return _buildResultContainer(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResultRow('🌿 Disease:', _diseaseName!),
            const SizedBox(height: 8),
            // _buildResultRow('🎯 Confidence:', '${_confidence ?? 'N/A'}%'),
            const Divider(height: 24, thickness: 1),
            Text(
              '🔬 Management & Cure:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green[900],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _managementInfo ?? 'Not available.',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            if (_disclaimer != null) ...[
              const Divider(height: 24, thickness: 1),
              Text(
                _disclaimer!,
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[700],
                ),
              ),
            ]
          ],
        ),
      );
    }
    // Return an empty container if there's no result, error, or loading state
    return Container();
  }

  // Helper for displaying result rows
  Widget _buildResultRow(String title, String value) {
    return Text.rich(
      TextSpan(
        text: title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.green[900],
        ),
        children: [
          TextSpan(
            text: ' $value',
            style: const TextStyle(fontWeight: FontWeight.normal),
          ),
        ],
      ),
    );
  }

  // Helper for creating the result container
  Widget _buildResultContainer(Widget child, {bool isError = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isError ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isError ? Colors.red.shade200 : Colors.green.shade200,
        ),
      ),
      child: isError
          ? Text(
        _errorMessage!,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.red[800],
        ),
      )
          : child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Disease Prediction'),
        backgroundColor: Colors.green[800],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 250,
                  width: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green.shade200, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _selectedImage == null
                      ? const Center(
                    child: Text(
                      'Select an image to begin',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                      : ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(_selectedImage!, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Select Image from Gallery'),
                  onPressed: _pickImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.science_outlined),
                  label: const Text('Predict Disease'),
                  onPressed: _selectedImage != null ? _predictDisease : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 30),
                // UPDATED: Result display area
                _buildResultWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}