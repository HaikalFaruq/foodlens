import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:food_recognizer_app/env/env.dart';
import 'package:food_recognizer_app/model/nutrition_info.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  late final GenerativeModel _model;
  bool _isInitialized = false;

  GeminiService() {
    final apiKey = Env.geminiApiKey;
    if (apiKey.isNotEmpty) {
      _model = GenerativeModel(
        model: 'gemini-2.5-flash-lite',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.2,
          responseMimeType: 'application/json',
        ),
      );
      _isInitialized = true;
    } else {
      debugPrint('[GeminiService] API key kosong / belum dikonfigurasi.');
      _isInitialized = false;
    }
  }

  Future<NutritionInfo?> getNutritionInfoFromGemini(String foodName) async {
    if (!_isInitialized) {
      debugPrint('[GeminiService] belum initialized.');
      return null;
    }

    final prompt =
        'Untuk makanan "$foodName", kembalikan JSON valid (tanpa teks lain) '
        'dengan keys persis: '
        '{"calories": number, "fat_total_g": number, "carbohydrates_total_g": number, '
        '"protein_g": number, "fiber_g": number}. '
        'Satuan per 100 gram.';

    try {
      final res = await _model
          .generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 20));

      if (res.promptFeedback != null &&
          res.promptFeedback!.blockReason != null) {
        debugPrint('[GeminiService] Blocked: ${res.promptFeedback!.blockReason}');
        return null;
      }

      final text = res.text;
      if (text == null || text.trim().isEmpty) {
        debugPrint('[GeminiService] Response text kosong.');
        return null;
      }

      final map = json.decode(text) as Map<String, dynamic>;
      map['name'] = foodName;
      return NutritionInfo.fromJson(map);

    } on TimeoutException {
      debugPrint('[GeminiService] Timeout.');
      return null;
    } on FormatException catch (e) {
      debugPrint('[GeminiService] JSON parse error: $e');
      return null;
    } catch (e, st) {
      debugPrint('[GeminiService] Error: $e\n$st');
      return null;
    }
  }

  Future<String?> generateFoodDescription(String foodName) async {
    if (!_isInitialized) {
      return 'Could not generate description: API key not configured.';
    }

    final prompt =
        "Berikan deskripsi singkat 2–3 kalimat tentang '$foodName' "
        "dalam bahasa Indonesia (tanpa heading/bullet).";

    try {
      final res = await _model
          .generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 20));

      if (res.promptFeedback != null &&
          res.promptFeedback!.blockReason != null) {
        debugPrint('[GeminiService] Blocked (desc): ${res.promptFeedback!.blockReason}');
        return 'Deskripsi diblokir oleh kebijakan konten.';
      }

      return res.text ?? 'Tidak dapat menghasilkan deskripsi.';
    } on TimeoutException {
      return 'Layanan AI timeout. Coba lagi.';
    } catch (e, st) {
      debugPrint('[GeminiService] Desc error: $e\n$st');
      return 'Terjadi kesalahan saat menghubungi layanan AI.';
    }
  }
}
