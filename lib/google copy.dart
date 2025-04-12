import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fisat_timetable/shared.dart';

class GoogleSignInController extends GetxController {
  final RxBool isSigningIn = false.obs;

  Future<void> signInWithGoogle() async {
    isSigningIn.value = true;

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        isSigningIn.value = false;
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      String email = userCredential.user?.email ?? "";

      //int privilege = await fetchPrivilege(email);

      //print("privileges in seid $privilege");

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_signed_in', true);
      await prefs.setString('user_email', email);
      checkLoginAndNavigate();
    } catch (e) {
      print("Error during Google sign-in: $e");
      Get.snackbar("Error", "Google sign-in failed");
    } finally {
      isSigningIn.value = false;
    }
  }

  Future<int> fetchPrivilege(String email) async {
    try {
      var ip = "${Sharedvariable().ip}/lab/user_data?email=$email";
      print("ippppppppppppppppppp$ip");
      final response = await http.get(Uri.parse(ip));

      final data = json.decode(response.body);
      //print("data  is    $data");
      return data['privilege'] ?? 0;
    } catch (e) {
      print("Failed to fetch privilege: $e");
      return 0;
    }
  }

  Future<void> checkLoginAndNavigate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isSignedIn = prefs.getBool('is_signed_in') ?? false;
    String email = prefs.getString('user_email') ?? "";

    if (isSignedIn && email.isNotEmpty) {
      int privilege = await fetchPrivilege(email);

      if (privilege == 1) {
        Get.toNamed("/");
      } else if (privilege == 0) {
        Get.toNamed("/user");
      } else {
        Get.toNamed("/google");
      }
    }
  }

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Get.offAllNamed('/google');
  }
}
