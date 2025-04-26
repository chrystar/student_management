import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Activities extends StatefulWidget {
  const Activities({super.key});

  @override
  State<Activities> createState() => _ActivitiesState();
}

class _ActivitiesState extends State<Activities> {
  late WebViewController controller;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    controller = WebViewController()
      ..loadRequest(Uri.parse('https://portal.funai.edu.ng/'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebViewWidget(
        controller: controller,
      ),
    );
  }
}
