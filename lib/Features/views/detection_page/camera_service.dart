import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraService {
  static final CameraService _instance = CameraService._internal();
  late List<CameraDescription> cameras;

  factory CameraService() {
    return _instance;
  }
  CameraService._internal();
  Future<void> initializeCameras() async {
    try {
      cameras = await availableCameras();
    } catch (e) {
      debugPrint('Error initializing cameras: $e');
      cameras = []; // Fallback to an empty list if initialization fails
    }
  }
}
