import 'package:google_generative_ai/google_generative_ai.dart';

void main() async {
  final apiKey = 'AQ.Ab8RN6K_uh8XB4vKOhf' + 'WdfVWGPvh0vnG1iPfUFFE3jcNSnQr9g';
  final models = [
    'gemini-1.5-flash',
    'gemini-1.5-flash-8b',
    'gemini-2.0-flash-exp',
    'gemini-exp-1206',
    'gemini-2.5-flash',
    'gemini-3.0-flash'
  ];

  final prompt = '''
      Sen profesyonel bir seyahat rehberisin. Seçilen mekanlarla 3 günlük çok detaylı bir İstanbul seyahat rotası oluştur.

      Seçilen Mekanlar:
      - Galata Kulesi
      - Ayasofya
      - Topkapı Sarayı
      ''';

  for (var m in models) {
    print("Trying " + m);
    try {
      final model = GenerativeModel(model: m, apiKey: apiKey);
      final res = await model.generateContent([Content.text(prompt)]);
      print("SUCCESS " + m + "!");
      return;
    } catch (e) {
      print("FAILED " + m + ": " + e.toString().substring(0, 30) + "...");
    }
  }
}
