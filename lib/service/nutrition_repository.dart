import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:food_recognizer_app/model/nutrition_info.dart';

class NutritionRepository {
  late final Map<String, NutritionInfo> _nutritionData;
  bool _isInitialized = false;

  NutritionRepository._();

  static final NutritionRepository _instance = NutritionRepository._();

  factory NutritionRepository() {
    return _instance;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/nutrition_data.json',
      );
      final List<dynamic> jsonList = json.decode(jsonString);

      _nutritionData = {
        for (var item in jsonList)
          (item['name'] as String).toLowerCase(): NutritionInfo.fromJson(item),
      };

      _isInitialized = true;
      print("NutritionRepository: Successfully initialized with local data.");
    } catch (e) {
      print("NutritionRepository: Failed to load local nutrition data - $e");
      _nutritionData = {};
    }
  }

  NutritionInfo? getLocalNutritionInfo(String foodName) {
    if (!_isInitialized) {
      print("Warning: NutritionRepository not initialized.");
      return null;
    }
    final normalizedName = foodName.toLowerCase();
    return _nutritionData[normalizedName];
  }
}
