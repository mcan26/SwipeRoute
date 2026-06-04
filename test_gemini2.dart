import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';

void main() async {
  final apiKey = 'AQ.Ab8RN6K_uh8XB4vKOhf' + 'WdfVWGPvh0vnG1iPfUFFE3jcNSnQr9g';
  
  print("Testing gemini-pro...");
  try {
    final model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
    final res = await model.generateContent([Content.text("Hello")]);
    print("PRO SUCCESS: ${res.text}");
  } catch (e) {
    print("PRO ERROR: $e");
  }
}
