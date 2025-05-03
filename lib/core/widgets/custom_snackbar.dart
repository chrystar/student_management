import 'package:flutter/material.dart';

/// Shows a custom snackbar with optional error styling
void showCustomSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
  Duration duration = const Duration(seconds: 3),
}) {
  final snackBar = SnackBar(
    content: Text(
      message,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
      ),
    ),
    backgroundColor: isError ? Colors.red.shade800 : Colors.green.shade700,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    margin: const EdgeInsets.all(10),
    duration: duration,
    action: SnackBarAction(
      label: 'Dismiss',
      onPressed: () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      },
      textColor: Colors.white,
    ),
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
