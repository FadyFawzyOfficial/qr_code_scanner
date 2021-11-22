import 'dart:io';

import 'package:flutter/material.dart';

import 'package:qr_code_scanner/qr_code_scanner.dart';

class QRScannerPage extends StatefulWidget {
  @override
  _QRScannerPageState createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final qrKey = GlobalKey(debugLabel: 'QR');

  QRViewController? qrViewController;

  @override
  void dispose() {
    qrViewController?.dispose();
    super.dispose();
  }

  // In order to get hot reload to work we need to pause the camera if the
  // platform is android, or resume the camera if the platform is iOS.
  //! Fix the hot reload for the camera on Android and iOS, so this code is
  //! needed to let the hot reloaded works without any issue.
  @override
  void reassemble() async {
    super.reassemble();

    if (Platform.isAndroid) await qrViewController!.pauseCamera();

    qrViewController!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          buildQrView(context),
        ],
      ),
    );
  }

  Widget buildQrView(BuildContext context) => QRView(
        key: qrKey,
        onQRViewCreated: onQRViewCreated,
        overlay: QrScannerOverlayShape(
          borderWidth: 10,
          borderLength: 20,
          borderRadius: 10,
          borderColor: Theme.of(context).accentColor,
          cutOutSize: MediaQuery.of(context).size.width * 0.8,
        ),
      );

  void onQRViewCreated(QRViewController qrViewController) =>
      setState(() => this.qrViewController = qrViewController);
}
