import 'dart:async'; // Import for Timeout handling
import 'dart:convert'; // Import for JSON encoding
import 'dart:io'; // Import for HttpOverrides
import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants/colors.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;


class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  SignUpPageState createState() => SignUpPageState();
}

class SignUpPageState extends State<SignUpPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscureText = true;

  final String signUpApiUrl = "https://api.jslpro.in:4661/register";

  bool _validateInputs() {
    String name = nameController.text.trim();
    String username = usernameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    RegExp nameRegex = RegExp(r'^[a-zA-Z]+$');
    RegExp usernameRegex = RegExp(r'^[a-zA-Z0-9]+$');
    RegExp emailRegex = RegExp(r'^[a-zA-Z0-9]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

    if (name.isEmpty || !nameRegex.hasMatch(name)) {
      Get.snackbar("Invalid Name", "Please enter a valid Name.",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return false;
    }

    if (username.isEmpty || !usernameRegex.hasMatch(username)) {
      Get.snackbar("Invalid Username", "Please enter a valid Username.",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return false;
    }

    if (email.isEmpty || !emailRegex.hasMatch(email)) {
      Get.snackbar("Invalid Email", "Please enter a valid Email address.",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return false;
    }

    if (password.isEmpty || password.length < 6) {
      Get.snackbar("Invalid Password", "Password must be at least 6 characters long.",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return false;
    }

    return true;
  }

  Future<void> _signUpUser() async {
    if (!_validateInputs()) return;

    Map<String, dynamic> requestBody = {
      "name": nameController.text.trim(),
      "username": usernameController.text.trim(),
      "email": emailController.text.trim(),
      "password": passwordController.text.trim(),
    };

    try {
      final response = await http.post(
        Uri.parse(signUpApiUrl),
        headers: {"Content-Type": "application/json", "Accept": "application/json"},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        Get.snackbar("Registration Successful", "You are now registered!",
            backgroundColor: Colors.green, colorText: Colors.white);

        nameController.clear();
        usernameController.clear();
        emailController.clear();
        passwordController.clear();

        Future.delayed(const Duration(seconds: 2), () {
          Get.toNamed('/login');
        });
      } else {
        Map<String, dynamic> errorResponse = jsonDecode(response.body);
        String errorMessage = errorResponse["message"] ?? "Registration failed.";
        Get.snackbar("Registration Failed", errorMessage,
            backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } on SocketException catch (_) {
      Get.snackbar("Error", "No Internet connection or server is unreachable.",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    } on TimeoutException catch (_) {
      Get.snackbar("Error", "Connection timeout. Please check your network.",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    } on FormatException catch (_) {
      Get.snackbar("Error", "Invalid response from server.",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Unexpected error: $e",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sign Up", style: TextStyle(color: AppColors.backgroundColor)),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Register Here",
                style: GoogleFonts.roboto(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Name",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: Icon(Icons.person, color: Colors.black),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: "Username",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: Icon(Icons.person, color:Colors.black ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: Icon(Icons.email, color: Colors.black),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: Icon(Icons.lock, color: Colors.black),
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
                onPressed: _signUpUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 80),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("SIGN UP", style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
