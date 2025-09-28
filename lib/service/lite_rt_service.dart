import 'package:camera/camera.dart';
import 'package:food_recognizer_app/service/isolate_utils.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

class LiteRTService {
  late tfl.Interpreter _interpreter;
  late List<String> _labels;
  late IsolateUtils _isolateUtils;
  bool _isInitialized = false;

  Future<void> initialize(
    tfl.Interpreter interpreter,
    List<String> labels,
  ) async {
    if (_isInitialized) return;
    _isolateUtils = IsolateUtils();
    await _isolateUtils.start();
    _interpreter = interpreter;
    _labels = labels;
    _isInitialized = true;
    print("LiteRTService Initialized.");
  }

  Future<String?> analyzeCameraFrame(CameraImage image) async {
    if (!_isInitialized) return "Service not initialized";
    if (_isolateUtils.isProcessing) return null;

    final isolateData = IsolateData(
      cameraImage: image,
      interpreterAddress: _interpreter.address,
      labels: _labels,
    );

    final result = await _isolateUtils.inference(isolateData);
    return result;
  }

  void dispose() {
    _isolateUtils.stop();
  }
}
