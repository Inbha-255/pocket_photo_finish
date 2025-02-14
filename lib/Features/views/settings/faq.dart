import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants/colors.dart';

class Faq extends StatelessWidget {
  final List<Map<String, String>> faqItems = [
    {
      "question": "What is XI-Timer?",
      "answer":
          "Xi-Timer is an app designed for precise timing and performance tracking, often used in sports, fitness, and other timing-related activities. The app offers features such as countdown timers, and the ability to measure and record intervals accurately. It's typically used by athletes, trainers, and event organizers for measuring time in races or training sessions.Xi-Timer is an app that motivates athletes to keep investing in improving their performance by offering precise timing and performance tracking features. By providing athletes with real-time data on their progress, the app encourages them to push their limits and stay committed to their training goals. Whether tracking personal bests, analyzing splits, or monitoring interval training, the app gives athletes the tools they need to measure their improvements and stay motivated to keep progressing."
    },
    {
      "question": "What are the technical prerequisites of XI-Timer?",
      "answer":
          "The app works by utilizing the camera of your native device, which is set up at the finish line of a race or competition. Using advanced object detection technology, the app specifically focuses on detecting the human body as the object of interest. It filters out all other irrelevant objects in the frame, such as background elements or stationary items, ensuring that only the athlete's body is tracked. When the athlete crosses the finish line, the app detects the first body part (e.g., foot or torso) that crosses the threshold, and precisely records the time. This allows for accurate, real-time measurement of performance without the need for physical sensors or manual timing.only need the manual start when the athlete"
    },
    {
      "question": "What is the Basic Mode?",
      "answer":
          "In Basic Mode, the setup is designed to be simple and efficient for personal training. The stopwatch started Manually as the athlete's movement or presence at the start line. As the athlete crosses the designated area, the phone’s camera automatically detects the athlete’s body and records intermediate times, such as lap times, each time the athlete passes the camera's field of view."
    },
    {
      "question": "Can i Time Multiple Athlete at Once?",
      "answer":
          "Yes, you can time multiple athletes at once in Basic Mode, as the app's camera can detect multiple athletes crossing the finish line. However, the times recorded will be based on when each athlete is detected individually"
    },
    {
      "question": "How does the Detection works?",
      "answer":
          "In Xi-Timer, detection operates at 30 frames per second, utilizing machine learning techniques to ensure real-time performance on most modern smartphones. As an athlete crosses the finish line, the app captures 30 frames per second, calculating the chest position for precise timing. The exact crossing moment is determined using ML-based interpolation between frame times just before and after the crossing. By default, Xi-Timer displays the frame immediately after the finish line for accurate analysis"
    },
    {
      "question": "How can i test accuracy of xi-timer?",
      "answer":
          "To test Xi-Timer's accuracy, set up the device at a finish line and use a controlled scenario, such as a known time interval or a secondary stopwatch for comparison. Record the time it detects for an athlete crossing the line and compare it with the manually measured time. Repeat this multiple times to ensure consistency. Testing with various lighting conditions and athlete speeds can also help verify its precision and reliability",
    },
    {
      "question": "I'm having some difficulties with detection reliability",
      "answer":
          "If you're facing detection reliability issues, ensure the camera is positioned correctly with a clear, unobstructed view of the finish line. Check for adequate lighting, as poor lighting can affect accuracy. Minimize background distractions to help the app focus on the athlete. If problems persist, consider updating the app or testing on a more powerful device.",
    },
    {
      "question": "Do I need a tripod for XI-Timer?",
      "answer":
          "Using a tripod for Xi-Timer is highly recommended to ensure stability and consistent camera alignment, especially at the finish line. A stable setup reduces the chances of detection errors caused by shaky footage. It also allows you to position the camera at an optimal height and angle for better accuracy. While not mandatory, a tripod greatly enhances reliability and ease of use.",
    },
  ];

  Faq({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "FAQ",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryColor,
      ),
      backgroundColor: const Color.fromARGB(255, 171, 170, 171),
      body: ListView.builder(
        itemCount: faqItems.length,
        itemBuilder: (context, index) {
          final faqItem = faqItems[index];
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  //borderRadius: BorderRadius.circular(8.0),
                  ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      faqItem["question"]!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      faqItem["answer"]!,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
