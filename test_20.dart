import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';

void main() async {
  final apiKey = 'AQ.Ab8RN6K_uh8XB4vKOhf' + 'WdfVWGPvh0vnG1iPfUFFE3jcNSnQr9g';
  final model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);
  final prompt = '''
      Sen profesyonel bir seyahat rehberisin. Seçilen mekanlarla 3 günlük çok detaylı bir İstanbul seyahat rotası oluştur.

      Seçilen Mekanlar:
      - Galata Kulesi
      - Ayasofya
      - Topkapı Sarayı
      ''';
  try {
    final res = await model.generateContent([Content.text(prompt)]);
    print("SUCCESS: ${res.text?.substring(0, 100)}...");
  } catch (e) {
    print("ERROR: $e");
  }
}
