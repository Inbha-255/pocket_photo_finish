//splash screen                                                                                                                                                                             
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants/colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to home page after 3 seconds
    Timer(Duration(seconds: 1), () {
      Navigator.pushReplacementNamed(context, '/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor, // Change as needed
      body: Center(
        child: Image.asset(
          'assets/splashscreen.png', // ✅ Corrected syntax
          width: 200,
          height: 200,
          errorBuilder: (context, error, stackTrace) {
            return Text(
              'Image not found!',
              style: TextStyle(fontSize: 16, color: Colors.red),
            ); // ✅ Handles missing image
          },
        ),
      ),
    );
  }
}
