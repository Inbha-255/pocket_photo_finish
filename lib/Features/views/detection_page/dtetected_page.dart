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
      //checks if the timeStr is in the format of "HH:mm:ss" (Hours:Minutes:Seconds).
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
 Future<void> _loadAthleteData() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String? athleteData = prefs.getString('selectedAthlete');
  String? storedToken = prefs.getString("auth_token"); // Ensure consistent key usage

  if (storedToken == null || storedToken.isEmpty) {
    print("❌ No authentication token found!");
  } else {
    print("🔹 Retrieved Token: $storedToken");
    setState(() {
      token = storedToken;
    });
  }

  print("🔹 Athlete Data Loaded: $athleteData");

  if (athleteData == null) {
    print("❌ Athlete data is null! Retrying...");
    await Future.delayed(const Duration(milliseconds: 500));
    return _loadAthleteData();
  }

  try {
    Map<String, dynamic> athlete = jsonDecode(athleteData);

    // Debugging: Print all keys in the athlete map
    print("🔹 Athlete Keys: ${athlete.keys}");

    // Check if player_Id exists and is not null
    if (!athlete.containsKey("player_Id") || athlete["player_Id"] == null) {
      print("❌ Invalid athlete data: Missing or null player_Id");
      _showSnackbar("Invalid athlete data! Please reselect athlete.");
      return;
    }

    // Check if number exists and is not null
    if (!athlete.containsKey("number") || athlete["number"] == null) {
      print("❌ Invalid athlete data: Missing or null number");
      _showSnackbar("Invalid athlete data! Please reselect athlete.");
      return;
    }

    setState(() {
      athleteName = athlete['name'] ?? "Unknown Athlete";
      playerId = athlete['player_Id'];
      playerNumber = athlete['number'];
      timingsId = playerId;
      imageId = playerId;
    });

    print("✅ Loaded Athlete: $playerNumber $athleteName (ID: $playerId)");
  } catch (e) {
    print("❌ Error parsing athlete data: $e");
  }
}
Future<void> _saveDetectionData() async {
  if (!mounted) return;

  if (playerId == null || playerNumber == null) {
    print("🔹 Athlete data missing. Retrying load...");
    await _loadAthleteData();
    if (playerId == null || playerNumber == null) {
      print("❌ Still no athlete selected!");
      _showSnackbar('No athlete selected! Please reselect an athlete.');
      return;
    }
  }

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String? storedToken = prefs.getString("auth_token"); // Retrieve token

  if (storedToken == null || storedToken.isEmpty) {
    print("❌ Authentication token missing!");
    _showSnackbar('Authentication token missing!');
    return;
  }

  try {
    // Parse the stored token JSON
    Map<String, dynamic> storedTokenData = jsonDecode(storedToken);
    String authToken = storedTokenData["token"]; // Extract only the token
    String userId = storedTokenData["userId"]; // Extract the userId

    print("🔹 Full Token Data: $storedToken");
    print("🔹 Extracted Auth Token: $authToken");
    print("🔹 Extracted User ID: $userId");

    File imageFile = File(widget.imagePath);
    List<int> imageBytes = await imageFile.readAsBytes();

    Map<String, dynamic> runningData = {
      "player_Id": playerId,
      "start_Time": DateTime.now().toIso8601String(),
      "finish_Time": DateTime.now().add(Duration(minutes: 5)).toIso8601String(),
      "session_Info": "go",
    };

    var request = http.MultipartRequest(
      "POST",
      Uri.parse("https://api.jslpro.in:4661/capture"),
    );

    request.fields['runningDatajson'] = jsonEncode(runningData);

    request.files.add(http.MultipartFile.fromBytes(
      'image',
      imageBytes,
      filename: path.basename(imageFile.path),
    ));

    request.headers["Authorization"] = "Bearer $authToken"; // ✅ Token used here
    request.headers["Accept"] = "application/json";
    request.headers["Content-Type"] = "multipart/form-data";

    var response = await request.send();

    if (!mounted) return;

    if (response.statusCode == 200) {
      _showSnackbar('Data saved successfully!');
      print("✅ Running Data and Image uploaded successfully!");
    } else {
      print("❌ Failed to upload. Status code: ${response.statusCode}");
      print("❌ Response Body: ${await response.stream.bytesToString()}");
      _showSnackbar('Error uploading data.');
    }
  } catch (e) {
    print("❌ Error making API request: $e");
    _showSnackbar('Unexpected error occurred.');
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

      String payload =
          utf8.decode(base64Url.decode(base64Url.normalize(tokenParts[1])));
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



  /// ✅ Helper Function to Show Snackbar Safely
  void _showSnackbar(String message) {
    if (!mounted) {
      return; // ✅ Prevents using `context` if the widget was removed
    }
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

              Text('Athletes: $athleteName',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue)),
              const SizedBox(height: 10),
              // Text('Player ID (UUID): $playerId', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              // const SizedBox(height: 10),
              Text('Number: $playerNumber',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              // ✅ Display Today's Date & Time
              Text('Date: $todayDate',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
              const SizedBox(height: 10),
              // ✅ Display Run Duration
              Text('Duration: ${widget.elapsedTime} sec',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
              const SizedBox(height: 20),
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
      ..strokeWidth = 2;
    canvas.drawLine(Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height), solidLinePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
