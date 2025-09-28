import 'dart:io';

import 'package:flutter/material.dart';
import 'package:food_recognizer_app/controller/photo_picker_controller.dart';
import 'package:food_recognizer_app/ui/route/navigation_route.dart';
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
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<PhotoPickerController>().initialize(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PhotoPickerController>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Recognizer'),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
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
    }
    return const _ImagePlaceholder();
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
      child: Image.file(
        image,
        fit: BoxFit.cover,
        height: 300,
        width: double.infinity,
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    final controller = context.read<PhotoPickerController>();
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => controller.showImageSourceDialog(context),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          height: 300,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt, size: 60, color: scheme.secondary),
              const SizedBox(height: 16),
              Text(
                "Tap to select an image",
                style: Theme.of(context).textTheme.titleMedium,
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
    final scheme = Theme.of(context).colorScheme;

    if (controller.serviceError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            controller.serviceError!,
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.error, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: controller.isLoading
                ? null
                : () => context
                .read<PhotoPickerController>()
                .showImageSourceDialog(context),
            child: const Text('Pick another image'),
          ),
        ],
      );
    }

    if (controller.image != null && controller.analysisResult == null) {
      return Column(
        children: [
          const _ActionButtons(),
          if (controller.postAnalyze) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: controller.isLoading
                  ? null
                  : () => context
                  .read<PhotoPickerController>()
                  .showImageSourceDialog(context),
              child: const Text('Pick another image'),
            ),
          ],
        ],
      );
    }

    if (controller.image == null) {
      return const _PickerButtons();
    }

    return Column(
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.insights),
          label: const Text('View Analysis Detail'),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Result already generated.')),
            );
          },
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: controller.isLoading
              ? null
              : () => context
              .read<PhotoPickerController>()
              .showImageSourceDialog(context),
          child: const Text('Pick another image'),
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PhotoPickerController>();

    return Column(
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.crop),
          label: const Text('Crop'),
          onPressed: controller.isLoading
              ? null
              : () => context.read<PhotoPickerController>().cropImage(context),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.science),
          label: const Text('Analyze'),
          onPressed: controller.isLoading
              ? null
              : () =>
                  context.read<PhotoPickerController>().analyzeImage(context),
        ),
      ],
    );
  }
}

class _PickerButtons extends StatelessWidget {
  const _PickerButtons();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PhotoPickerController>();
    return Column(
      children: [
        ElevatedButton(
          onPressed: controller.isLoading
              ? null
              : () => context
                  .read<PhotoPickerController>()
                  .showImageSourceDialog(context),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text('Pick from Gallery/Camera'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: controller.isLoading
              ? null
              : () => Navigator.pushNamed(
                    context,
                    NavigationRoute.cameraRoute.name,
                  ),
          child: const Text('Or use Live Camera Feed'),
        ),
      ],
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
