import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraService {
  static final CameraService _instance = CameraService._internal();
  late List<CameraDescription> cameras;
  bool _isInitialized = false;

  factory CameraService() {
    return _instance;
  }
  CameraService._internal();
  Future<void> initializeCameras() async {
    if (_isInitialized) return;
    try {
      cameras = await availableCameras();
      _isInitialized = true;
      debugPrint('Cameras initialized successfully.');

    } catch (e) {
      debugPrint('Error initializing cameras: $e');
      cameras = []; // Fallback to an empty list if initialization fails
    }
  }
  bool get isCameraAvailable => _isInitialized && cameras.isNotEmpty;
}
