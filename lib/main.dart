import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/routes/routes.dart'; // Your existing routes file
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Features/views/detection_page/camera_service.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  // ✅ Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString("auth_token");
  int? expiryTime = prefs.getInt("token_expiry");

  String initialRoute = "/login"; // Default route

  if (token != null && expiryTime != null) {
    int currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (currentTime < expiryTime) {
      initialRoute = "/home"; // ✅ Token valid → Go to home
    } else {
      prefs.remove("auth_token"); // Remove expired token
      prefs.remove("token_expiry");
    }
  }

  // ✅ Initialize Camera Service
  final cameraService = CameraService();
  await cameraService.initializeCameras(); // Initialize cameras once

  if (!cameraService.isCameraAvailable) {
    debugPrint('⚠️ No cameras detected. Exiting app.');
    return;
  }

  // ✅ Start the app only once
  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      getPages: approutes(),
    );
  }
}
