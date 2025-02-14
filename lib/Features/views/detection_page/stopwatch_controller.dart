import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dtetected_page.dart';

class StopwatchScreen extends StatelessWidget {
  final List<CameraDescription> cameras;

  const StopwatchScreen({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    final StopwatchController controller = Get.put(StopwatchController(cameras: cameras));

    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            // Full-Screen Camera Preview
            GetBuilder<StopwatchController>(
              builder: (controller) {
                if (controller.cameraController.value.isInitialized) {
                  final previewSize = controller.cameraController.value.previewSize!;
                  final screenSize = MediaQuery.of(context).size;
                  final previewAspectRatio = previewSize.height / previewSize.width;
                  final screenAspectRatio = screenSize.width / screenSize.height;

                  return Transform.rotate(
                    angle: Platform.isAndroid ? 3.1416 / 2 : 0,
                    child: AspectRatio(
                      aspectRatio: previewAspectRatio,
                      child: OverflowBox(
                        maxWidth: screenAspectRatio > previewAspectRatio
                            ? screenSize.width
                            : screenSize.height * previewAspectRatio,
                        maxHeight: screenAspectRatio > previewAspectRatio
                            ? screenSize.width / previewAspectRatio
                            : screenSize.height,
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: previewSize.width,
                            height: previewSize.height,
                            child: CameraPreview(controller.cameraController),
                          ),
                        ),
                      ),
                    ),
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),

            // **Full-Screen Vertical Line (Green -> Red on Motion)**
            Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: Obx(() => Container(
                      width: 4,
                      height: double.infinity, // Ensures full-screen coverage
                      color: controller.isMotionDetected.value ? Colors.red : Colors.green,
                    )),
              ),
            ),

            // Stopwatch and Buttons
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Obx(() => Text(
                        'Elapsed Time: ${controller.elapsedTime.value}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                        ),
                      )),
                  const SizedBox(height: 16),
                  Obx(() => ElevatedButton(
                        onPressed: controller.isRecording.value ? null : controller.startRecording,
                        child: const Text('Click to Start'),
                      )),
                  Obx(() => controller.isRecording.value
                      ? ElevatedButton(
                          onPressed: controller.stopRecording,
                          child: const Text('Stop Recording'),
                        )
                      : const SizedBox.shrink()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StopwatchController extends GetxController {
  final List<CameraDescription> cameras;
  late CameraController cameraController;
  late PoseDetector poseDetector;
  final stopwatch = Stopwatch();
  final isRecording = false.obs;
  final elapsedTime = '00:00'.obs;
  DateTime? startTime;
  DateTime? endTime;
  final isMotionDetected = false.obs; // Track motion detection status
  final AudioPlayer audioPlayer = AudioPlayer(); // Audio player for sound
  final FlutterTts flutterTts = FlutterTts(); // Text-to-speech instance

  StopwatchController({required this.cameras});

  @override
  void onInit() {
    super.onInit();
    initializeCamera();
    poseDetector = PoseDetector(options: PoseDetectorOptions());
  }

  Future<void> initializeCamera() async {
    cameraController = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await cameraController.initialize();
    await cameraController.lockCaptureOrientation(DeviceOrientation.portraitUp);
    update();
  }

  Future<void> startRecording() async {
    if (!cameraController.value.isInitialized) return;

    isRecording.value = true;
    isMotionDetected.value = false;

    // Play "On your marks, get set, go!" before starting
    await _playCountdown();

    startTime = DateTime.now();
    stopwatch.start();
    _updateElapsedTime();
    _detectMotion();
  }

  Future<void> _playCountdown() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5); // Adjust speech speed if needed

    await flutterTts.speak("On your marks");
    await Future.delayed(Duration(seconds: 1));

    await flutterTts.speak("Get set");
    await Future.delayed(Duration(seconds: 1));

    await flutterTts.speak("Go!");
    await Future.delayed(Duration(seconds: 1));
  }

  void stopRecording() {
    isRecording.value = false;
    stopwatch.stop();
    endTime = DateTime.now();
    isMotionDetected.value = false;
    stopwatch.reset();
    update();
  }

  void _updateElapsedTime() {
    if (isRecording.value) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (isRecording.value) {
          final elapsed = stopwatch.elapsed;
          elapsedTime.value =
              '${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}:' 
              '${((elapsed.inMilliseconds % 1000) ~/ 10).toString().padLeft(2, '0')}';
          _updateElapsedTime();
        }
      });
    }
  }

  Future<void> _detectMotion() async {
    while (isRecording.value && cameraController.value.isInitialized) {
      try {
        final image = await cameraController.takePicture();
        final inputImage = InputImage.fromFilePath(image.path);
        final poses = await poseDetector.processImage(inputImage);

        if (poses.isNotEmpty) {
          isMotionDetected.value = true;
          await _playSound();

          final elapsed = elapsedTime.value;
          stopRecording();

          String formattedStartTime = _formatTimestamp(startTime);
          String formattedEndTime = _formatTimestamp(endTime);

          double detectedX = poses.first.landmarks[PoseLandmarkType.leftAnkle]?.x ??
                             poses.first.landmarks[PoseLandmarkType.rightAnkle]?.x ??
                             MediaQuery.of(Get.context!).size.width / 2;

          Get.to(() => DetectionResultScreen(
                imagePath: image.path,
                elapsedTime: elapsed,
                startTime: formattedStartTime,
                endTime: formattedEndTime,
                detectedPositionX: detectedX,
              ));

          debugPrint('Motion detected! Photo saved.');
          return;
        }
      } catch (e) {
        debugPrint('Error during motion detection: $e');
      }
    }
  }

  Future<void> _playSound() async {
    try {
      await audioPlayer.play(AssetSource('sound/alert.aac'));
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return "N/A";
    return DateFormat('HH:mm:ss.SSS').format(timestamp);
  }

  @override
  void onClose() {
    cameraController.dispose();
    poseDetector.close();
    stopwatch.stop();
    audioPlayer.dispose();
    flutterTts.stop();
    super.onClose();
  }
}
