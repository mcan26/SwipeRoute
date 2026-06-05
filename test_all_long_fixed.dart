import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final apiKey = 'AQ.Ab8RN6K_uh8XB4vKOhf' + 'WdfVWGPvh0vnG1iPfUFFE3jcNSnQr9g';
  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=\$apiKey');
  
  List<String> models = [];
  try {
    final response = await http.get(url);
    final data = json.decode(response.body);
    for (var model in data['models']) {
      models.add(model['name'].replaceAll('models/', ''));
    }
  } catch (e) {
    print("ERROR fetching models: \$e");
    return;
  }

  final prompt = '''
      Sen profesyonel bir seyahat rehberisin. Seçilen mekanlarla 3 günlük çok detaylı bir İstanbul seyahat rotası oluştur.

      Seçilen Mekanlar:
      - Galata Kulesi
      - Ayasofya
      - Topkapı Sarayı

      Lütfen şu kurallara kesinlikle uy:
      1. Sadece seçilen mekanları kullanarak 3 güne bölüştür.
      2. Mekanları haritadaki yakınlıklarına ve mantıklı bir gezi sırasına göre grupla.
      3. Her gün için Sabah, Öğle, Akşam olarak alt başlıklar koy.
      4. Mekanlar hakkında kısa ama ilgi çekici (1-2 cümlelik) tarihi/turistik bilgiler ver.
      5. Çok samimi, enerjik ve "Kingo" tarzı bir rehber dili kullan.
      6. Sadece gezi planını ver, başka gereksiz giriş/çıkış cümleleri kullanma.
      ''';

  print("Testing \${models.length} models with LONG prompt...");
  for (var m in models) {
    if (!m.contains('gemini')) continue;
    print("Trying: " + m);
    try {
      final model = GenerativeModel(model: m, apiKey: apiKey);
      final res = await model.generateContent([Content.text(prompt)]);
      print("SUCCESS " + m + "! RESPONSE LENGTH: " + (res.text?.length.toString() ?? "0"));
      return; 
    } catch (e) {
      // Ignored
    }
  }
  print("ALL GEMINI MODELS FAILED FOR LONG PROMPT.");
}
