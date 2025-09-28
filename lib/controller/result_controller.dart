import 'package:flutter/material.dart';
import 'package:food_recognizer_app/model/food_info.dart';
import 'package:food_recognizer_app/model/nutrition_info.dart';
import 'package:food_recognizer_app/service/gemini_service.dart';
import 'package:food_recognizer_app/service/nutrition_repository.dart';

class ResultController extends ChangeNotifier {
  final GeminiService _geminiService;
  final NutritionRepository _nutritionRepository;

  ResultController({
    required GeminiService geminiService,
    required NutritionRepository nutritionRepository,
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
      _nutritionRepository.getLocalNutritionInfo(foodLabel);

      if (nutritionResult == null) {
        try {
          nutritionResult = await _geminiService
              .getNutritionInfoFromGemini(foodLabel)
              .timeout(const Duration(seconds: 12));
        } catch (_) {
        }
      }

      String? descriptionResult;
      try {
        descriptionResult = await _geminiService
            .generateFoodDescription(foodLabel)
            .timeout(const Duration(seconds: 8));
      } catch (_) {
        descriptionResult = null;
      }

      nutritionResult ??= NutritionInfo.notFound(foodLabel);

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
