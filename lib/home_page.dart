// lib/home_page.dart
import 'package:flutter/material.dart';
import 'crop_recommendation_page.dart';
import 'disease_prediction_page.dart';
import 'fertilizer_recommendation_page.dart'; // Import the new page

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AgroPath Dashboard'),
        backgroundColor: Colors.green[800],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset(
            'assets/images/OIP.jpeg',
            fit: BoxFit.cover,
            color: Colors.black.withOpacity(0.7),
            colorBlendMode: BlendMode.darken,
          ),
          // Feature List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: ListView(
              children: [
                _buildFeatureCard(
                  context: context,
                  icon: Icons.grass,
                  title: 'Crop Recommendation',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CropRecommendationPage()),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _buildFeatureCard(
                  context: context,
                  icon: Icons.sick_outlined,
                  title: 'Disease Prediction',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const DiseasePredictionPage()),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // --- NEW FEATURE CARD ADDED HERE ---
                _buildFeatureCard(
                  context: context,
                  icon: Icons.science_outlined, // Icon for fertilizer
                  title: 'Fertilizer Recommendation',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FertilizerRecommendationPage()),
                    );
                  },
                ),
                // ------------------------------------

                const SizedBox(height: 20),
                _buildFeatureCard(
                  context: context,
                  icon: Icons.bar_chart_outlined,
                  title: 'Profit Analysis',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Feature coming soon!')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget - no changes needed here
  Widget _buildFeatureCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.green.withOpacity(0.25),
      elevation: 8.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: Colors.green.shade200, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, size: 45, color: Colors.white),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }
}