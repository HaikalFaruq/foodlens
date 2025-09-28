import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

class IsolateUtils {
  late Isolate _isolate;
  final ReceivePort _receivePort = ReceivePort();
  late SendPort _sendPort;
  bool isProcessing = false;

  Future<void> start() async {
    _isolate = await Isolate.spawn(_inferenceEntryPoint, _receivePort.sendPort);
    _sendPort = await _receivePort.first;
  }

  void stop() {
    _isolate.kill(priority: Isolate.immediate);
  }

  Future<String> inference(IsolateData isolateData) async {
    isProcessing = true;
    final responsePort = ReceivePort();
    _sendPort.send([isolateData, responsePort.sendPort]);
    final results = await responsePort.first;
    isProcessing = false;
    return results;
  }
}

class IsolateData {
  final CameraImage cameraImage;
  final int interpreterAddress;
  final List<String> labels;

  IsolateData({
    required this.cameraImage,
    required this.interpreterAddress,
    required this.labels,
  });
}

void _inferenceEntryPoint(SendPort sendPort) async {
  final port = ReceivePort();
  sendPort.send(port.sendPort);

  await for (final dynamic data in port) {
    final isolateData = data[0] as IsolateData;
    final responsePort = data[1] as SendPort;

    final result = _analyzeFrame(isolateData);
    responsePort.send(result);
  }
}

String _analyzeFrame(IsolateData isolateData) {
  final image = _convertCameraImage(isolateData.cameraImage);
  if (image == null) return "Processing error";

  final interpreter = tfl.Interpreter.fromAddress(
    isolateData.interpreterAddress,
  );

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
      (j) => List.generate(modelInputSize, (k) => List.generate(3, (l) => 0.0)),
    ),
  );

  int index = 0;
  for (int i = 0; i < modelInputSize; i++) {
    for (int j = 0; j < modelInputSize; j++) {
      input[0][i][j][0] = imageBytes[index++] / 255.0;
      input[0][i][j][1] = imageBytes[index++] / 255.0;
      input[0][i][j][2] = imageBytes[index++] / 255.0;
    }
  }

  final List<String> labels = isolateData.labels;
  final output = [List<double>.filled(labels.length, 0)];
  interpreter.run(input, output);

  final scores = output[0];
  double maxScore = 0;
  int bestIndex = 0;
  for (int i = 0; i < scores.length; i++) {
    if (scores[i] > maxScore) {
      maxScore = scores[i];
      bestIndex = i;
    }
  }

  if (maxScore > 0.6) {
    final confidence = (maxScore * 100).toStringAsFixed(2);
    return '${labels[bestIndex]} ($confidence%)';
  }
  return '';
}

img.Image? _convertCameraImage(CameraImage cameraImage) {
  if (cameraImage.format.group == ImageFormatGroup.yuv420) {
    return _convertYUV420(cameraImage);
  } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
    return img.Image.fromBytes(
      width: cameraImage.width,
      height: cameraImage.height,
      bytes: cameraImage.planes[0].bytes.buffer,
      order: img.ChannelOrder.bgra,
    );
  } else {
    return null;
  }
}

img.Image _convertYUV420(CameraImage image) {
  final int width = image.width;
  final int height = image.height;
  final int uvRowStride = image.planes[1].bytesPerRow;
  final int uvPixelStride = image.planes[1].bytesPerPixel!;

  final yuv420image = img.Image(width: width, height: height);

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final int uvIndex =
          uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
      final int index = y * width + x;

      final yp = image.planes[0].bytes[index];
      final up = image.planes[1].bytes[uvIndex];
      final vp = image.planes[2].bytes[uvIndex];

      int r = (yp + vp * 1.402).round();
      int g = (yp - up * 0.344 - vp * 0.714).round();
      int b = (yp + up * 1.772).round();

      yuv420image.setPixelRgba(
        x,
        y,
        r.clamp(0, 255),
        g.clamp(0, 255),
        b.clamp(0, 255),
        255,
      );
    }
  }
  return yuv420image;
}
