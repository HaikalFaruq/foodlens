import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:food_recognizer_app/controller/photo_picker_controller.dart';
import 'package:food_recognizer_app/firebase_options.dart';
import 'package:food_recognizer_app/service/gemini_service.dart';
import 'package:food_recognizer_app/service/ml_service.dart';
import 'package:food_recognizer_app/service/nutrition_service.dart';
import 'package:food_recognizer_app/ui/camera_screen.dart';
import 'package:food_recognizer_app/ui/navigation_route.dart';
import 'package:food_recognizer_app/ui/photo_picker_screen.dart';
import 'package:food_recognizer_app/ui/result_screen.dart';
import 'package:food_recognizer_app/ui/route/navigation_args.dart';
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
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/main':
              return MaterialPageRoute(
                builder: (_) => const PhotoPickerScreen(),
                settings: settings,
              );
            case '/camera':
              return MaterialPageRoute(
                builder: (_) => const CameraScreen(),
                settings: settings,
              );
            case '/analyze':
              final args = settings.arguments;
              if (args is ResultPageArgs) {
                return MaterialPageRoute(
                  builder: (_) => ResultScreen(
                    image: args.image,
                    analysisResult: args.analysisResult,
                  ),
                  settings: settings,
                );
              }
              return MaterialPageRoute(
                builder: (_) => const PhotoPickerScreen(),
                settings: settings,
              );
            default:
              return MaterialPageRoute(
                builder: (_) => const PhotoPickerScreen(),
                settings: settings,
              );
          }
        });
  }
}
