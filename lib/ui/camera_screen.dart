import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:food_recognizer_app/service/lite_rt_service.dart';
import 'package:food_recognizer_app/service/ml_service.dart';
import 'package:provider/provider.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  final LiteRTService _liteRTService = LiteRTService();
  String? _prediction;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    final mlService = context.read<MLService>();
    if (!mlService.isInitialized) {
      print("ML Service not ready, cannot start camera.");
      return;
    }
    await _liteRTService.initialize(mlService.interpreter, mlService.labels);
    await _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_controller != null) {
      if (_controller!.value.isStreamingImages) {
        _controller!.stopImageStream();
      }
      _controller!.dispose();
      _controller = null;
    }
    _liteRTService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (_controller == null) return;

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      if (_controller!.value.isStreamingImages) {
        _controller!.stopImageStream();
      }
      _controller!.dispose();
      _controller = null;
      setState(() => _isCameraInitialized = false);
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      if (_controller != null) {
        if (_controller!.value.isStreamingImages) {
          await _controller!.stopImageStream();
        }
        await _controller!.dispose();
        _controller = null;
      }

      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No cameras available.')),
        );
        return;
      }

      _controller = CameraController(
        _cameras!.first,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();
      if (!mounted) return;

      if (!_controller!.value.isStreamingImages) {
        await _controller!.startImageStream((image) async {
          if (_isProcessing) return;
          setState(() => _isProcessing = true);

          try {
            final result = await _liteRTService.analyzeCameraFrame(image);
            if (!mounted) return;
            if (result != null) {
              setState(() => _prediction = result);
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Analyze error: $e')),
              );
            }
          } finally {
            if (mounted) setState(() => _isProcessing = false);
          }
        });
      }

      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } on CameraException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error [${e.code}]: ${e.description}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing camera: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Feed Analysis')),
      body: _isCameraInitialized
          ? Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(_controller!),
                if (_prediction != null)
                  Positioned(
                    bottom: 32,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _prediction!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
