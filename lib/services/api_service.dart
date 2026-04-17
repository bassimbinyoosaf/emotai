import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'emotion_result.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.1.4:3000';

  static Future<String> sendChatMessage({
    required String emotion,
    required String message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("http://192.168.1.4:3000/chat"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"emotion": emotion, "message": message}),
      );

      print("CHAT STATUS: ${response.statusCode}");
      print("CHAT BODY: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["reply"];
      } else {
        throw Exception("Chat failed: ${response.body}");
      }
    } catch (e) {
      print("CHAT EXCEPTION: $e");
      rethrow;
    }
  }

  static Future<EmotionResult> sendImage(File image) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/predict'),
    );

    request.files.add(await http.MultipartFile.fromPath('image', image.path));

    final response = await request.send().timeout(const Duration(seconds: 50));

    final body = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception('Status ${response.statusCode}: $body');
    }
    return EmotionResult.fromJson(jsonDecode(body));
  }
}
