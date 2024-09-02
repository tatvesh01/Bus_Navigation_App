import 'package:flutter/material.dart';
import '../Utils/helper.dart';

class BaseAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget> widgets;

  const BaseAppBar({super.key, required this.title, required this.widgets});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      iconTheme: IconThemeData(color: Helper.whiteColor),
      title: Text(
        title,
        style: TextStyle(color: Helper.whiteColor, fontSize: 18,fontWeight: FontWeight.w500),
      ),
      backgroundColor: Helper.lightBlueColor,
      actions: widgets,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(55);
}