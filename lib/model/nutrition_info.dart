class NutritionInfo {
  final String name;
  final double calories;
  final double fat;
  final double carbs;
  final double protein;
  final double fiber;

  NutritionInfo({
    required this.name,
    required this.calories,
    required this.fat,
    required this.carbs,
    required this.protein,
    required this.fiber,
  });

  factory NutritionInfo.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value is int) {
        return value.toDouble();
      } else if (value is double) {
        return value;
      }
      return 0.0;
    }

    return NutritionInfo(
      name: json['name'] ?? 'N/A',
      calories: parseDouble(json['calories']),
      fat: parseDouble(json['fat_total_g']),
      carbs: parseDouble(json['carbohydrates_total_g']),
      protein: parseDouble(json['protein_g']),
      fiber: parseDouble(json['fiber_g']),
    );
  }

  factory NutritionInfo.notFound(String foodName) {
    return NutritionInfo(
      name: '$foodName (Not Found)',
      calories: 0,
      fat: 0,
      carbs: 0,
      protein: 0,
      fiber: 0,
    );
  }
}
