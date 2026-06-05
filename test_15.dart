import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';

void main() async {
  final apiKey = 'AQ.Ab8RN6K_uh8XB4vKOhf' + 'WdfVWGPvh0vnG1iPfUFFE3jcNSnQr9g';
  final models = ['gemini-1.5-pro-latest', 'gemini-1.5-flash-latest'];
  final prompt = 'Kısa test';
  
  for (var m in models) {
    try {
      final model = GenerativeModel(model: m, apiKey: apiKey);
      final res = await model.generateContent([Content.text(prompt)]);
      print("SUCCESS $m: ${res.text}");
    } catch (e) {
      print("ERROR $m: $e");
    }
  }
}
