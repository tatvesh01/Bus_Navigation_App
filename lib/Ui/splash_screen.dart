import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Utils/helper.dart';
import '../Controller/splash_screen_controller.dart';
import '../Utils/global.dart';

class SplashScreen extends StatelessWidget {
  SplashScreen({Key? key}) : super(key: key);

  SplashScreenController splashScreenController = Get.put(SplashScreenController());

  @override
  Widget build(BuildContext context) {

    Global.deviceSize(context);

    return Scaffold(
      body: Container(
        height: Global.sHeight,
        width: Global.sWidth,
        color: Helper.bgColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(Helper.iconImg,height: 100,width: 100,),
            SizedBox(height: 20,),
            Text(
              "Please Wait..",
              style: TextStyle(color: Helper.blackColor, fontSize: 18,fontWeight: FontWeight.w500),
            )
          ],
        ),
      ),
    );
  }
}
