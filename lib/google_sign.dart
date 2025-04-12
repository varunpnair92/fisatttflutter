import 'package:fisat_timetable/google.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GoogleSignInPage extends StatelessWidget {
  final GoogleSignInController controller = Get.put(GoogleSignInController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Google Sign In"),
        centerTitle: true,
      ),
      body: Center(
        child: Obx(() => controller.isSigningIn.value
            ? CircularProgressIndicator()
            : ElevatedButton.icon(
                icon: Icon(Icons.login),
                label: Text("Sign in with Google"),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: TextStyle(fontSize: 18),
                ),
                onPressed: controller.signInWithGoogle,
              )),
      ),
    );
  }
}
