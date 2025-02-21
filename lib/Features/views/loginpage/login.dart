// ignore_for_file: avoid_print, depend_on_referenced_packages
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final String loginApiUrl = "https://api.jslpro.in:4661/login";

  bool _obscureText = true;

  bool _validateInputs() {
    String username = usernameController.text.trim();
    String password = passwordController.text.trim();

    if (username.isEmpty) {
      Get.snackbar("Invalid Username", "Please enter a valid Username.",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return false;
    }

    if (password.isEmpty || password.length < 6) {
      Get.snackbar(
          "Invalid Password", "Password must be at least 6 characters long.",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return false;
    }

    return true;
  }

  /// ✅ **Decode JWT Token to extract "sub" field (User Identifier)**
  String? _decodeJwtForSub(String token) {
    try {
      List<String> tokenParts = token.split(".");
      if (tokenParts.length != 3) {
        print("❌ Invalid JWT format.");
        return null;
      }

      // ✅ Decode payload (Base64)
      String payload = tokenParts[1];
      String decodedPayload =
          utf8.decode(base64Url.decode(base64Url.normalize(payload)));

      print("🔹 Full Decoded JWT Payload: $decodedPayload"); // Debugging log

      // ✅ Convert JSON payload to a Map
      Map<String, dynamic> payloadData = jsonDecode(decodedPayload);

      // ✅ Ensure "sub" key exists before accessing
      return payloadData["sub"] as String?;
    } catch (e) {
      print("❌ Error decoding JWT: $e");
      return null;
    }
  }

  /// ✅ **Decode JWT Token to extract "exp" field (Expiry Timestamp)**
  int? _decodeJwtExpiry(String token) {
    try {
      List<String> tokenParts = token.split(".");
      if (tokenParts.length != 3) {
        print("❌ Invalid JWT format.");
        return null;
      }

      String payload = tokenParts[1];
      String decodedPayload =
          utf8.decode(base64Url.decode(base64Url.normalize(payload)));
      Map<String, dynamic> payloadData = jsonDecode(decodedPayload);

      return payloadData["exp"] as int?;
    } catch (e) {
      print("❌ Error decoding JWT expiry: $e");
      return null;
    }
  }

  Future<void> _authenticateUser() async {
    if (!_validateInputs()) return;

    Map<String, dynamic> requestBody = {
      "username": usernameController.text.trim(),
      "password": passwordController.text.trim(),
    };

    try {
      final response = await http.post(
        Uri.parse(loginApiUrl),
        headers: {"Content-Type": "application/json", "Accept": "application/json"},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 10));

      print("🔹 Response Status: ${response.statusCode}");
      print("🔹 Raw Response Body: '${response.body}'"); // Debugging

      if (response.statusCode == 200) {
        // ✅ The response body is the JWT token (plain string)
        String token = response.body.trim();

        if (token.isEmpty) {
          print("❌ Token is empty.");
          Get.snackbar("Login Failed", "Invalid token received.",
              backgroundColor: Colors.redAccent, colorText: Colors.white);
          return;
        }

        String loggedInUsername = usernameController.text.trim();
        String? userIdentifier = _decodeJwtForSub(token);
        int? expiryTime = _decodeJwtExpiry(token);

        if (userIdentifier == null || userIdentifier.isEmpty) {
          Get.snackbar("Login Failed", "Could not retrieve user identifier.",
              backgroundColor: Colors.redAccent, colorText: Colors.white);
          return;
        }

        if (expiryTime == null) {
          print("❌ Failed to extract expiry time.");
          Get.snackbar("Login Failed", "Invalid token expiry.",
              backgroundColor: Colors.redAccent, colorText: Colors.white);
          return;
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("auth_token", token);
        await prefs.setString("user_identifier", userIdentifier);
        await prefs.setInt("token_expiry", expiryTime);

        if (!prefs.containsKey("selectedAthlete")) {
          Map<String, dynamic> defaultAthlete = {
            "name": loggedInUsername,
            "number": 1
          };
          await prefs.setString("selectedAthlete", jsonEncode(defaultAthlete));
        }

        Get.snackbar("Login Successful", "Welcome, $loggedInUsername!",
            backgroundColor: Colors.green, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);

        Get.offNamed('/home');
      } else {
        Get.snackbar("Login Failed", "Incorrect username or password.",
            backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e) {
      print("❌ Unexpected error: $e");
      Get.snackbar("Error", "Unexpected error: $e",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Get.toNamed('/login');
          },
        ),
        title: const Text("Login", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Login Here",
                  style: GoogleFonts.roboto(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    labelText: "Username",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.person, color: Colors.black),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: passwordController,
                  obscureText: _obscureText,
                  decoration: InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.lock, color: Colors.black),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off : Icons.visibility,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _authenticateUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 80),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "LOGIN",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
                const SizedBox(height: 10),
                          // Forgot Password TextButton
                          TextButton(
                            onPressed: () {
                              Get.toNamed('/forget');
                            },
                            child: Text(
                              "Forgot Password?",
                              style: TextStyle(
                                  color: AppColors.textcolor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          // Sign Up TextButton
                          TextButton(
                            onPressed: () {
                              Get.toNamed('/signup');
                            },
                            child: const Text(
                              "Sign Up",
                              style: TextStyle(
                                  color: AppColors.textcolor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
