import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  // 🔑 Replace this with your valid Gemini API key
  final String apiKey = "AIzaSyCKCOqf8jdzXibSLfASV2ol6HT_4b22Uk8";

  Future<String> generateText(String prompt) async {
    final url = Uri.parse(
      // ✅ Correct endpoint for current Gemini API (v1beta + proper model)
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey",
    );

    final headers = {"Content-Type": "application/json"};
    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": prompt}
          ]
        }
      ]
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"];
        return text ?? "No response from Gemini.";
      } else {
        print("❌ API Error ${response.statusCode}: ${response.body}");
        return "API error (${response.statusCode}): ${response.body}";
      }
    } catch (e) {
      print("⚠️ Exception: $e");
      return "Error connecting to Gemini service.";
    }
  }
}
