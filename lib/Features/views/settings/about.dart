import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants/colors.dart';

class Aboutpage extends StatelessWidget {
  const Aboutpage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Info",style: TextStyle(color: Colors.white),),
      
      backgroundColor: AppColors.primaryColor,
      
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text("Xi-Timer is an app designed for precise timing and performance tracking, often used in sports, fitness, and other timing-related activities. "
            "The app offers features such as countdown timers, and the ability to measure and record intervals accurately. It's typically used by athletes, trainers, and event organizers for measuring time in races or training sessions."
            "Xi-Timer is an app that motivates athletes to keep investing in improving their performance by offering precise timing and performance tracking features. By providing athletes with real-time data on their progress, the app encourages them to push their limits and stay committed to their training goals."
            " Whether tracking personal bests, analyzing splits, or monitoring interval training,"
            " the app gives athletes the tools they need to measure their improvements and stay motivated to keep progressing.")
          ],
        ),
      ),
    );
  }
}