import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:food_recognizer_app/env/env.dart';
import 'package:food_recognizer_app/model/nutrition_info.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  late final GenerativeModel _jsonModel;
  late final GenerativeModel _textModel;
  bool _isInitialized = false;

  GeminiService() {
    final apiKey = Env.geminiApiKey;
    if (apiKey.isNotEmpty) {
      // Model for JSON responses (nutrition info)
      _jsonModel = GenerativeModel(
        model: 'gemini-2.5-flash-lite',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.2,
          responseMimeType: 'application/json',
        ),
      );
      
      // Model for text responses (descriptions)
      _textModel = GenerativeModel(
        model: 'gemini-2.5-flash-lite',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
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
      final res = await _jsonModel
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
      return 'Tidak dapat menghasilkan deskripsi: API key belum dikonfigurasi.';
    }

    final prompt =
        "Berikan deskripsi singkat 2-3 kalimat tentang '$foodName' "
        "dalam bahasa Indonesia. Jelaskan secara natural tanpa format JSON, "
        "tanpa heading, dan tanpa bullet points.";

    try {
      final res = await _textModel
          .generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 15));

      if (res.promptFeedback != null &&
          res.promptFeedback!.blockReason != null) {
        debugPrint('[GeminiService] Blocked (desc): ${res.promptFeedback!.blockReason}');
        return 'Deskripsi diblokir oleh kebijakan konten.';
      }

      final description = res.text?.trim();
      if (description == null || description.isEmpty) {
        return 'Tidak dapat menghasilkan deskripsi.';
      }
      
      // Clean up any JSON artifacts if present
      if (description.startsWith('{') || description.startsWith('[')) {
        try {
          final parsed = json.decode(description);
          if (parsed is Map && parsed.containsKey('deskripsi')) {
            return parsed['deskripsi']?.toString().trim();
          }
        } catch (_) {
          // If JSON parsing fails, return as-is
        }
      }
      
      return description;
    } on TimeoutException {
      return 'Layanan AI timeout. Coba lagi.';
    } catch (e, st) {
      debugPrint('[GeminiService] Desc error: $e\n$st');
      return 'Terjadi kesalahan saat menghubungi layanan AI.';
    }
  }
}
