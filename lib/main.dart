import 'package:firebase_core/firebase_core.dart';
import 'package:fisat_timetable/google_sign.dart';
import 'package:fisat_timetable/home_controller.dart';
import 'package:fisat_timetable/home_page_u.dart';
import 'package:fisat_timetable/start_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
 

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBRhjSUtUg3POkZ6HR-NN8HN9Ecxod3JH4",
      appId: "1:967714456718:android:1a2f43536d6b19bc5ab5df",
      messagingSenderId: "967714456718",
      projectId: "fisattimetablefirebase",
      storageBucket: "fisattimetablefirebase.firebasestorage.app",
    ),
  );
  Get.put(HomeController());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Lab Allotment',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      getPages: [
        GetPage(name: "/", page: () => HomePage()),
        GetPage(name: "/start", page: () => StartupPage()),
        GetPage(name: "/user", page: () => HomePageU()),
        GetPage(name: "/google", page: () => GoogleSignInPage()),
      ],
      initialRoute: "/",
    );
  }
}
