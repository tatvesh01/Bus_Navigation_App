import 'dart:ui';

class Helper{

  //colors
  static Color bgColor = const Color(0xFFFFFFFF);
  static Color whiteColor = const Color(0xFFFFFFFF);
  static Color blackColor = const Color(0xFF000000);
  static Color greyColor = const Color(0xFFB2B2B2);
  static Color lightGreyColor = const Color(0xA0F1F0F0);
  static Color redColor = const Color(0xFFFF1C1C);
  static Color lightBlueColor = const Color(0xFF3FBCFF);
  static Color lightGreenColor = const Color(0xFF3EA61D);
  static Color transparentColor = const Color(0xFFFFFF);
  static Color polyLineColor = const Color(0xFF2222FF);

  //images
  static String dotImg = "assets/images/black_dot.png";
  static String iconImg = "assets/images/app_icon.png";
  static String carImg = "assets/images/car_img.png";
  static String upArrowImg = "assets/images/up_arrow_img.png";
  static String upArrowBlackImg = "assets/images/up_arrow_black_img.png";

  static int destReachTimeMinMtr = 50;
  static int drawDotedRouteAgainAfterDriveMeters = 5;
  static int drawReRouteTimeMinMtr = 8;
}