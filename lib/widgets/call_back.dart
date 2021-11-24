import 'package:flutter/material.dart';
import 'package:qr_code_example/pages/home_page.dart';

class CallBack extends StatefulWidget {
  final bool isScanner;
  const CallBack({Key? key, required this.isScanner}) : super(key: key);

  @override
  _CallBackState createState() => _CallBackState();
}

class _CallBackState extends State<CallBack> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback(
      (_) => Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(isScanner: widget.isScanner),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
