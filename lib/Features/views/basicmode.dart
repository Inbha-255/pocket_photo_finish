// ignore_for_file: use_build_context_synchronously
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Import Get package for navigation
import 'add_athlete.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BasicModeScreen extends StatefulWidget {
  const BasicModeScreen({super.key});

  @override
  State<BasicModeScreen> createState() => _BasicModeScreenState();
}

class _BasicModeScreenState extends State<BasicModeScreen> {
  Map<String, dynamic>? selectedAthlete;

  @override
  void initState() {
    super.initState();
    _loadSelectedAthlete();
  }

  
 Future<void> _loadSelectedAthlete() async {
    final prefs = await SharedPreferences.getInstance();
    final athleteJson = prefs.getString('selectedAthlete');
    if (athleteJson != null) {
      setState(() {
        selectedAthlete = jsonDecode(athleteJson);
      });
    }
  }

  // Navigate to AddAthletePage and get the selected athlete
  void _navigateToSelectAthlete() async {
    final athlete = await Get.to(() => const AddAthletePage());

    if (athlete != null && athlete is Map<String, dynamic>) {
      setState(() {
        selectedAthlete = athlete;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedAthlete', jsonEncode(athlete));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 26, 25, 25),
        title: const Text(
          "Basic Mode",
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          onPressed: () {
            Get.offNamed('/home');
          },
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            color: Colors.white,
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Basic Mode'),
                    content: const Text(
                        "In Basic Mode, the session begins when the 'Manual Start' button is clicked. "
                        "It starts recording time and ends automatically upon detecting the athlete's motion. "
                        "\nNote: The camera must remain fixed and steady without any movement."),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Get.back();
                        },
                        child: const Text("OK"),
                      ),
                    ],
                  );
                },
              );
            },
            icon: const Icon(Icons.help),
          ),
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Text(
                          "Athlete",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Athlete'),
                                content: const Text(
                                  "Athletes are assigned lap times to track individual performance during a session "
                                  "and review it later in the history. "
                                  "In Basic Mode, you can focus on timing just one athlete, keeping it simple and streamlined.",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Get.back();
                                    },
                                    child: const Text("OK"),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        icon: const Icon(Icons.help),
                      ),
                    ],
                  ),

                  if (selectedAthlete != null)
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 15,
                            backgroundColor: const Color.fromARGB(255, 10, 0, 0),
                            child: Text(
                              selectedAthlete!["number"].toString(),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            selectedAthlete!["name"] ?? 'Unknown Athlete',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: ElevatedButton(
                      onPressed: _navigateToSelectAthlete,
                      style: ElevatedButton.styleFrom(
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        backgroundColor: const Color.fromARGB(255, 14, 0, 0),
                      ),
                      child: Text(
                        selectedAthlete != null
                            ? 'Change Athlete'
                            : 'Add Athlete',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () async {
                  if (selectedAthlete != null) {
                    final SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    await prefs.setString('selectedAthlete', jsonEncode(selectedAthlete));

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Session started for ${selectedAthlete!["name"] ?? 'Unknown Athlete'}',
                        ),
                      ),
                    );
                    Get.offNamed('/stopwatch');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select an athlete first!')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 47, 53, 68),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0),
                  ),
                ),
                child: const Text(
                  "START SESSION",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
