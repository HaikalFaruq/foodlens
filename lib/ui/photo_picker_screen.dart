import 'dart:io';

import 'package:flutter/material.dart';
import 'package:food_recognizer_app/controller/photo_picker_controller.dart';
import 'package:food_recognizer_app/model/analysis_result.dart';
import 'package:food_recognizer_app/ui/camera_screen.dart';
import 'package:food_recognizer_app/ui/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class PhotoPickerScreen extends StatefulWidget {
  const PhotoPickerScreen({super.key});

  @override
  State<PhotoPickerScreen> createState() => _PhotoPickerScreenState();
}

class _PhotoPickerScreenState extends State<PhotoPickerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PhotoPickerController>().initialize(context);
    });
  }

  Future<void> _showImageSourceDialog(BuildContext context) async {
    final controller = context.read<PhotoPickerController>();
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Image Source"),
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
      await controller.pickImage(source);
    }
  }

  void _navigateToLiveFeed(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CameraScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PhotoPickerController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Recognizer'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF0F2F5),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _ScreenContent(),
                const SizedBox(height: 24),
                _BottomSection(controller: controller),
              ],
            ),
          ),
          if (controller.isLoading) const _LoadingOverlay(),
        ],
      ),
    );
  }
}

class _ScreenContent extends StatelessWidget {
  const _ScreenContent();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PhotoPickerController>();
    if (controller.image != null) {
      return _ImagePreview(image: controller.image!);
    } else {
      return const _ImagePlaceholder();
    }
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.image});

  final File image;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Image.file(image, fit: BoxFit.cover, height: 300),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          context.read<PhotoPickerController>().showImageSourceDialog(context),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          height: 300,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt, size: 60, color: Colors.grey[600]),
              const SizedBox(height: 16),
              Text(
                "Tap to select an image",
                style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomSection extends StatelessWidget {
  const _BottomSection({required this.controller});

  final PhotoPickerController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.serviceError != null) {
      return Text(
        controller.serviceError!,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.red, fontSize: 16),
      );
    }
    if (controller.analysisResult != null) {
      return _ResultDisplay(result: controller.analysisResult!);
    }
    if (controller.image != null) {
      return _ActionButtons();
    }
    return const _PickerButtons();
  }
}

class _ActionButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = context.read<PhotoPickerController>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.crop),
          label: const Text('Crop'),
          onPressed: () => controller.cropImage(context),
          style: AppTheme.themeData.elevatedButtonTheme.style,
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.science),
          label: const Text('Analyze'),
          onPressed: () => controller.analyzeImage(context),
          style: AppTheme.themeData.elevatedButtonTheme.style,
        ),
      ],
    );
  }
}

class _PickerButtons extends StatelessWidget {
  const _PickerButtons();

  @override
  Widget build(BuildContext context) {
    final controller = context.read<PhotoPickerController>();
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => controller.showImageSourceDialog(context),
          style: AppTheme.themeData.elevatedButtonTheme.style?.copyWith(
            minimumSize: MaterialStateProperty.all(
              const Size(double.infinity, 50),
            ),
          ),
          child: const Text('Pick from Gallery/Camera'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => controller.navigateToLiveFeed(context),
          child: const Text('Or use Live Camera Feed'),
        ),
      ],
    );
  }
}

class _ResultDisplay extends StatelessWidget {
  const _ResultDisplay({required this.result});

  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final confidence = (result.confidence * 100).toStringAsFixed(2);
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              result.label,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              '$confidence%',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}
