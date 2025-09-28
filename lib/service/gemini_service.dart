import 'dart:async';
import 'dart:convert';

import 'package:food_recognizer_app/env/env.dart';
import 'package:food_recognizer_app/model/nutrition_info.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  late final GenerativeModel _model;
  bool _isInitialized = false;

  GeminiService() {
    final apiKey = Env.geminiApiKey;
    if (apiKey.isNotEmpty && !apiKey.contains("YOUR")) {
      _model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(temperature: 0.2),
      );
      _isInitialized = true;
    } else {
      _isInitialized = false;
    }
  }

  Future<String?> generateFoodDescription(String foodName) async {
    if (!_isInitialized)
      return "Could not generate description: API key not configured.";
    final prompt =
        "Berikan deskripsi singkat (2–3 kalimat) tentang '$foodName' ...";
    try {
      final res = await _model.generateContent([Content.text(prompt)]).timeout(
          const Duration(seconds: 12));
      return res.text ?? "Tidak dapat menghasilkan deskripsi.";
    } on TimeoutException {
      return "Layanan AI timeout. Coba lagi.";
    } catch (_) {
      return "Terjadi kesalahan saat menghubungi layanan AI.";
    }
  }

  String _cleanJsonString(String raw) {
    final t = raw
        .replaceAll(RegExp(r'```[a-zA-Z]*'), '')
        .replaceAll('```', '')
        .trim();
    final s = t.indexOf('{');
    final e = t.lastIndexOf('}');
    return (s != -1 && e != -1 && e > s) ? t.substring(s, e + 1) : t;
  }

  Future<NutritionInfo?> getNutritionInfoFromGemini(String foodName) async {
    if (!_isInitialized) return null;
    final prompt =
        'Untuk makanan "$foodName", berikan estimasi nutrisi per 100g dalam JSON valid dengan keys: '
        '{"calories","fat_total_g","carbohydrates_total_g","protein_g","fiber_g"} tanpa teks tambahan.';
    try {
      final res = await _model.generateContent([Content.text(prompt)]).timeout(
          const Duration(seconds: 12));
      if (res.text == null) return null;
      final cleaned = _cleanJsonString(res.text!);
      final map = json.decode(cleaned) as Map<String, dynamic>;
      map['name'] = foodName;
      return NutritionInfo.fromJson(map);
    } catch (_) {
      return NutritionInfo.notFound(foodName);
    }
  }
}
