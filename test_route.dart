import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';

void main() async {
  print('Testing Gemini Route Generation with new API key...');
  final apiKey = 'AQ.Ab8RN6K_uh8XB4vKOhf' + 'WdfVWGPvh0vnG1iPfUFFE3jcNSnQr9g';
  
  final model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: apiKey,
  );

  final prompt = '''
  Sen profesyonel bir seyahat rehberisin. İstanbul için 1 günlük kısa bir deneme rotası oluştur.
  ''';

  try {
    final response = await model.generateContent([Content.text(prompt)]);
    print('SUCCESS! Response from Gemini:');
    print('-----------------------------------');
    print(response.text);
    print('-----------------------------------');
  } catch (e, stacktrace) {
    print('FAILED! Error:');
    print(e);
    print(stacktrace);
  }
}
