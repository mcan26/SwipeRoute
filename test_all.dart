import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final apiKey = 'AQ.Ab8RN6K_uh8XB4vKOhf' + 'WdfVWGPvh0vnG1iPfUFFE3jcNSnQr9g';
  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');
  
  List<String> models = [];
  try {
    final response = await http.get(url);
    final data = json.decode(response.body);
    for (var model in data['models']) {
      models.add(model['name'].replaceAll('models/', ''));
    }
  } catch (e) {
    print("ERROR fetching models: $e");
    return;
  }

  print("Testing \${models.length} models...");
  for (var m in models) {
    if (!m.contains('gemini')) continue;
    try {
      final model = GenerativeModel(model: m, apiKey: apiKey);
      final res = await model.generateContent([Content.text("A")]);
      print("SUCCESS $m: \${res.text?.substring(0, 10)}");
      return; // Stop on first success!
    } catch (e) {
      // Ignore errors
    }
  }
  print("ALL GEMINI MODELS FAILED.");
}
