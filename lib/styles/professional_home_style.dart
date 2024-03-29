import 'package:flutter/material.dart';

class ProfessionalHomeStyle {
  List<Color> colorizeColors = [
    Colors.purple,
    Colors.indigo,
    Colors.deepPurple,
    Colors.purple,
    Colors.indigo,
    Colors.deepPurple,
    Colors.purple,
    Colors.indigo,
    Colors.deepPurple,
    Colors.purple,
    Colors.indigo,
    Colors.deepPurple,
  ];

  TextStyle colorizeTitleTextStyle = const TextStyle(
    fontSize: 40.0,
    fontFamily: 'Horizon',
  );
  TextStyle colorizeTextStyle = const TextStyle(
    fontSize: 20,
    fontFamily: 'Horizon',
  );

  InputDecoration inputDecoration({required String hintText}) {
    return InputDecoration(
        border: InputBorder.none,
        hintText: hintText,
        hintStyle: const TextStyle(color: Color.fromARGB(255, 10, 24, 229)));
  }
}
