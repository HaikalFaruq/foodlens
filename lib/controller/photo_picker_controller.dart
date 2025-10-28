import 'dart:io';

import 'package:flutter/material.dart';
import 'package:food_recognizer_app/model/analysis_result.dart';
import 'package:food_recognizer_app/service/image_service.dart';
import 'package:food_recognizer_app/service/ml_service.dart';
import 'package:image_picker/image_picker.dart';

import '../ui/route/navigation_args.dart';
import '../ui/route/navigation_route.dart';

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

  bool _postAnalyze = false;

  bool get postAnalyze => _postAnalyze;

  void _setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }

  void _resetState({bool keepImage = true}) {
    if (!keepImage) _image = null;
    _analysisResult = null;
    _serviceError = null;
    _postAnalyze = false;
    notifyListeners();
  }

  void clearSelection() {
    _resetState(keepImage: false);
  }

  Future<void> pickImage(ImageSource source) async {
    if (_isLoading) return;
    _setLoading(true);
    _resetState(keepImage: false);
    try {
      final file = await _imageService.pickImage(source);
      if (file != null) {
        _image = file;
        notifyListeners();
      }
    } catch (e) {
      _serviceError = 'Gagal memilih gambar: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> cropImage(BuildContext context) async {
    if (_image == null || _isLoading) return;
    _setLoading(true);
    _analysisResult = null;
    _serviceError = null;
    _postAnalyze = false;
    notifyListeners();

    try {
      final file = await _imageService.cropImage(_image!);
      if (file != null) {
        _image = file;
        notifyListeners();
      }
    } catch (e) {
      _serviceError = 'Gagal memotong gambar: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> analyzeImage(BuildContext context) async {
    if (_image == null) {
      _serviceError = 'Pilih gambar dulu.';
      notifyListeners();
      return;
    }
    if (_isLoading) return;

    _setLoading(true);
    _analysisResult = null;
    _serviceError = null;
    notifyListeners();

    try {
      _analysisResult = await _mlService.analyzeImage(_image!);
    } catch (e) {
      _serviceError = 'Terjadi kesalahan saat analisis: $e';
    } finally {
      _setLoading(false);
      notifyListeners();
    }

    if (_image != null && _analysisResult != null && context.mounted) {
      Navigator.pushNamed(
        context,
        NavigationRoute.analyzeRoute.name,
        arguments: ResultPageArgs(
          image: _image!,
          analysisResult: _analysisResult!,
        ),
      );
    } else if (_analysisResult == null) {
      _serviceError =
      'Makanan tidak teridentifikasi. Coba foto lain (pencahayaan jelas, objek memenuhi frame).';
      notifyListeners();
    }
  }


  void initialize(BuildContext context) {
    if (!_mlService.isInitialized) {
      _serviceError =
          'ML Service belum siap. Pastikan model telah diinisialisasi lalu buka ulang aplikasi.';
      notifyListeners();
    }
  }

  Future<void> showImageSourceDialog(BuildContext context) async {
    if (_isLoading) return;
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
}
