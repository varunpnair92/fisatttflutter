import 'package:fisat_timetable/google.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StartupController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _checkSignInState();
  }

  Future<void> _checkSignInState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isSignedIn = prefs.getBool('is_signed_in') ?? false;
    String email = prefs.getString('user_email') ?? "";

    if (isSignedIn && email.isNotEmpty) {
      
      await GoogleSignInController().checkLoginAndNavigate();
    } else {
      
      Get.offAllNamed("/google");
    }
  }
}
