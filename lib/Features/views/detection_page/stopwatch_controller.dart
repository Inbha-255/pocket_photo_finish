import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';// Used to lock screen orientation.
import 'package:get/get.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:intl/intl.dart';//Used to format timestamps
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';//Text-to-speech package (for the "On your marks, Get set, Go!" countdown).
import '../add_athlete.dart';
import 'dtetected_page.dart';
import 'dart:math';

class StopwatchScreen extends StatelessWidget {
  final List<CameraDescription> cameras;

  const StopwatchScreen({super.key, required this.cameras});//required this.cameras → This means cameras must be provided when creating StopwatchScreen.

  @override
  Widget build(BuildContext context) {
    final StopwatchController controller =
        Get.put(StopwatchController(cameras: cameras));//After calling Get.put(), 
        //you can access the same controller anywhere in your app using: final controller = Get.find<StopwatchController>();
    double screenHeight = MediaQuery.of(context).size.height;//screen height
    double lineHeight = min(screenHeight * 0.65, screenHeight * 0.8);//motion detection line height
    return SafeArea(//SafeArea → Ensures UI stays within safe screen areas (avoiding notches), automatically adds padding
      child: Scaffold(
        body: Stack(
          children: [
            // Full-Screen Camera Preview
            //GetBuilder<StopwatchController> → Listens for changes in the controller.
            GetBuilder<StopwatchController>(
              builder: (controller) {
                if (controller.cameraController.value.isInitialized) {//Checks if the camera is ready (cameraController.value.isInitialized).

                  final previewSize =
                      controller.cameraController.value.previewSize!;//previewSize → Gets the camera preview dimensions.
                  final screenSize = MediaQuery.of(context).size;
                  final previewAspectRatio =
                      previewSize.height / previewSize.width;//previewAspectRatio → Aspect ratio of the camera preview.
                  final screenAspectRatio =
                      screenSize.width / screenSize.height;//screenAspectRatio → Aspect ratio of the phone screen

                  return Transform.rotate(
                    angle: Platform.isAndroid ? 3.1416 / 2 : 0,//handle this line with XXXcaution!!!XXX//Rotates the camera preview on Android because some devices display it sideways.
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
                            child: CameraPreview(controller.cameraController),//Displays the camera feed on the screen.
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
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () {
                  Get.to(() => AddAthletePage()); // Navigate to Add Athlete Page
                },
              ),
            ),

            // **Full-Screen Vertical Line (Green -> Red on Motion)**
            Positioned(
              top: 0,
              left: MediaQuery.of(context).size.width / 2 - 2,
              right: MediaQuery.of(context).size.width / 2 - 2,
              child: Align(
                alignment: Alignment.center,
                child: Obx(() => Container(
                      width: 2,
                      height: lineHeight, // Ensures full-screen coverage
                      color: controller.isMotionDetected.value
                          ? Colors.red
                          : Colors.green,
                    )),
              ),
            ),
            // Stopwatch and Buttons
            Positioned(
              bottom: 0,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Obx(() => Text(//Obx() → Listens for elapsedTime changes.
                        'Stopwatch time: ${controller.elapsedTime.value}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                        ),
                      )),
                  const SizedBox(height: 16),
                  Obx(() => ElevatedButton(
                        onPressed: controller.isRecording.value
                            ? null
                            : controller.startRecording,
                        child: const Text('Click to Start'),
                      )),
                  Obx(() => controller.isRecording.value
                      ? ElevatedButton(
                          onPressed: controller.stopRecording,
                          child: const Text('Stop Recording'),
                        )
                      : const SizedBox.shrink()),
                  ElevatedButton(
                    onPressed: controller.resetStopwatch,
                    child: const Text('Reset'),
                  ),
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
  late CameraController cameraController;//Manages the camera preview & picture capturing.It will be initialized later using initializeCamera().
  late PoseDetector poseDetector;//Uses Google ML Kit to detect motion (body movement) from camera images.
  final stopwatch = Stopwatch();//A Dart built-in Stopwatch to track time from motion start to stop.
  final isRecording = false.obs;//isRecording → true when the stopwatch is running.
  final elapsedTime = '00.00'.obs;//elapsedTime → Holds the stopwatch's formatted time.
  DateTime? startTime;//Stores the start time of the stopwatch.
  DateTime? endTime;//Stores the end time of the stopwatch.
  final isMotionDetected = false.obs; // Track motion detection status .isMotionDetected → true when motion is detected.
  final AudioPlayer audioPlayer = AudioPlayer(); // Audio player for sound
  final FlutterTts flutterTts = FlutterTts(); // Text-to-speech instance

  StopwatchController({required this.cameras});

  @override
  void onInit() {
    super.onInit();
    initializeCamera();//calls initializeCamera() to start the camera.
    poseDetector = PoseDetector(options: PoseDetectorOptions());//Creates a Pose Detector for motion tracking.
  }

  Future<void> initializeCamera() async {
    cameraController = CameraController(
      cameras.first,//Chooses the first available camera (cameras.first).
      ResolutionPreset.high,//for good quality pic
      enableAudio: false,//audio recording disabled
    );

    await cameraController.initialize();
    await cameraController.lockCaptureOrientation(DeviceOrientation.portraitUp);//Locks the screen orientation to portrait.
    update();//update() is a method from GetxController (part of GetX).
    //It tells the UI to refresh when a variable changes
    //This is useful for updating the UI without using setState().
  }

  Future<void> startRecording() async {
    if (!cameraController.value.isInitialized) return;
    isRecording.value = true;
    isMotionDetected.value = false;////Effect: Ensures that the motion detection logic starts fresh every time recording begins.
    await _playCountdown();// Play "On your marks, get set, go!" before starting
    startTime = DateTime.now();//Stores the start time.
    stopwatch.start();//start stopwatch
    _updateElapsedTime();//Begins updating the elapsed time.
    _detectMotion();//Starts motion detection.
  }

  Future<void> _playCountdown() async {//
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
    //isMotionDetected.value = false;-->If a new recording starts, we don’t want the previous motion detection state to carry over.
  //By setting it to false, the system waits for new motion detection in the next recording session.
    isMotionDetected.value = false;//Effect: Prevents false positives where motion might be mistakenly detected from a previous session
    stopwatch.reset();
    update();
  }

  void _updateElapsedTime() {//The _updateElapsedTime() function is responsible for continuously updating the stopwatch's displayed time while recording is in progress.

    
    if (isRecording.value) {//If recording has stopped, this function exits and stops updating time.isRecording.value is true when the stopwatch is running
      Future.delayed(const Duration(milliseconds: 50), () {//It updates the elapsedTime variable every 50 milliseconds (ms).
                                               //why 50 ms ??? Human eyes can perceive delays above 100ms, so 50ms gives a smoother update.
        if (isRecording.value) {//Checks again if isRecording is still true.
                                //If the user stopped the recording during the delay, it prevents unnecessary updates.
          final elapsed = stopwatch.elapsed;//elapsed is a Duration object, which contains time in seconds & milliseconds.
          elapsedTime.value =
              '${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}.'//Formats Seconds → (elapsed.inSeconds % 60).toString().padLeft(2, '0')elapsed.inSeconds % 60 → Extracts seconds (e.g., 12 from 00:00:12)..toString().padLeft(2, '0') → Ensures two digits (e.g., 08 instead of 8).

              '${((elapsed.inMilliseconds % 1000) ~/ 10).toString().padLeft(2, '0')}';//elapsed.inMilliseconds % 1000 → Extracts milliseconds.
              //~/ 10 → Converts milliseconds to two-digit format. eg 350ms → 35
          _updateElapsedTime();
        }
      });
    }
  }

  void resetStopwatch() {
    stopwatch.reset();
    elapsedTime.value = '00.00';
    update();
  }

  Future<void> _detectMotion() async {//continuously checks for motion using the camera and Google ML Kit’s Pose Detector while the stopwatch is running.
      //Why use a while loop?
      //It keeps checking for motion until recording stops.
      //If motion is detected, the function exits early using return.


    while (isRecording.value && cameraController.value.isInitialized) {//isRecording.value == true → The stopwatch is running.cameraController.value.isInitialized == true → The camera is ready.
      try {
        final image = await cameraController.takePicture();//Captures a picture from the camera every loop cycle.
                                                          //Why take a picture instead of live video?
                                                         //Google ML Kit works best with still images.
                                                        //Processing images is faster & more efficient than live video.
        final inputImage = InputImage.fromFilePath(image.path);//The camera takes a JPEG or PNG file, but ML Kit needs a special InputImage format.
                                                              //final inputImage = InputImage.fromFilePath(image.path);---->Converts the captured image into a format that Google ML Kit can process.
        final poses = await poseDetector.processImage(inputImage);

        if (poses.isNotEmpty) {//Uses ML Kit's poseDetector to analyze the image and find human body landmarks (like hands, legs, etc.).
          isMotionDetected.value = true;//Checks if any body parts are detected.
                                        //If motion is found, isMotionDetected.value is set to true, changing the UI.
          await _playSound();//Calls _playSound(), which plays an alert sound.

          final elapsed = elapsedTime.value;//Stops the stopwatch & resets everything once motion is detected.
                                            //Stores the elapsed time before stopping.
          stopRecording();

          String formattedStartTime = _formatTimestamp(startTime);//Formats the start & end times into a readable string (HH:mm:ss.SSS format).
                                                                  //Uses _formatTimestamp(), which applies date formatting.

          String formattedEndTime = _formatTimestamp(endTime);

          double detectedX =//This line finds the X-position of the athlete’s motion using the left ankle first, then the right ankle, and defaults to the screen center if both are missing
              poses.first.landmarks[PoseLandmarkType.leftAnkle]?.x ??//Gets left ankle X-position (if available).
                  poses.first.landmarks[PoseLandmarkType.rightAnkle]?.x ??//If left ankle is missing, uses right ankle X-position.
                  MediaQuery.of(Get.context!).size.width / 2;//If both are missing, defaults to screen center.

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
