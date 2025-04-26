import 'package:flutter/material.dart';


Widget text12Normal({required String text, required Color color}) {
  return Text(
    text,
    style: TextStyle(
      fontSize: 12,
      color: color,
    ),
  );
}
Widget text14Normal({required String text, required Color color}) {
  return Text(
    text,
    style: TextStyle(
      fontSize: 16,
      color: color,
    ),
  );
}

Widget text16Normal({required String text, required Color color, FontWeight? fontWeight}) {
  return Text(
    text,
    style: TextStyle(
      fontSize: 16,
      color: color,
      fontWeight: fontWeight,
    ),
  );
}

Widget text18Normal({required String text, required Color color}) {
  return Text(
    text,
    style: TextStyle(
      fontSize: 18,
      color: color,
    ),
  );
}

Widget text20Normal({required String text, required Color color}) {
  return Text(
    text,
    style: TextStyle(
      fontSize: 20,
      color: color,
    ),
  );
}

Widget text24Normal({required String text, required Color color, FontWeight? fontWeight}) {
  return Text(
    text,
    style: TextStyle(
        fontSize: 24,
        color: color,
        fontWeight: fontWeight
    ),
  );
}
