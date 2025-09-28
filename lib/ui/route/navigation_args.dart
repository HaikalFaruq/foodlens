import 'dart:io';
import 'package:food_recognizer_app/model/analysis_result.dart';

class ResultPageArgs {
  final File image;
  final AnalysisResult analysisResult;

  const ResultPageArgs({
    required this.image,
    required this.analysisResult,
  });
}
