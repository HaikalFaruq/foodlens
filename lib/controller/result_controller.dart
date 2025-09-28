import 'package:flutter/material.dart';
import 'package:food_recognizer_app/model/food_info.dart';
import 'package:food_recognizer_app/model/nutrition_info.dart';
import 'package:food_recognizer_app/service/gemini_service.dart';
import 'package:food_recognizer_app/service/nutrition_service.dart';

class ResultController extends ChangeNotifier {
  final GeminiService _geminiService;
  final NutritionService _nutritionRepository;

  ResultController({
    required GeminiService geminiService,
    required NutritionService nutritionRepository,
  })  : _geminiService = geminiService,
        _nutritionRepository = nutritionRepository;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  FoodInfo? _foodInfo;

  FoodInfo? get foodInfo => _foodInfo;

  Future<void> fetchFoodDetails(String foodLabel, double confidence) async {
    _isLoading = true;
    _foodInfo = FoodInfo(label: foodLabel, confidence: confidence);
    notifyListeners();

    try {
      NutritionInfo? nutritionResult =
          await _geminiService.getNutritionInfoFromGemini(foodLabel);

      if (nutritionResult == null) {
        if (!_nutritionRepository.isInitialized) {
          await _nutritionRepository.initialize();
        }
        nutritionResult = _nutritionRepository.getLocalNutritionInfo(foodLabel);
      }

      nutritionResult ??= NutritionInfo.notFound(foodLabel);

      String? descriptionResult;
      try {
        descriptionResult = await _geminiService
            .generateFoodDescription(foodLabel)
            .timeout(const Duration(seconds: 8));
      } catch (_) {
        descriptionResult = null;
      }

      _foodInfo = _foodInfo?.copyWith(
        nutritionInfo: nutritionResult,
        description: descriptionResult,
        referenceImageUrl: null,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
