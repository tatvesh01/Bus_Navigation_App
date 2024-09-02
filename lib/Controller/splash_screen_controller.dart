import 'package:get/get.dart';
import 'package:map_navigation/Ui/main_screen.dart';
import '../Utils/sPHelper.dart';

class SplashScreenController extends GetxController{

  @override
  void onInit() {

    SPHelper.sharedPrefInit();
    redirectScreen();
    super.onInit();
  }

  void redirectScreen() {
    Future.delayed(const Duration(seconds: 1), () {
      Get.off(()=>MainScreen());
    });
  }


}