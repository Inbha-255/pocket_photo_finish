import 'package:flutter_application_1/Features/views/detection_page/stopwatch_controller.dart';
import 'package:flutter_application_1/Features/views/homepage.dart';
import 'package:flutter_application_1/Features/views/loginpage/forget.dart';
import 'package:flutter_application_1/Features/views/loginpage/login.dart';
import 'package:flutter_application_1/Features/views/loginpage/signup.dart';
import 'package:flutter_application_1/Features/views/history.dart';
import 'package:flutter_application_1/Features/views/settings/about.dart';
import 'package:flutter_application_1/Features/views/settings/faq.dart';
import 'package:get/get.dart';
import '../Features/views/athlete.dart';
import '../Features/views/basicmode.dart';
import '../Features/views/detection_page/camera_service.dart';

List<GetPage> approutes() {
  return [
    GetPage(name: '/login', page: () => LoginPage()),
    GetPage(name: '/forget', page: () => ForgotPasswordPage()),
    GetPage(name: '/signup', page: () => SignUpPage()),
    GetPage(name: '/home', page: () => Homepage()),
    GetPage(name: '/BasicModeScreen', page: () => BasicModeScreen()),
    GetPage(name: '/Athlete', page: () => SelectAthletePage()),
    GetPage(name: '/history', page: () => HistoryPage()),
    GetPage(name: '/faq', page: () => Faq()),
    GetPage(name: '/aboutpage', page: () => Aboutpage()),
    GetPage(
      name: '/stopwatch',
      page: () => StopwatchScreen(
        cameras: CameraService().cameras, // Access cameras from CameraService
      ),
    ),


  ];
}
