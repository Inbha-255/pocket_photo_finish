// ignore_for_file: avoid_print

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;


class DetectionResultScreen extends StatefulWidget {
  final String imagePath;
  final String elapsedTime;
  final String startTime;
  final String endTime;
  final double detectedPositionX; // X-coordinate of detected motion

  const DetectionResultScreen({
    super.key,
    required this.imagePath,
    required this.elapsedTime,
    required this.startTime,
    required this.endTime,
    required this.detectedPositionX,
  });

  @override
  DetectionResultScreenState createState() => DetectionResultScreenState();
}

class DetectionResultScreenState extends State<DetectionResultScreen> {
  String athleteName = "Unknown Athlete"; 
  String todayDate = "";
  String? playerId; 
  int? playerNumber;
  String? timingsId;
  String? imageId;
  String? token;
  String? userUuid;
  @override
  void initState() {
    super.initState();
    _loadAthleteData();
    todayDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
  }

    // Define extractTime inside the class
  String? extractTime(String timeStr) {
  try {
    if (timeStr.isEmpty) return null; // Handle empty values
    print("🔹 Extracting time from input: $timeStr");

    // Remove milliseconds if present (e.g., "10:47:30.033" → "10:47:30")
    if (timeStr.contains(".")) {
      timeStr = timeStr.split(".")[0]; // Extracts only "HH:mm:ss"
    }

    // If input contains date & time (e.g., "2024-02-14T10:47:30"), extract only the time
    if (timeStr.contains("T")) {
      timeStr = timeStr.split("T")[1]; // Extracts "10:47:30"
      if (timeStr.contains(".")) {
        timeStr = timeStr.split(".")[0]; // Ensure milliseconds are removed
      }
      print(" Extracted Time (No Date, No Milliseconds): $timeStr");
      return timeStr;
    }

    // If input is already in HH:mm:ss format, return as is
    if (RegExp(r'^\d{2}:\d{2}:\d{2}$').hasMatch(timeStr)) {
      print("Time is already in correct format: $timeStr");
      return timeStr;
    }

    print("Unknown time format: $timeStr");
    return null;
  } catch (e) {
    print(" Error extracting time: $timeStr - $e");
    return null;
  }
}

  // Load athlete details from SharedPreferences
  Future<void> _loadAthleteData() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String? athleteData = prefs.getString('selectedAthlete');
  String? storedToken = prefs.getString("auth_token"); 

  setState(() {
    token = storedToken;
  });

  if (athleteData != null) {
    Map<String, dynamic> athlete = jsonDecode(athleteData);
    setState(() {
      athleteName = athlete['name'];
      playerId = athlete['player_Id']; //  Use `player_Id` as UUID
      playerNumber = athlete['number'];
      timingsId = playerId; //  Set playerId as UUID
      imageId = playerId;
    });



    print("✅ Loaded Athlete: $athleteName (ID: $playerId, Number: $playerNumber)");
    print("🔹 Retrieved Token: $token");
  }
}
DateTime? safeParseDate(String dateStr) {
    try {
      if (dateStr.isEmpty) return null; // Handle empty date strings
      print("🔹 Trying to parse date: $dateStr");
      return DateFormat("yyyy-MM-ddTHH:mm:ss").parse(dateStr, true); // Handles ISO 8601
    } catch (e) {
      print("❌ Invalid Date Format: $dateStr - Error: $e");
      return null;
    }
  }

  void _showFullScreenImage(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: GestureDetector(
          onTap: () => Navigator.pop(context), // Close on tap
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(0),
              minScale: 0.5,
              maxScale: 3.0,
              child: AspectRatio(
                aspectRatio: MediaQuery.of(context).size.width /
                    MediaQuery.of(context).size.height,
                child: CustomPaint(
                  foregroundPainter: MotionDetectionPainter(
                    detectedPositionX: widget.detectedPositionX,
                  ),
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
void checkTokenExpiry(String token) {
  try {
    List<String> tokenParts = token.split(".");
    if (tokenParts.length != 3) {
      print("❌ Invalid Token Format");
      return;
    }

    String payload = utf8.decode(base64Url.decode(base64Url.normalize(tokenParts[1])));
    Map<String, dynamic> payloadData = jsonDecode(payload);

    int? expTime = payloadData["exp"];
    if (expTime == null) {
      print("❌ Token has no expiry field!");
      return;
    }

    DateTime expiryDate = DateTime.fromMillisecondsSinceEpoch(expTime * 1000);
    print("🔹 Token Expiry: $expiryDate");

    if (expiryDate.isBefore(DateTime.now())) {
      print("❌ Token has expired!");
    } else {
      print("✅ Token is valid.");
    }
  } catch (e) {
    print("❌ Error decoding token: $e");
  }
}
Future<void> _saveDetectionData() async {
    if (!mounted) return; // ✅ Ensure widget is still in the tree before running
    if (playerId == null || playerNumber == null) {
      _showSnackbar('No athlete selected!');
      return;
    }

    if (token == null || token!.isEmpty) {
      _showSnackbar('Authentication token missing!');
      return;
    }

    print("🔹 Stored Player ID (UUID) from SharedPreferences: $playerId");
    print("🔹 Token Before Sending API Request: $token");

    File imageFile = File(widget.imagePath);
    List<int> imageBytes = await imageFile.readAsBytes();

    // ✅ Use safe parsing for times
    String? startTime = extractTime(widget.startTime);
    String? endTime = extractTime(widget.endTime);

    if (startTime == null || endTime == null) {
      _showSnackbar('Invalid time format detected!');
      return;
    }

    // ✅ Debugging check: Ensure only HH:mm:ss is stored
    print("✅ Final Start Time (Only Time): $startTime");
    print("✅ Final End Time (Only Time): $endTime");

    // ✅ Prepare JSON structure without image details
    Map<String, dynamic> requestBody = {
      "runningData": {
        "player_Id": playerId,
        "session_Info": "Go",
        "start_Time": startTime,
        "finish_Time": endTime
      }
    };

    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("https://api.jslpro.in:4661/capture"),
      );

      // ✅ Attach the image file separately
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: path.basename(imageFile.path),
      ));

      // ✅ Attach JSON payload
      request.fields['runningData'] = jsonEncode(requestBody);

      // ✅ Set Headers
      request.headers["Authorization"] = "Bearer $token";
      request.headers["Accept"] = "application/json";
      request.headers["Content-Type"] = "multipart/form-data"; 

      var response = await request.send();

      if (!mounted) return; // ✅ Ensure widget is still in the tree

      if (response.statusCode == 200) {
        _showSnackbar('Data saved successfully!');
        print("✅ Image uploaded successfully!");
      } else {
        _showSnackbar('Error ❌ API Error: ${response.statusCode}');
        print("❌ Failed to upload image. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error making API request: $e");
      if (!mounted) return;
      _showSnackbar('Error saving data: $e');
    }
}


  /// ✅ Helper Function to Show Snackbar Safely
  void _showSnackbar(String message) {
    if (!mounted) return; // ✅ Prevents using `context` if the widget was removed
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detection Result'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => _showFullScreenImage(context, widget.imagePath),
                child: Image.file(File(widget.imagePath)),
              ),
              const SizedBox(height: 20),

              Text('Athletes: $athleteName', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
              const SizedBox(height: 10),
              // Text('Player ID (UUID): $playerId', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              // const SizedBox(height: 10),
              Text('Number: $playerNumber', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              ElevatedButton(
                onPressed: () => _saveDetectionData(), 
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// **Motion Detection Painter (Green Line + Dotted White Line)**
class MotionDetectionPainter extends CustomPainter {
  final double detectedPositionX;

  MotionDetectionPainter({required this.detectedPositionX});

  @override
  void paint(Canvas canvas, Size size) {
    Paint solidLinePaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 4;

    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), solidLinePaint);

    Paint dottedLinePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(Offset(detectedPositionX, startY), Offset(detectedPositionX, startY + 5), dottedLinePaint);
      startY += 10;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
