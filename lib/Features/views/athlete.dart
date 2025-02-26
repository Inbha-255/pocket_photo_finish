// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../constants/colors.dart';

class SelectAthletePage extends StatefulWidget {
  const SelectAthletePage({super.key});

  @override
  State<SelectAthletePage> createState() => _SelectAthletePageState();
}

class _SelectAthletePageState extends State<SelectAthletePage> {
  final TextEditingController _nameController = TextEditingController();
  int? _selectedNumber;
  late List<int> _availableNumbers;
  List<Map<String, dynamic>> _athletes = [];
  final String apiUrl = "https://api.jslpro.in:4661";
  bool _isMounted = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _fetchAthletes();
    if (Get.arguments != null && Get.arguments is Map<String, dynamic>) {
      setState(() {
        _currentIndex = Get.arguments['index'] ?? 0; // ✅ Default to 0 if null
      });
    }
  }

  @override
  void dispose() {
    _isMounted = false;
    _nameController.dispose();
    super.dispose();
  }

  void _updateAvailableNumbers() {
    final takenNumbers =
        _athletes.map((athlete) => athlete["number"] as int).toSet();
    _availableNumbers = List.generate(999, (index) => index + 1)
        .where((number) => !takenNumbers.contains(number))
        .toList();
  }
  void _navigateToPage(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index; // ✅ Ensures the selected tab updates
      });

      // ✅ Pass `_currentIndex` as an argument to persist tab selection
      if (index == 0) {
        Get.offNamed("/home", arguments: {'index': index});
      } else if (index == 1) {
        Get.offNamed("/Athlete", arguments: {'index': index});
      } else if (index == 2) {
        Get.offNamed("/history", arguments: {'index': index});
      }
    }
  }
Future<void> _addAthlete() async {
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString("auth_token");
  if (token == null) return;

  if (_nameController.text.isEmpty || _selectedNumber == null) return;

  try {
    final response = await http.post(
      Uri.parse(
          "$apiUrl/addAthlete?name=${_nameController.text.trim()}&number=$_selectedNumber"),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json"
      },
    );

    if (response.statusCode == 200) {
      if (_isMounted) {
        setState(() {
          _fetchAthletes(); // Refresh the list without closing the page
        });
      }
    }
  } catch (e) {
    print("Error adding athlete: $e");
  }
}

Future<void> _editAthlete(
    String playerId, String name, int oldNumber, int newNumber) async {
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString("auth_token");
  if (token == null) return;

  try {
    final response = await http.put(
      Uri.parse("$apiUrl/editAthlete/$playerId/$name/$newNumber"),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json"
      },
    );

    if (response.statusCode == 200) {
      if (_isMounted) {
        setState(() {
          _fetchAthletes(); // Refresh the list without closing the page
        });
      }
    }
  } catch (e) {
    print("Error editing athlete: $e");
  }
}
  Future<void> _fetchAthletes() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("auth_token");
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse("$apiUrl/getAthlete"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json"
        },
      );

      if (response.statusCode == 200 && _isMounted) {
        setState(() {
          _athletes = List<Map<String, dynamic>>.from(jsonDecode(response.body));
          _updateAvailableNumbers();
        });
      }
    } catch (e) {
      print("Error fetching athletes: $e");
    }
  }

  Future<void> _deleteAthlete(int number) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("auth_token");
    if (token == null) return;

    try {
      final response = await http.delete(
        Uri.parse("$apiUrl/deleteAthlete/$number"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        _fetchAthletes();
      }
    } catch (e) {
      print("Error deleting athlete: $e");
    }
  }

  void _showCreateAthleteDialog({Map<String, dynamic>? athlete}) async {
    int? previousNumber;
    if (athlete != null) {
      _nameController.text = athlete["name"];
      previousNumber = athlete["number"];
      _selectedNumber = previousNumber;
    } else {
      _nameController.clear();
      _selectedNumber = _availableNumbers.first;
    }

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(athlete == null ? 'Create New Athlete' : 'Edit Athlete'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text("Name  "),
                  Expanded(
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        border: UnderlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('Number:'),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 120,
                      child: CupertinoPicker(
                        itemExtent: 40.0,
                        scrollController: FixedExtentScrollController(
                          initialItem:
                              _availableNumbers.indexOf(_selectedNumber!),
                        ),
                        onSelectedItemChanged: (int index) {
                          if (_isMounted) {
                            setState(() {
                              _selectedNumber = _availableNumbers[index];
                            });
                          }
                        },
                        children: _availableNumbers
                            .map((number) =>
                                Center(child: Text(number.toString())))
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                if (athlete == null) {
                  _addAthlete();
                } else {
                  _editAthlete(
                      athlete["player_Id"],
                      _nameController.text.trim(),
                      previousNumber!,
                      _selectedNumber!);
                }
                if (_isMounted) {
                  setState(() {});
                  _fetchAthletes(); // Refresh the list
                }
                Navigator.of(dialogContext).pop(); // Close the dialog correctly
              },
              child: const Text("Save"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primaryColor,
        title: const Text('Athletes', style: TextStyle(color: Colors.white)),
        // leading: IconButton(
        //   onPressed: () => Get.back(),
        //   icon: const Icon(Icons.arrow_back, color: Colors.white),
        // ),
        actions: [
          Hero(
            tag: "uniqueHeroTag",
            child: IconButton(
              onPressed: () => _showCreateAthleteDialog(),
              icon: const Icon(Icons.person_add, color: Colors.white),
            ),
          ),
        ],
      ),
      body: _athletes.isEmpty
          ? const Center(child: Text('No athletes available'))
          : ListView.builder(
              itemCount: _athletes.length,
              itemBuilder: (context, index) {
                final athlete = _athletes[index];
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(5),
                    tileColor: AppColors.backgroundColor,
                    leading: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(255, 19, 2, 2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${athlete["number"]}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    title: Text(athlete["name"] ?? "Unknown",
                        style: const TextStyle(fontSize: 16)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.black),
                          onPressed: () =>
                              _showCreateAthleteDialog(athlete: athlete),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Color.fromARGB(255, 156, 3, 3)),
                          onPressed: () => _deleteAthlete(athlete["number"]),
                        ),
                      ],
                    ),
                    
                  ),
                );
              },
            ),
            bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.primaryColor,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: const Color(0xFF676767),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
        onTap: _navigateToPage, // ✅ Calls the updated function
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
