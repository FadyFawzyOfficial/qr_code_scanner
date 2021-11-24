import 'package:flutter/material.dart';
import 'package:qr_code_example/pages/home_page.dart';

class ScanAgain extends StatefulWidget {
  final bool isScanner;
  const ScanAgain({Key? key, required this.isScanner}) : super(key: key);

  @override
  _ScanAgainState createState() => _ScanAgainState();
}

class _ScanAgainState extends State<ScanAgain> {
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
