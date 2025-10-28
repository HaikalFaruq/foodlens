import 'dart:io';
import 'dart:isolate';

import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

import '../../model/analysis_result.dart';

class MLService {
  late tfl.Interpreter _interpreter;
  late List<String> _labels;
  bool _isInitialized = false;

  tfl.Interpreter get interpreter => _interpreter;

  List<String> get labels => _labels;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Try Firebase first
    try {
      debugPrint("Attempting to load model from Firebase...");
      final model = await FirebaseModelDownloader.instance.getModel(
        "food_model",
        FirebaseModelDownloadType.localModelUpdateInBackground,
        FirebaseModelDownloadConditions(
          iosAllowsCellularAccess: true,
          androidChargingRequired: false,
          androidWifiRequired: false,
          androidDeviceIdleRequired: false,
        ),
      );
      _interpreter = tfl.Interpreter.fromFile(model.file);
      await _loadLabels();
      _isInitialized = true;
      debugPrint("ML Service initialized successfully from Firebase.");
      return;
    } catch (e) {
      debugPrint("Could not load model from Firebase: $e");
      debugPrint("Trying to load from local assets...");
    }

    // Fallback to local assets
    try {
      _interpreter = await tfl.Interpreter.fromAsset('assets/model.tflite');
      await _loadLabels();
      _isInitialized = true;
      debugPrint("ML Service initialized successfully from local assets.");
    } catch (e) {
      debugPrint("FATAL: Could not initialize ML Service from assets either: $e");
      debugPrint("INSTRUCTIONS:");
      debugPrint("1. Upload TFLite model to Firebase Console with name 'food_model', OR");
      debugPrint("2. Place model file at assets/model.tflite and update pubspec.yaml");
    }
  }

  Future<void> _loadLabels() async {
    try {
      final labelsString = await rootBundle.loadString('assets/labelmap.txt');
      _labels = labelsString
          .split('\n')
          .skip(1)
          .map((line) {
            final parts = line.split(',');
            if (parts.length > 1) {
              return parts[1].trim();
            }
            return '';
          })
          .where((label) => label.isNotEmpty)
          .toList();
      debugPrint("ML Service: Successfully loaded ${_labels.length} labels.");
    } catch (e) {
      debugPrint('FATAL: Could not load labels: $e');
      _labels = [];
    }
  }

  Future<AnalysisResult?> analyzeImage(File imageFile) async {
    if (!_isInitialized || _labels.isEmpty) {
      debugPrint("ML Service not ready or labels missing.");
      return null;
    }
    final receivePort = ReceivePort();
    await Isolate.spawn(_inferenceIsolate, [
      receivePort.sendPort,
      imageFile.path,
      _interpreter.address,
      _labels,
    ]);
    final results = await receivePort.first as List<dynamic>;

    if (results.isEmpty || results[0] == 'ERROR') {
      debugPrint(
        "Error from inference isolate: ${results.length > 1 ? results[1] : 'Unknown error'}",
      );
      return null;
    }

    double maxScore = results[1];
    int bestIndex = results[2];

    if (bestIndex == -1) {
      debugPrint("Inference did not find any valid result.");
      return null;
    }

    if (maxScore > 0.3) {
      final result = AnalysisResult(
        label: _labels[bestIndex],
        confidence: maxScore,
      );
      final confidencePercentage = (result.confidence * 100).toStringAsFixed(2);
      debugPrint("Prediction: ${result.label} ($confidencePercentage%)");
      return result;
    }

    final confidencePercentage = (maxScore * 100).toStringAsFixed(2);
    debugPrint(
      "Low Confidence: Best match was ${_labels[bestIndex]} ($confidencePercentage%). Result ignored.",
    );

    return null;
  }

  void dispose() {
    _interpreter.close();
  }
}

void _inferenceIsolate(List<dynamic> args) async {
  SendPort sendPort = args[0];
  try {
    final imagePath = args[1] as String;
    final interpreterAddress = args[2] as int;
    final labels = args[3] as List<String>;

    final interpreter = tfl.Interpreter.fromAddress(interpreterAddress);
    final imageFile = File(imagePath);

    final image = img.decodeImage(imageFile.readAsBytesSync())!;
    final inputTensor = interpreter.getInputTensor(0);
    final modelInputSize = inputTensor.shape[1];
    final inputType = inputTensor.type;

    debugPrint("Model input - Shape: ${inputTensor.shape}, Type: $inputType");

    final resizedImage = img.copyResize(
      image,
      width: modelInputSize,
      height: modelInputSize,
    );

    final imageBytes = resizedImage.getBytes();
    
    // Check if model expects normalized float input (0-1) or uint8 (0-255)
    final needsNormalization = inputType == tfl.TensorType.float32;

    var input = needsNormalization
        ? List.generate(
            1,
            (i) => List.generate(
              modelInputSize,
              (j) => List.generate(
                  modelInputSize, (k) => List.generate(3, (l) => 0.0)),
            ),
          )
        : List.generate(
            1,
            (i) => List.generate(
              modelInputSize,
              (j) => List.generate(modelInputSize, (k) => List.generate(3, (l) => 0)),
            ),
          );

    int index = 0;
    for (int i = 0; i < modelInputSize; i++) {
      for (int j = 0; j < modelInputSize; j++) {
        if (needsNormalization) {
          // Normalize to 0-1 range for float32 input
          input[0][i][j][0] = imageBytes[index++] / 255.0;
          input[0][i][j][1] = imageBytes[index++] / 255.0;
          input[0][i][j][2] = imageBytes[index++] / 255.0;
        } else {
          // Keep as uint8 (0-255)
          input[0][i][j][0] = imageBytes[index++];
          input[0][i][j][1] = imageBytes[index++];
          input[0][i][j][2] = imageBytes[index++];
        }
        if (resizedImage.numChannels == 4) {
          index++; // Skip alpha channel
        }
      }
    }

    final outputTensor = interpreter.getOutputTensor(0);
    final outputShape = outputTensor.shape;
    final outputType = outputTensor.type;
    
    debugPrint("Model output - Shape: $outputShape, Type: $outputType");
    
    if (outputShape.length != 2 ||
        outputShape[0] != 1 ||
        outputShape[1] != labels.length) {
      throw Exception(
        'Model output shape $outputShape does not match label count ${labels.length}.',
      );
    }

    // Check if model outputs uint8 (quantized) or float32
    final isQuantized = outputType == tfl.TensorType.uint8;
    
    final output = isQuantized 
        ? List.generate(
            outputShape[0],
            (index) => List<int>.filled(outputShape[1], 0),
          )
        : List.generate(
            outputShape[0],
            (index) => List<double>.filled(outputShape[1], 0.0),
          );

    interpreter.run(input, output);

    // Normalize scores based on output type
    final scores = isQuantized 
        ? (output[0] as List<int>).map((e) => e / 255.0).toList()
        : (output[0] as List<double>).toList();
    
    // Debug: Log top 5 predictions
    final scoreIndexPairs = List.generate(scores.length, (i) => {'index': i, 'score': scores[i]});
    scoreIndexPairs.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
    debugPrint("Top 5 predictions:");
    for (int i = 0; i < 5 && i < scoreIndexPairs.length; i++) {
      final idx = scoreIndexPairs[i]['index'] as int;
      final score = scoreIndexPairs[i]['score'] as double;
      final label = idx < labels.length ? labels[idx] : 'Unknown';
      debugPrint("  ${i + 1}. $label: ${(score * 100).toStringAsFixed(2)}%");
    }

    double maxScore = 0;
    int bestIndex = -1;
    for (int i = 0; i < scores.length; i++) {
      if (scores[i] > maxScore) {
        maxScore = scores[i];
        bestIndex = i;
      }
    }

    Isolate.exit(sendPort, ['SUCCESS', maxScore, bestIndex]);
  } catch (e) {
    Isolate.exit(sendPort, ['ERROR', e.toString()]);
  }
}
