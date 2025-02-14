import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: "AIzaSyDx9OyLkUBCIwyOXBrTEhMetC9toy26iHw",
      appId: "1:582964422062:web:e85bf52c49e8decf34d43f",
      messagingSenderId: "582964422062",
      projectId: "pocket-photo-finish",
      storageBucket: "pocket-photo-finish.appspot.com", // 🔹 Corrected value
    );
  }
}
