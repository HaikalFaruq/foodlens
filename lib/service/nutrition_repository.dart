import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:food_recognizer_app/model/nutrition_info.dart';

class NutritionRepository {
  NutritionRepository._();
  static final NutritionRepository _instance = NutritionRepository._();
  factory NutritionRepository() => _instance;

  Map<String, NutritionInfo> _nutritionData = const {};
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final jsonString = await rootBundle.loadString('assets/data/nutrition_data.json');
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      _nutritionData = {
        for (final item in jsonList)
          ((item as Map<String, dynamic>)['name'] as String).toLowerCase()
              .trim(): NutritionInfo.fromJson(item),
      };
      _isInitialized = true;
      debugPrint("NutritionRepository initialized with ${_nutritionData.length} items.");
    } catch (e) {
      debugPrint("NutritionRepository init failed: $e");
      _nutritionData = const {};
    }
  }

  NutritionInfo? getLocalNutritionInfo(String foodName) {
    if (!_isInitialized) {
      debugPrint("Warning: NutritionRepository not initialized.");
      return null;
    }

    final q = foodName.toLowerCase().trim();

    final direct = _nutritionData[q];
    if (direct != null) return direct;

    for (final entry in _nutritionData.entries) {
      final k = entry.key;
      if (q.contains(k) || k.contains(q)) {
        return entry.value;
      }
    }

    return null;
  }

}