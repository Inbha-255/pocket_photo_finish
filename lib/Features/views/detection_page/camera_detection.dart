import 'package:flutter/material.dart';
import 'package:flutter_application_1/Features/views/detection_page/stopwatch_controller.dart';
import 'camera_service.dart';

class StopwatchScreenApp extends StatelessWidget {
  const StopwatchScreenApp({super.key});

  @override
  Widget build(BuildContext context) {
    final cameras = CameraService().cameras; // Access cameras from CameraService

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StopwatchScreen(cameras: cameras),
    );
  }
}

