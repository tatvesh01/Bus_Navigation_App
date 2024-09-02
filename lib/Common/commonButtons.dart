import 'package:flutter/material.dart';
import '../Utils/helper.dart';

class CommonButtons extends StatelessWidget {
  CommonButtons(String label);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
          backgroundColor: Helper.lightBlueColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      onPressed: () {},
      child: const Text(
        "label",
        style: TextStyle(color: Colors.white, fontSize: 15),
      ),
    );
  }
}