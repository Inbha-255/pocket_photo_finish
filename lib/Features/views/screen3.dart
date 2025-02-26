import 'dart:convert';
import 'dart:io';
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

  @override
  void initState() {
    super.initState();
    _fetchHistoryData();
    if (Get.arguments != null && Get.arguments is Map<String, dynamic>) {
      setState(() {
        _currentIndex = Get.arguments['index'] ?? 0;
      });
    }
  }

  // Fetch history data from API
  Future<void> _fetchHistoryData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("auth_token");
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse("https://api.jslpro.in:4661/getHistory"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json"
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        List<Map<String, dynamic>> fetchedData =
            List<Map<String, dynamic>>.from(jsonDecode(response.body));

        setState(() {
          historyRecords = fetchedData;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching history: ${response.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load history: $e')),
      );
    }
  }

  // Convert 24-hour time to 12-hour format with AM/PM
  String _convertTo12HourFormat(String time) {
    try {
      DateTime dateTime = DateFormat("HH:mm:ss.SSS").parse(time);
      return DateFormat("hh:mm:ss a").format(dateTime);
    } catch (e) {
      return time;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primaryColor,
        // leading: IconButton(
        //   onPressed: () => Get.back(),
        //   icon: const Icon(Icons.arrow_back, color: Colors.white),
        // ),
        title: const Text("History", style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: historyRecords.isEmpty
            ? const Center(child: Text("No history available", style: TextStyle(color: Colors.white)))
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
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                    DataColumn(
                        label: Text("Date",
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                    DataColumn(
                        label: Text("Athlete Name",
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                    DataColumn(
                        label: Text("Detected Time",
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                    DataColumn(
                        label: Text("Image",
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                    DataColumn(
                        label: Text("Clock Start Time",
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                    DataColumn(
                        label: Text("Clock End Time",
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                    DataColumn(
                        label: Text("Actions",
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                  ],
                  rows: List.generate(historyRecords.length, (index) {
                    final record = historyRecords[index];
                    String date = record['date'] ??
                        DateFormat('dd-MM-yyyy').format(DateTime.now());

                    return DataRow(
                      color: MaterialStateColor.resolveWith((states) =>
                          Colors.white),
                      cells: [
                        DataCell(Text('${index + 1}', style: TextStyle(color: Colors.black))),
                        DataCell(Text(date, style: TextStyle(color: Colors.black))),
                        DataCell(Text(record['athleteName'] ?? 'Unknown', style: TextStyle(color: Colors.black))),
                        DataCell(Text(record['time'] ?? 'N/A', style: TextStyle(color: Colors.black))),
                        DataCell(
                          record['imagePath'] != null &&
                                  File(record['imagePath']).existsSync()
                              ? Image.file(
                                  File(record['imagePath']),
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.image_not_supported, color: Colors.black),
                        ),
                        DataCell(Text(_convertTo12HourFormat(
                            record['startTime'] ?? 'N/A'), style: TextStyle(color: Colors.black))),
                        DataCell(Text(_convertTo12HourFormat(
                            record['endTime'] ?? 'N/A'), style: TextStyle(color: Colors.black))),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
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
