import 'package:flutter/material.dart';
import 'prediction_service.dart';

void main() {
  runApp(const DiabetesApp());
}

class DiabetesApp extends StatelessWidget {
  const DiabetesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diabetes Risk Predictor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D6B)),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
        ),
      ),
      home: const PredictionPage(),
    );
  }
}

class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for each input field, pre-filled with sample values
  // so the demo is easy to try out immediately.
  final _pregnancies = TextEditingController(text: '2');
  final _glucose = TextEditingController(text: '120');
  final _bloodPressure = TextEditingController(text: '70');
  final _skinThickness = TextEditingController(text: '20');
  final _insulin = TextEditingController(text: '79');
  final _bmi = TextEditingController(text: '25.0');
  final _dpf = TextEditingController(text: '0.5');
  final _age = TextEditingController(text: '30');

  bool _isLoading = false;
  String? _errorMessage;
  PredictionResult? _result;

  final _service = PredictionService();

  @override
  void dispose() {
    _pregnancies.dispose();
    _glucose.dispose();
    _bloodPressure.dispose();
    _skinThickness.dispose();
    _insulin.dispose();
    _bmi.dispose();
    _dpf.dispose();
    _age.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _result = null;
    });

    try {
      final result = await _service.predict(
        pregnancies: double.parse(_pregnancies.text),
        glucose: double.parse(_glucose.text),
        bloodPressure: double.parse(_bloodPressure.text),
        skinThickness: double.parse(_skinThickness.text),
        insulin: double.parse(_insulin.text),
        bmi: double.parse(_bmi.text),
        diabetesPedigreeFunction: double.parse(_dpf.text),
        age: double.parse(_age.text),
      );
      setState(() => _result = result);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to get prediction: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String? _numericValidator(String? value, {bool allowDecimal = true}) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final parsed = double.tryParse(value);
    if (parsed == null) return 'Enter a valid number';
    if (parsed < 0) return 'Must be 0 or more';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diabetes Risk Predictor'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SectionLabel('Patient Health Metrics'),
                const SizedBox(height: 12),
                _buildField('Pregnancies', _pregnancies, hint: 'e.g. 2'),
                _buildField('Glucose (mg/dL)', _glucose, hint: 'e.g. 120'),
                _buildField('Blood Pressure (mm Hg)', _bloodPressure, hint: 'e.g. 70'),
                _buildField('Skin Thickness (mm)', _skinThickness, hint: 'e.g. 20'),
                _buildField('Insulin (mu U/ml)', _insulin, hint: 'e.g. 79'),
                _buildField('BMI', _bmi, hint: 'e.g. 25.0'),
                _buildField('Diabetes Pedigree Function', _dpf, hint: 'e.g. 0.5'),
                _buildField('Age', _age, hint: 'e.g. 30'),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.health_and_safety),
                  label: Text(_isLoading ? 'Predicting...' : 'Predict Risk'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 20),
                if (_errorMessage != null) _buildError(_errorMessage!),
                if (_result != null) _buildResultCard(_result!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
        ),
        validator: _numericValidator,
      ),
    );
  }

  Widget _buildError(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: Colors.red.shade700)),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(PredictionResult result) {
    final isHighRisk = result.prediction == 1;
    final color = switch (result.riskLevel) {
      'High' => Colors.red,
      'Moderate' => Colors.orange,
      _ => Colors.green,
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.shade200, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isHighRisk ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                color: color.shade700,
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                isHighRisk ? 'Diabetes Risk Detected' : 'Low Diabetes Risk',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Probability: ${(result.probability * 100).toStringAsFixed(1)}%',
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            'Risk Level: ${result.riskLevel}',
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: result.probability,
            backgroundColor: color.shade100,
            color: color.shade600,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          Text(
            'Note: This is a demo model and not a substitute for professional medical advice.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    );
  }
}
