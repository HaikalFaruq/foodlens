import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:food_recognizer_app/controller/photo_picker_controller.dart';
import 'package:food_recognizer_app/firebase_options.dart';
import 'package:food_recognizer_app/service/gemini_service.dart';
import 'package:food_recognizer_app/service/ml_service.dart';
import 'package:food_recognizer_app/service/nutrition_repository.dart';
import 'package:food_recognizer_app/ui/photo_picker_screen.dart';
import 'package:food_recognizer_app/ui/theme/app_theme.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final mlService = MLService();
  final geminiService = GeminiService();

  await Future.wait([
    mlService.initialize(),
    NutritionRepository()
        .initialize(),
  ]);

  final photoPickerController = PhotoPickerController(mlService: mlService);

  runApp(
    MultiProvider(
      providers: [
        Provider<MLService>.value(value: mlService),
        Provider<GeminiService>.value(value: geminiService),
        ChangeNotifierProvider.value(value: photoPickerController),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Recognizer App',
      theme: AppTheme.themeData,
      debugShowCheckedModeBanner: false,
      home: const PhotoPickerScreen(),
    );
  }
}