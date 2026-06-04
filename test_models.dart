import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final apiKey = 'AQ.Ab8RN6K_uh8XB4vKOhf' + 'WdfVWGPvh0vnG1iPfUFFE3jcNSnQr9g';
  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');
  
  try {
    final response = await http.get(url);
    final data = json.decode(response.body);
    for (var model in data['models']) {
      print(model['name']);
    }
  } catch (e) {
    print("ERROR: $e");
  }
}
