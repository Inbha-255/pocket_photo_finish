// ignore_for_file: avoid_print, use_build_context_synchronously, unused_local_variable, deprecated_member_use

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/constants/colors.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> historyRecords = [];
  int _currentIndex = 2;
  String athleteName = "Unknown Athlete";
  bool _isLoading = true;
  String formatDurationToSecondsMillis(String isoDuration) {
  RegExp regex = RegExp(r'PT(\d+H)?(\d+M)?([\d.]+S)?');
  Match? match = regex.firstMatch(isoDuration);

  if (match == null) return "Invalid Duration";

  int hours = match.group(1) != null
      ? int.parse(match.group(1)!.replaceAll('H', ''))
      : 0;
  int minutes = match.group(2) != null
      ? int.parse(match.group(2)!.replaceAll('M', ''))
      : 0;
  double seconds = match.group(3) != null
      ? double.parse(match.group(3)!.replaceAll('S', ''))
      : 0.0;

  // Convert everything to total milliseconds
  int totalMilliseconds =
      (hours * 3600000) + (minutes * 60000) + (seconds * 1000).round();

  // Extract seconds and milliseconds
  int displaySeconds = totalMilliseconds ~/ 1000;
  int displayMilliseconds = totalMilliseconds % 1000;

  return "$displaySeconds seconds $displayMilliseconds milliseconds";
}


  @override
  void initState() {
    super.initState();
    _fetchHistoryData();
    _loadAthleteName();
    if (Get.arguments != null && Get.arguments is Map<String, dynamic>) {
      setState(() {
        _currentIndex = Get.arguments['index'] ?? 0;
      });
    }
  }

  Future<void> _loadAthleteName() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? athleteData = prefs.getString('selectedAthlete');

    if (athleteData != null) {
      try {
        Map<String, dynamic> athlete = jsonDecode(athleteData);
        setState(() {
          athleteName = athlete['name'] ?? "Unknown Athlete";
        });
      } catch (e) {
        print("❌ Error parsing athlete name: $e");
      }
    } else {
      print("No athlete data found in SharedPreferences.");
    }
  }

  Future<void> _fetchHistoryData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedTokenJson = prefs.getString("auth_token");

    if (storedTokenJson == null || storedTokenJson.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication token missing!')),
      );
      return;
    }

    try {
      Map<String, dynamic> tokenData = jsonDecode(storedTokenJson);
      String authToken = tokenData['token'];

      final response = await http.get(
        Uri.parse("https://api.jslpro.in:4661/getHistory"),
        headers: {
          "Authorization": "Bearer $authToken",
          "Accept": "application/json",
        },
      );

      print("🔹 Response Status Code: ${response.statusCode}");
      print("🔹 Response Body: ${response.body}");

      if (!mounted) return;

      if (response.statusCode == 200) {
        List<dynamic> fetchedData = jsonDecode(response.body);

        if (fetchedData.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No history records found.')),
          );
        }

        setState(() {
          historyRecords = fetchedData.map((record) {
            return {
              "date": DateFormat('dd-MM-yyyy').format(DateTime.parse(
                  record['images']['uploaded_At'] ??
                      DateTime.now().toString())),
              "athlete_name": athleteName, // This comes from SharedPreferences
              "start_time": record['runningData']['start_Time'],
              "finish_time": record['runningData']['finish_Time'],
              "duration": formatDurationToSecondsMillis(record['runningData']['duration']),

              "image": record['images']['images'], // Base64 image
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching history: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load history: $e')),
      );
    }
  }
Uint8List _decodeBase64Image(String base64String) {
  // Remove Base64 prefix if exists
  final RegExp regex = RegExp(r'data:image/[^;]+;base64,');
  base64String = base64String.replaceAll(regex, '');

  try {
    return base64Decode(base64String);
  } catch (e) {
    print("⚠️ Base64 Decode Error: $e");
    return Uint8List(0); // Return an empty list if decoding fails
  }
}



  String _convertTo12HourFormat(String? time) {
    if (time == null || time.isEmpty || time == 'N/A') return "N/A";

    try {
      DateTime dateTime;

      if (time.contains("T")) {
        dateTime = DateTime.parse(time).toLocal();
      } else {
        dateTime = DateFormat("HH:mm:ss.SSS").parse(time);
      }

      return DateFormat("hh:mm:ss a").format(dateTime);
    } catch (e) {
      print("⚠️ Time Format Error: $time - $e");
      return "N/A";
    }
  }

  Future<void> _deleteRecord(int index) async {
    bool confirmDelete = await _showDeleteConfirmationDialog();
    if (confirmDelete) {
      setState(() {
        historyRecords.removeAt(index);
      });
    }
  }

  Future<bool> _showDeleteConfirmationDialog() async {
    return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Confirm Deletion"),
              content:
                  const Text("Are you sure you want to delete this record?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("Delete"),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _navigateToPage(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });

      if (index == 0) {
        Get.offNamed("/home", arguments: {'index': index});
      } else if (index == 1) {
        Get.offNamed("/Athlete", arguments: {'index': index});
      } else if (index == 2) {
        Get.offNamed("/history", arguments: {'index': index});
      }
    }
  }

  void _showFullScreenImage(BuildContext context, String imageBase64) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Center(
            child: Hero(
              tag: 'imageHero',
              child: Image.memory(
                base64Decode(imageBase64),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primaryColor,
        title: const Text("History", style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(10.0),
              child: historyRecords.isEmpty
                  ? const Center(
                      child: Text("No history available",
                          style: TextStyle(color: Colors.white)))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        border: TableBorder.all(color: Colors.grey, width: 1.0),
                        headingRowColor: MaterialStateColor.resolveWith(
                            (states) => const Color.fromARGB(255, 27, 41, 33)),
                        columnSpacing: 20,
                        columns: const [
                          DataColumn(
                              label: Text("SI.No",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white))),
                          DataColumn(
                              label: Text("Date",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white))),
                          DataColumn(
                              label: Text("Athlete Name",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white))),
                          DataColumn(
                              label: Text("Detected Time",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white))),
                          DataColumn(
                              label: Text("Image",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white))),
                          DataColumn(
                              label: Text("Clock Start Time",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white))),
                          DataColumn(
                              label: Text("Clock End Time",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white))),
                          DataColumn(
                              label: Text("Actions",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white))),
                        ],
                        rows: List.generate(historyRecords.length, (index) {
                          final record = historyRecords[index];
                          String date = record['date'] ??
                              DateFormat('dd-MM-yyyy').format(DateTime.now());
                          return DataRow(
                            color: MaterialStateColor.resolveWith(
                                (states) => Colors.white),
                            cells: [
                              DataCell(Text('${index + 1}',
                                  style: TextStyle(color: const Color.fromARGB(255, 63, 25, 25)))),
                              DataCell(Text(record['date'] ?? 'N/A',
                                  style: TextStyle(color: Colors.black))),
                              DataCell(Text(athleteName,
                                  style: TextStyle(color: Colors.black))),
                             DataCell(Text(record['duration']?.toString() ?? 'N/A',
    style: TextStyle(color: Colors.black))),
                              DataCell(
  GestureDetector(
    onTap: () {
      if (record['image'] != null) {
        _showFullScreenImage(context, record['image']);
      }
    },
    child: Hero(
      tag: 'imageHero-$index',
      child: record['image'] != null
          ? Image.memory(
              _decodeBase64Image(record['image']),
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            )
          : const Icon(Icons.image_not_supported, color: Colors.black),
    ),
  ),
),

                              DataCell(Text(
                                  _convertTo12HourFormat(
                                      record['start_time'] ?? 'N/A'),
                                  style: TextStyle(color: Colors.black))),
                              DataCell(Text(
                                  _convertTo12HourFormat(
                                      record['finish_time'] ?? 'N/A'),
                                  style: TextStyle(color: Colors.black))),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _deleteRecord(index),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.primaryColor,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: const Color(0xFF676767),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
        onTap: _navigateToPage,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.timer_outlined),
            label: 'Timer',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups),
            label: 'Athletes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'History',
          ),
        ],
      ),
    );
  }
}
