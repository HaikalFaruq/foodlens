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
    _controller?.dispose();
    _liteRTService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      if (_controller != null) {
        _initializeCamera();
      }
    } else {
      _controller?.stopImageStream();
      _controller?.dispose();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _controller = CameraController(
          _cameras![0],
          ResolutionPreset.medium,
          enableAudio: false,
        );

        await _controller!.initialize();
        if (!mounted) return;

        _controller!.startImageStream((image) {
          if (_isProcessing) return;
          setState(() => _isProcessing = true);
          _liteRTService.analyzeCameraFrame(image).then((result) {
            if (result != null) {
              setState(() {
                _prediction = result;
              });
            }
            setState(() => _isProcessing = false);
          });
        });

        setState(() {
          _isCameraInitialized = true;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No cameras available.')),
          );
        }
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
                          color: Colors.black.withOpacity(0.6),
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
