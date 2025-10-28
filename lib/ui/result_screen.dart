import 'dart:io';

import 'package:flutter/material.dart';
import 'package:food_recognizer_app/controller/result_controller.dart';
import 'package:food_recognizer_app/model/analysis_result.dart';
import 'package:food_recognizer_app/model/food_info.dart';
import 'package:food_recognizer_app/model/nutrition_info.dart';
import 'package:food_recognizer_app/service/gemini_service.dart';
import 'package:food_recognizer_app/service/nutrition_service.dart';
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
    final scheme = Theme.of(context).colorScheme;

    return ChangeNotifierProvider(
      create: (_) => ResultController(
        geminiService: Provider.of<GeminiService>(context, listen: false),
        nutritionRepository:
            Provider.of<NutritionService>(context, listen: false),
      )..fetchFoodDetails(analysisResult.label, analysisResult.confidence),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Hasil Analisis"),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          centerTitle: true,
          elevation: 0,
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
        final isLoading = controller.isLoading;

        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (foodInfo == null) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Icon(Icons.info_outline, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    "Informasi tidak tersedia.",
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
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
    final scheme = Theme.of(context).colorScheme;

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
                    color: scheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (foodInfo.description != null &&
                foodInfo.description!.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.description, size: 20, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text("Deskripsi", style: textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                foodInfo.description!,
                style: textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
              const Divider(height: 24),
            ],
            Row(
              children: [
                Icon(Icons.restaurant_menu, size: 20, color: scheme.primary),
                const SizedBox(width: 8),
                Text("Informasi Nutrisi", style: textTheme.titleLarge),
              ],
            ),
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
        "Informasi nutrisi tidak dapat diambil dari layanan AI.",
        style: TextStyle(fontStyle: FontStyle.italic),
      );
    }
    if (info.name.contains("Not Found")) {
      final cleanName = info.name.replaceAll(" (Not Found)", "");
      return Text(
        "Informasi nutrisi untuk $cleanName tidak ditemukan.",
        style: const TextStyle(fontStyle: FontStyle.italic),
      );
    }

    return Column(
      children: [
        _NutritionRow(
          label: "Kalori",
          value: "${info.calories.toStringAsFixed(0)} kkal",
          icon: Icons.local_fire_department,
        ),
        _NutritionRow(
          label: "Karbohidrat",
          value: "${info.carbs.toStringAsFixed(1)} g",
          icon: Icons.grain,
        ),
        _NutritionRow(
          label: "Lemak",
          value: "${info.fat.toStringAsFixed(1)} g",
          icon: Icons.water_drop,
        ),
        _NutritionRow(
          label: "Protein",
          value: "${info.protein.toStringAsFixed(1)} g",
          icon: Icons.egg,
        ),
        _NutritionRow(
          label: "Serat",
          value: "${info.fiber.toStringAsFixed(1)} g",
          icon: Icons.eco,
        ),
      ],
    );
  }
}

class _NutritionRow extends StatelessWidget {
  const _NutritionRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: textTheme.bodyLarge),
          ),
          Text(
            value,
            style: textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: scheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
