import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/routes/routes.dart'; // Your existing routes file
import 'package:get/get_navigation/src/root/get_material_app.dart';
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
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  final cameraService = CameraService();
  await cameraService.initializeCameras(); // Initialize cameras once
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      getPages: approutes(),
    );
  }
}

