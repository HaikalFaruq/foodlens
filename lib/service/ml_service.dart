import 'dart:io';
import 'dart:isolate';

import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';
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
    try {
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
    } catch (e) {
      print("FATAL: Could not initialize ML Service from Firebase: $e");
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
      print("ML Service: Successfully loaded ${_labels.length} labels.");
    } catch (e) {
      print('FATAL: Could not load labels: $e');
      _labels = [];
    }
  }

  Future<AnalysisResult?> analyzeImage(File imageFile) async {
    if (!_isInitialized || _labels.isEmpty) {
      print("ML Service not ready or labels missing.");
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
      print(
        "Error from inference isolate: ${results.length > 1 ? results[1] : 'Unknown error'}",
      );
      return null;
    }

    double maxScore = results[1];
    int bestIndex = results[2];

    if (bestIndex == -1) {
      print("Inference did not find any valid result.");
      return null;
    }

    if (maxScore > 0.6) {
      final result = AnalysisResult(
        label: _labels[bestIndex],
        confidence: maxScore,
      );
      final confidencePercentage = (result.confidence * 100).toStringAsFixed(2);
      print("Prediction: ${result.label} ($confidencePercentage%)");
      return result;
    }

    final confidencePercentage = (maxScore * 100).toStringAsFixed(2);
    print(
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
    final modelInputSize = interpreter.getInputTensor(0).shape[1];

    final resizedImage = img.copyResize(
      image,
      width: modelInputSize,
      height: modelInputSize,
    );

    final imageBytes = resizedImage.getBytes();

    var input = List.generate(
      1,
      (i) => List.generate(
        modelInputSize,
        (j) => List.generate(modelInputSize, (k) => List.generate(3, (l) => 0)),
      ),
    );

    int index = 0;
    for (int i = 0; i < modelInputSize; i++) {
      for (int j = 0; j < modelInputSize; j++) {
        input[0][i][j][0] = imageBytes[index++];
        input[0][i][j][1] = imageBytes[index++];
        input[0][i][j][2] = imageBytes[index++];
        if (resizedImage.numChannels == 4) {
          index++;
        }
      }
    }

    final outputShape = interpreter.getOutputTensor(0).shape;
    if (outputShape.length != 2 ||
        outputShape[0] != 1 ||
        outputShape[1] != labels.length) {
      throw Exception(
        'Model output shape $outputShape does not match label count ${labels.length}.',
      );
    }

    final output = List.generate(
      outputShape[0],
      (index) => List<int>.filled(outputShape[1], 0),
    );

    interpreter.run(input, output);

    final scores = output[0].map((e) => e / 255.0).toList();

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
