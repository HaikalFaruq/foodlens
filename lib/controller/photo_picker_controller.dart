import 'dart:io';

import 'package:flutter/material.dart';
import 'package:food_recognizer_app/model/analysis_result.dart';
import 'package:food_recognizer_app/service/image_service.dart';
import 'package:food_recognizer_app/service/ml_service.dart';
import 'package:food_recognizer_app/ui/camera_screen.dart';
import 'package:food_recognizer_app/ui/result_screen.dart';
import 'package:image_picker/image_picker.dart';

class PhotoPickerController extends ChangeNotifier {
  final ImageService _imageService = ImageService();
  final MLService _mlService;

  PhotoPickerController({required MLService mlService})
    : _mlService = mlService;

  File? _image;

  File? get image => _image;

  AnalysisResult? _analysisResult;

  AnalysisResult? get analysisResult => _analysisResult;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  String? _serviceError;

  String? get serviceError => _serviceError;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _resetState() {
    _analysisResult = null;
    _serviceError = null;
  }

  Future<void> pickImage(ImageSource source) async {
    _setLoading(true);
    _resetState();
    final file = await _imageService.pickImage(source);
    if (file != null) {
      _image = file;
    }
    _setLoading(false);
  }

  Future<void> cropImage(BuildContext context) async {
    if (_image == null) return;
    _setLoading(true);
    _resetState();
    final file = await _imageService.cropImage(_image!);
    if (file != null) {
      _image = file;
    }
    _setLoading(false);
  }

  Future<void> analyzeImage(BuildContext context) async {
    if (_image == null) {
      _serviceError = 'Pilih gambar dulu.';
      notifyListeners();
      return;
    }
    _setLoading(true);
    try {
      _analysisResult = await _mlService.analyzeImage(_image!);
    } catch (e) {
      _serviceError = 'Terjadi kesalahan saat analisis: $e';
    } finally {
      _setLoading(false);
    }

    if (_analysisResult != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ResultScreen(image: _image!, analysisResult: _analysisResult!),
        ),
      );
    } else {
      _serviceError =
      'Makanan tidak teridentifikasi. Coba foto lain (pencahayaan jelas, objek memenuhi frame).';
      notifyListeners();
    }
  }

  void initialize(BuildContext context) {
    if (!_mlService.isInitialized) {
      _serviceError =
          'ML Service could not be initialized. Please check your internet connection and restart the app.';
      notifyListeners();
    }
  }

  Future<void> showImageSourceDialog(BuildContext context) async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Image Source"),
        content: const Text("Choose where to get the image from."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Text("Gallery"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Text("Camera"),
          ),
        ],
      ),
    );

    if (source != null) {
      await pickImage(source);
    }
  }

  void navigateToLiveFeed(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CameraScreen()),
    );
  }
}
