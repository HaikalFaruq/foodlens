
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:food_recognizer_app/controller/photo_picker_controller.dart';
import 'package:food_recognizer_app/firebase_options.dart';
import 'package:food_recognizer_app/service/gemini_service.dart';
import 'package:food_recognizer_app/service/ml_service.dart';
import 'package:food_recognizer_app/service/nutrition_service.dart';
import 'package:food_recognizer_app/ui/camera_screen.dart';
import 'package:food_recognizer_app/ui/photo_picker_screen.dart';
import 'package:food_recognizer_app/ui/result_screen.dart';
import 'package:food_recognizer_app/ui/route/navigation_args.dart';
import 'package:food_recognizer_app/ui/route/navigation_route.dart';
import 'package:food_recognizer_app/ui/theme/app_theme.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final mlService = MLService();
  final geminiService = GeminiService();
  final nutritionRepo = NutritionService();

  try {
    await Future.wait([
      mlService.initialize(),
      nutritionRepo.initialize(),
    ]);
  } catch (e) {
    debugPrint('App init failed: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<MLService>.value(value: mlService),
        Provider<GeminiService>.value(value: geminiService),
        Provider<NutritionService>.value(value: nutritionRepo),
        ChangeNotifierProvider(
          create: (_) => PhotoPickerController(mlService: mlService),
          lazy: false,
        ),
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
      themeMode: ThemeMode.system,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: NavigationRoute.mainRoute.name,
      routes: {
        NavigationRoute.mainRoute.name: (context) => const PhotoPickerScreen(),
        NavigationRoute.cameraRoute.name: (context) => CameraScreen(),
        NavigationRoute.analyzeRoute.name: (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments as ResultPageArgs;
          return ResultScreen(
            image: args.image,
            analysisResult: args.analysisResult,
          );
        },
      },
    );
  }
}
