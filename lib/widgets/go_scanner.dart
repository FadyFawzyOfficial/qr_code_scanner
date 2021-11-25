import 'package:flutter/material.dart';
import 'package:qr_code_example/pages/booth_scanner_page.dart';

class GoScanner extends StatefulWidget {
  final int boothNumber;
  const GoScanner({Key? key, required this.boothNumber}) : super(key: key);

  @override
  _GoScannerState createState() => _GoScannerState();
}

class _GoScannerState extends State<GoScanner> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((_) => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BoothScannerPage(
              isScanner: true,
              boothNumber: widget.boothNumber,
              sessionType: 'start',
            ),
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
