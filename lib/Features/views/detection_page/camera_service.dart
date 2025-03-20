import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraService {
  static final CameraService _instance = CameraService._internal();//The line static final CameraService _instance = CameraService._internal(); ensures only one instance of CameraService exists.
  
  late List<CameraDescription> cameras;//cameras → A list to store available cameras.

 
   bool _isInitialized = false;

//Factory constructor-Instead of creating a new instance every time, it always returns the existing _instance.
  factory CameraService() {//CameraService, which is responsible for handling camera initialization and availability checks.
    return _instance;
  }
  CameraService._internal();//A private named constructor (_internal) ensures that the class instance can only be created inside the class itself.
  Future<void> initializeCameras() async {//cameras → A list to store available cameras.

    if (_isInitialized) return;//_isInitialized → A private flag to check whether cameras have been initialized.
    //If the camera is already initialized, this function exits immediately (prevents duplicate initialization).
    try {
      cameras = await availableCameras();//availableCameras() → Retrieves a list of all cameras available on the device.
      //Yes, availableCameras() is an inbuilt function from the Flutter camera package (package:camera/camera.dart).
      _isInitialized = true;
      debugPrint('Cameras initialized successfully.');

    } catch (e) {
      debugPrint('Error initializing cameras: $e');
      cameras = []; // Fallback to an empty list if initialization fails
      //The camera list is set to an empty list ([]) as a fallback to prevent crashes.
    }
  }
  bool get isCameraAvailable => _isInitialized && cameras.isNotEmpty;//Returns true if a camera is available, otherwise false.
}
