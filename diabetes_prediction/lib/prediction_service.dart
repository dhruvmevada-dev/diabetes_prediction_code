import 'dart:convert';
import 'package:http/http.dart' as http;

/// Holds the result returned by the /predict endpoint.
class PredictionResult {
  final int prediction; // 0 = no diabetes, 1 = diabetes
  final double probability; // probability of class 1
  final String riskLevel; // "Low" | "Moderate" | "High"

  PredictionResult({
    required this.prediction,
    required this.probability,
    required this.riskLevel,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      prediction: json['prediction'] as int,
      probability: (json['probability'] as num).toDouble(),
      riskLevel: json['risk_level'] as String,
    );
  }
}

class PredictionService {
  /// Base URL of the FastAPI backend.
  ///
  /// IMPORTANT:
  /// - Android emulator: use http://10.0.2.2:8000
  /// - iOS simulator / desktop / web (Chrome) on the same machine: http://127.0.0.1:8000 or http://localhost:8000
  /// - Physical device: use your computer's LAN IP, e.g. http://192.168.1.50:8000
  static const String baseUrl = 'https://diabetespredictioncode-production.up.railway.app';

  Future<PredictionResult> predict({
    required double pregnancies,
    required double glucose,
    required double bloodPressure,
    required double skinThickness,
    required double insulin,
    required double bmi,
    required double diabetesPedigreeFunction,
    required double age,
  }) async {
    final uri = Uri.parse('$baseUrl/predict');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'pregnancies': pregnancies,
        'glucose': glucose,
        'blood_pressure': bloodPressure,
        'skin_thickness': skinThickness,
        'insulin': insulin,
        'bmi': bmi,
        'diabetes_pedigree_function': diabetesPedigreeFunction,
        'age': age,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return PredictionResult.fromJson(data);
    } else {
      throw Exception(
        'Server returned ${response.statusCode}: ${response.body}',
      );
    }
  }
}
