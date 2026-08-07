import 'package:firebase_ai/firebase_ai.dart';

class GeminiService {

  final model = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-2.5-flash',
  );

  Future<String> askGemini(String prompt) async {

    final response = await model.generateContent([
      Content.text(prompt),
    ]);

    return response.text ?? "No response";
  }
}