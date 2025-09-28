import 'package:food_recognizer_app/model/nutrition_info.dart';

class FoodInfo {
  final String label;
  final double confidence;
  final NutritionInfo? nutritionInfo;
  final String? description;
  final String? referenceImageUrl;

  FoodInfo({
    required this.label,
    required this.confidence,
    this.nutritionInfo,
    this.description,
    this.referenceImageUrl,
  });

  FoodInfo copyWith({
    String? label,
    double? confidence,
    NutritionInfo? nutritionInfo,
    String? description,
    String? referenceImageUrl,
  }) {
    return FoodInfo(
      label: label ?? this.label,
      confidence: confidence ?? this.confidence,
      nutritionInfo: nutritionInfo ?? this.nutritionInfo,
      description: description ?? this.description,
      referenceImageUrl: referenceImageUrl ?? this.referenceImageUrl,
    );
  }
}
