import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';

void main() async {
  final apiKey = 'AQ.Ab8RN6K_uh8XB4vKOhf' + 'WdfVWGPvh0vnG1iPfUFFE3jcNSnQr9g';
  
  print("Testing gemini-2.5-flash...");
  try {
    final model25 = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
    final res25 = await model25.generateContent([Content.text("Hello")]);
    print("2.5 SUCCESS: ${res25.text}");
  } catch (e) {
    print("2.5 ERROR: $e");
  }

  print("Testing gemini-1.5-flash...");
  try {
    final model15 = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
    final res15 = await model15.generateContent([Content.text("Hello")]);
    print("1.5 SUCCESS: ${res15.text}");
  } catch (e) {
    print("1.5 ERROR: $e");
  }
}
