import 'dart:io';

import 'package:flutter/material.dart';
import 'package:food_recognizer_app/controller/result_controller.dart';
import 'package:food_recognizer_app/model/analysis_result.dart';
import 'package:food_recognizer_app/model/food_info.dart';
import 'package:food_recognizer_app/model/nutrition_info.dart';
import 'package:food_recognizer_app/service/gemini_service.dart';
import 'package:food_recognizer_app/service/nutrition_repository.dart';
import 'package:food_recognizer_app/ui/theme/app_theme.dart';
import 'package:provider/provider.dart';

class ResultScreen extends StatelessWidget {
  final File image;
  final AnalysisResult analysisResult;

  const ResultScreen({
    super.key,
    required this.image,
    required this.analysisResult,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ResultController(
        geminiService: Provider.of<GeminiService>(context, listen: false),
        nutritionRepository: Provider.of<NutritionRepository>(context, listen: false),
      )..fetchFoodDetails(analysisResult.label, analysisResult.confidence),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Analysis Result"),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ImageCard(image: image),
              const SizedBox(height: 16),
              const _ResultView(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageCard extends StatelessWidget {
  const _ImageCard({required this.image});

  final File image;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Image.file(
        image,
        width: double.infinity,
        height: 250,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView();

  @override
  Widget build(BuildContext context) {
    return Consumer<ResultController>(
      builder: (context, controller, child) {
        final foodInfo = controller.foodInfo;
        final isLoading = controller.isLoading && foodInfo?.description == null;

        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (foodInfo == null) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("No information available."),
            ),
          );
        }

        return _ResultCard(foodInfo: foodInfo);
      },
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.foodInfo});

  final FoodInfo foodInfo;

  @override
  Widget build(BuildContext context) {
    final confidencePercentage = (foodInfo.confidence * 100).toStringAsFixed(2);
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    foodInfo.label,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  "$confidencePercentage%",
                  style: textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            if (foodInfo.description != null &&
                foodInfo.description!.isNotEmpty) ...[
              Text("Description", style: textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(foodInfo.description!),
              const Divider(height: 24),
            ],

            // Nutrition Facts Section
            Text("Nutrition Facts", style: textTheme.titleLarge),
            const SizedBox(height: 8),
            _NutritionSection(nutrition: foodInfo.nutritionInfo),
          ],
        ),
      ),
    );
  }
}

class _NutritionSection extends StatelessWidget {
  const _NutritionSection({this.nutrition});

  final NutritionInfo? nutrition;

  @override
  Widget build(BuildContext context) {
    final info = nutrition;
    if (info == null) {
      return const Text(
        "Nutrition information could not be retrieved from the AI service.",
      );
    }
    if (info.name.contains("Not Found")) {
      final cleanName = info.name.replaceAll(" (Not Found)", "");
      return Text("No nutrition information could be found for $cleanName.");
    }

    return Column(
      children: [
        _NutritionRow(
          label: "Calories",
          value: "${info.calories.toStringAsFixed(0)} kcal",
        ),
        _NutritionRow(
          label: "Carbs",
          value: "${info.carbs.toStringAsFixed(1)} g",
        ),
        _NutritionRow(label: "Fat", value: "${info.fat.toStringAsFixed(1)} g"),
        _NutritionRow(
          label: "Protein",
          value: "${info.protein.toStringAsFixed(1)} g",
        ),
        _NutritionRow(
          label: "Fiber",
          value: "${info.fiber.toStringAsFixed(1)} g",
        ),
      ],
    );
  }
}

class _NutritionRow extends StatelessWidget {
  const _NutritionRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: textTheme.bodyLarge),
          Text(
            value,
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
