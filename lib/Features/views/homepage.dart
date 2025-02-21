//home page
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants/colors.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart'; // Necessary for launching URLs

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _currentIndex = 0;
  @override
  void initState() {
    super.initState();
    _checkTokenValidity();
    // ✅ Check if an argument (index) was passed during navigation
    if (Get.arguments != null && Get.arguments is Map<String, dynamic>) {
      setState(() {
        _currentIndex = Get.arguments['index'] ?? 0; // ✅ Default to 0 if null
      });
    }
  }

  Future<void> _checkTokenValidity() async {
    final prefs = await SharedPreferences.getInstance();
    int? expiryTime = prefs.getInt("token_expiry");

    if (expiryTime != null) {
      int currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (currentTime >= expiryTime) {
        _logoutUser(); // ✅ Logout if token expired
      }
    }
  }
void _logoutUser() async {
  final prefs = await SharedPreferences.getInstance();

   // Remove authentication-related data
  await prefs.remove("auth_token");   // Clear authentication token
  await prefs.remove("token_expiry"); // Clear token expiry time
  await prefs.remove("user_identifier");
  
  // Remove all stored user-related data
  await prefs.clear(); // This clears all stored data

  Get.offNamed("/login"); // Navigate to login screen

  Get.snackbar(
    "Session Expired",
    "Please log in again.",
    backgroundColor: Colors.redAccent,
    colorText: Colors.white,
  );
}

  // void _logoutUser() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.remove("auth_token"); // Remove token
  //   await prefs.remove("token_expiry"); // Remove expiry time
  //   await prefs.remove("user_identifier"); // Remove user identifier

  //   Get.offNamed("/login");
  //   Get.snackbar("Session Expired", "Please log in again.",
  //       backgroundColor: Colors.redAccent, colorText: Colors.white);
  // }

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

  // To track the selected tab

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false, // This removes the back button
        backgroundColor: AppColors.primaryColor,
        title: Text(
          "Pocket Photo Finish",
          style: GoogleFonts.roboto(
              color: AppColors.backgroundColor, fontWeight: FontWeight.bold),
        ),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: Icon(
                Icons.tune,
                color: AppColors.backgroundColor,
              ),
              onPressed: () {
                Scaffold.of(context).openDrawer(); // Open the drawer
              },
            );
          },
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
              ),
              child: Text(
                'More Options',
                style: TextStyle(
                    color: Color.fromARGB(255, 250, 245, 245), fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.of(context).pop();
                Get.toNamed("/settings");
              },
            ),
            ListTile(
              leading: const Icon(Icons.play_circle_outlined),
              title: const Text('Tutorial Videos'),
              onTap: () {
                Navigator.of(context).pop();
                Get.toNamed("/about");
              },
            ),
            ListTile(
              leading: const Icon(Icons.school_outlined),
              title: const Text('FAQ'),
              onTap: () {
                Navigator.of(context).pop();
                Get.toNamed("/faq");
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About'),
              onTap: () {
                Navigator.of(context).pop();
                Get.toNamed("/aboutpage");
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log out'),
              onTap: () {
                _logoutUser(); // ✅ Call the function properly
                Get.offAllNamed("/login"); // ✅ Navigate to login after logout
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage("assets/imagehome.jpg"),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter // ✅ Shifts the image to the left
                ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 50),
            child: Column(
              children: [
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Get.toNamed("/BasicModeScreen");
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.backgroundColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size(300, 50),
                  ),
                  child: Text(
                    "CREATE SESSION",
                    style:
                        TextStyle(color: const Color.fromARGB(255, 13, 13, 14)),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.primaryColor,
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.backgroundColor,
        unselectedItemColor: AppColors.ropecolor,
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
      floatingActionButton: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Positioned(
            bottom: 80,
            right: 10,
            child: FloatingActionButton.extended(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50)),
              onPressed: () {
                // Show the AlertDialog
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text("Exciting Study Results!"), // Dialog title
                      content: Text(
                        "Our study highlights the remarkable accuracy of XI Timer, surpassing traditional light barrier systems. The results show a 95% confidence level with an error margin of less than 15 milliseconds.",
                      ), // Dialog content
                      actions: [
                        TextButton(
                          onPressed: () async {
                            const pdfUrl =
                                'https://pdflink.to/0f32ae23/'; // Example link to test
                            final Uri url = Uri.parse(pdfUrl);

                            // Debugging to confirm the button press
                            print('View Study button pressed');

                            // Try to launch the URL
                            try {
                              if (!await launchUrl(
                                url,
                                mode: LaunchMode
                                    .platformDefault, // Works better on Android
                              )) {
                                print('Could not launch URL: $pdfUrl');
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          "Could not open the link. Please try again.")),
                                );
                              }
                            } catch (e) {
                              print('Error occurred while launching URL: $e');
                            }
                          },
                          child: Text("View Study"), // Redirect button
                        ),
                      ],
                    );
                  },
                );
              },
              backgroundColor: AppColors.backgroundColor,
              icon: Icon(Icons.play_circle_outlined,
                  color: const Color.fromARGB(255, 5, 6, 8)),
              label: Text("NEW: ACCURACY STUDY",
                  style:
                      TextStyle(color: const Color.fromARGB(255, 13, 13, 14))),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 10,
            child: FloatingActionButton.extended(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50)),
              onPressed: () {
                print('FAB 2 clicked');
              },
              backgroundColor: AppColors.backgroundColor,
              icon: Icon(Icons.play_circle_outlined,
                  color: Color.fromARGB(255, 5, 6, 8)),
              label: Text("NEW: TUTORIAL VIDEOS",
                  style:
                      TextStyle(color: const Color.fromARGB(255, 13, 13, 14))),
            ),
          ),
        ],
      ),
    );
  }
}
