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
  Map<String, dynamic>? selectedAthlete;
  final String apiUrl = "https://api.jslpro.in:4661";
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _availableNumbers = []; // Initialize it as an empty list
    if (Get.arguments?['clearAthleteData'] == true) {
      _athletes.clear();
      _nameController.clear();
      _clearStoredAthlete();
      _selectedNumber = null;
    }
    _isMounted = true;
    _initializeAthlete();
  }

  @override
  void dispose() {
    _isMounted = false;
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _clearStoredAthlete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selectedAthlete');
  }

 Future<void> _initializeAthlete() async {
  final prefs = await SharedPreferences.getInstance();
  
  // Get the token string from SharedPreferences.
  String? token = prefs.getString("auth_token");
  if (token == null) {
    print("Error: No token found");
    return;
  }

  // Decode the token (which is a JSON string containing both the actual JWT and the userId).
  Map<String, dynamic> tokenData = jsonDecode(token);
  
  // Extract the userId from the token data and use it as the player's UUID.
  String? userIdFromToken = tokenData["userId"];
  if (userIdFromToken == null) {
    print("Error: userId not found in token");
    return;
  }
  String userUuid = userIdFromToken;

  // Extract the actual JWT so that we can check its expiry.
  String? actualJWT = tokenData["token"];
  if (actualJWT == null) {
    print("Error: Actual JWT not found in token data");
    return;
  }

  // Validate the token expiry.
  try {
    Map<String, dynamic> decodedToken = jsonDecode(
      utf8.decode(base64.decode(base64.normalize(actualJWT.split(".")[1])))
    );
    int expiryTime = decodedToken["exp"] * 1000;
    if (DateTime.now().millisecondsSinceEpoch > expiryTime) {
      print(" Error: Token has expired");
      return;
    }
  } catch (e) {
    print(" Error decoding token: $e");
    return;
  }

  // Get stored username from preferences.
  String storedUserName = prefs.getString("user_identifier") ?? "Default Athlete";

  // Check if the athlete is already in the list using the extracted userUuid.
  bool userExists = _athletes.any((athlete) => athlete["player_Id"] == userUuid);

  if (!userExists) {
    setState(() {
      _athletes.add({
        "name": storedUserName,
        "number": 1,
        "player_Id": userUuid, // Use the UUID from the token
      });
    });
    await _addAthlete(defaultName: storedUserName, defaultNumber: 1);
  }
}



 void _updateAvailableNumbers() {
    final takenNumbers =
        _athletes.map((athlete) => athlete["number"] as int).toSet();
    _availableNumbers = List.generate(999, (index) => index + 1)
        .where((number) => !takenNumbers.contains(number))
        .toList();
    if (_availableNumbers.isEmpty) {
      _availableNumbers = [1];
    }
    print("Updated Available Numbers: $_availableNumbers");

    if (_isMounted) {
      setState(() {});
    }
  }

Future<void> _addAthlete({String? defaultName, int? defaultNumber}) async {
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString("auth_token");
  if (token == null) {
    print(" No auth token found.");
    return;
  }
 // Extract the token from JSON
  Map<String, dynamic> tokenData = jsonDecode(token);
  String? authToken = tokenData["token"]; // Fix: Extract authToken
  String nameToSend = defaultName ?? _nameController.text.trim();
  int numberToSend = defaultNumber ?? _selectedNumber ?? 1;

  if (nameToSend.isEmpty) {
    print(" Name cannot be empty.");
    return;
  }
  
  print(" Editing Athlete:");
  print(" Name: $nameToSend");
  print(" Number: $numberToSend");
  
  try {
    final Uri uri = Uri.parse("$apiUrl/addAthlete?name=$nameToSend&number=$numberToSend");
    print(" Sending request to: $uri");
    print("Auth Token: $token");

    final response = await http.post(
      uri,
      headers: {
        "Authorization": "Bearer $authToken",
        "Accept": "application/json",
        "Content-Type": "application/json",


      },
    );

    print(" Response Status Code: ${response.statusCode}");
    print(" Response Body: ${response.body}");

    if (response.statusCode == 200 && _isMounted) {
      final List<dynamic> responseData = jsonDecode(response.body);
      final List<Map<String, dynamic>> updatedAthletes = responseData.map((athlete) {
        return {
          "player_Id": athlete["player_Id"],
          "name": athlete["name"],
          "number": athlete["number"],
        };
      }).toList();

      setState(() {
        _athletes = updatedAthletes;
        _updateAvailableNumbers();
      });
      print("Athletes Updated: $_athletes");
    } else if (response.statusCode == 403) {
      print("Forbidden: You do not have permission to access this resource.");
    } else {
      print("Error Adding Athlete: ${response.body}");
    }
  } catch (e) {
    print(" Exception while adding athlete: $e");
  }
}

  Future<void> _editAthlete(String playerId, String name, int oldNumber, int number) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("auth_token");
    if (token == null) {
      print(" No auth token found.");
      return;
    }
    // Extract the token from JSON
  Map<String, dynamic> tokenData = jsonDecode(token);
  String? authToken = tokenData["token"]; // Fix: Extract authToken
  print("Editing athlete with ID: $playerId");
if (playerId.isEmpty) {
  print("Error: playerId is empty, cannot proceed with edit.");
  return;
}

    try {
      final url = Uri.parse("$apiUrl/editAthlete/$playerId/$name/$number");
      print("Sending Edit Request to: $url");

      final response = await http.put(
        url,
        headers: {
          "Authorization": "Bearer $authToken",
          "Accept": "application/json"
        },
      );

      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        // Parse the updated list of athletes from the response
        final updatedAthletes = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        setState(() {
          _athletes = updatedAthletes;
          _updateAvailableNumbers();
        });
        print("Athletes Updated: $_athletes");
      } else {
        print("Error Updating Athlete: ${response.body}");
      }
    } catch (e) {
      print("Exception while updating athlete: $e");
    }
  }

  Future<void> _deleteAthlete(String playerId) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("auth_token");
    if (token == null) return;
    // Extract the token from JSON
  Map<String, dynamic> tokenData = jsonDecode(token);
  String? authToken = tokenData["token"]; // Fix: Extract authToken

    try {
      final response = await http.delete(
        Uri.parse("$apiUrl/deleteAthlete/$playerId"),
        headers: {"Authorization": "Bearer $authToken"},
      );

      if (response.statusCode == 200) {
        // Parse the updated list of athletes from the response
        final updatedAthletes = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        setState(() {
          _athletes = updatedAthletes;
          _updateAvailableNumbers();
        });
        print("Athletes Updated: $_athletes");
      }
    } catch (e) {
      print("Error deleting athlete: $e");
    }
  }

  void _showCreateAthleteDialog({Map<String, dynamic>? athlete}) async {
  int? previousNumber;
  String? playerId;

  if (athlete != null) {
    _nameController.text = athlete["name"];
    previousNumber = athlete["number"];
    playerId = athlete["player_Id"]; // Store player ID for editing

    if (playerId == null || playerId.isEmpty) {
      print("Error: Invalid playerId received for editing.");
      return;
    }
    _selectedNumber = previousNumber;
  } else {
    _nameController.clear();
    _selectedNumber = _availableNumbers.isNotEmpty ? _availableNumbers.first : 1;
  }

  int initialIndex = _availableNumbers.isNotEmpty
      ? _availableNumbers.indexOf(_selectedNumber ?? _availableNumbers.first)
      : 0; // Ensure it doesn't crash if list is empty

  print(" Opening Dialog: ${athlete == null ? 'Create' : 'Edit'} Athlete");
  if (!mounted) return;

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
                      itemExtent: 42.0,
                      scrollController: FixedExtentScrollController(
                        initialItem: initialIndex,
                      ),
                      onSelectedItemChanged: (int index) {
                        if (_isMounted) {
                          setState(() {
                            _selectedNumber = _availableNumbers[index];
                          });
                        }
                      },
                      children: _availableNumbers
                          .map((number) => Center(child: Text(number.toString())))
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
                  playerId!,
                  _nameController.text.trim(),
                  previousNumber!,
                  _selectedNumber!,
                );
              }
              Navigator.of(dialogContext).pop();
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
        backgroundColor: AppColors.primaryColor,
        title: const Text('Add Athlete', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          onPressed: () => Get.offAllNamed('/BasicModeScreen'),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () => _showCreateAthleteDialog(),
            icon: const Icon(Icons.person_add, color: Colors.white),
            tooltip: "Add Athlete",
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
                          icon: const Icon(Icons.delete,
                              color: Color.fromARGB(255, 148, 2, 2)),
                          onPressed: () => _deleteAthlete(athlete["player_Id"]),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}