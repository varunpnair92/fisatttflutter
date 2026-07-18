import 'package:fisat_timetable/google.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GoogleSignInPage extends StatelessWidget {
  final GoogleSignInController controller = Get.put(GoogleSignInController());

  GoogleSignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Google Sign In"),
        centerTitle: true,
      ),
      body: Center(
        child: Obx(() => controller.isSigningIn.value
            ? const CircularProgressIndicator()
            : ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text("Sign in with Google"),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                onPressed: controller.signInWithGoogle,
              )),
      ),
    );
  }
}
