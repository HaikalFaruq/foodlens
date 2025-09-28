class NutritionInfo {
  final String name;
  final double calories;
  final double fat;
  final double carbs;
  final double protein;
  final double fiber;

  const NutritionInfo({
    required this.name,
    required this.calories,
    required this.fat,
    required this.carbs,
    required this.protein,
    required this.fiber,
  });

  factory NutritionInfo.fromJson(Map<String, dynamic> json) {
    double _d(dynamic v) => switch (v) { int i => i.toDouble(), double d => d, _ => 0.0 };
    return NutritionInfo(
      name: (json['name'] ?? 'N/A').toString(),
      calories: _d(json['calories']),
      fat: _d(json['fat_total_g']),
      carbs: _d(json['carbohydrates_total_g']),
      protein: _d(json['protein_g']),
      fiber: _d(json['fiber_g']),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'calories': calories,
    'fat_total_g': fat,
    'carbohydrates_total_g': carbs,
    'protein_g': protein,
    'fiber_g': fiber,
  };

  factory NutritionInfo.notFound(String foodName) => NutritionInfo(
    name: '$foodName (Not Found)',
    calories: 0, fat: 0, carbs: 0, protein: 0, fiber: 0,
  );
}
