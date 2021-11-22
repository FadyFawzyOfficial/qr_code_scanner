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
  Barcode? barcode;

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
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            buildQrView(context),
            // Show the result of scanned qrcode (in toast message)
            Positioned(bottom: 24, child: buildResult()),
            // Show 2 button to control the camera flash and side (front & back)
            Positioned(top: 24, child: buildControlButtons()),
          ],
        ),
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

  void onQRViewCreated(QRViewController qrViewController) {
    setState(() => this.qrViewController = qrViewController);

    // So is our qr code created (scanned) for the first time,
    // so we want to listen to our scanned data and get the qr code
    // that the camera scanned for us.
    // Then we want to store this inside our state with a barcode variable.
    qrViewController.scannedDataStream
        .listen((barcode) => setState(() => this.barcode = barcode));
  }

  Widget buildResult() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        barcode != null ? 'Result: ${barcode!.code}' : 'Scan a code!',
        maxLines: 3,
      ),
    );
  }

  Widget buildControlButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.flash_off_rounded),
            onPressed: () async {
              await qrViewController?.toggleFlash();
              setState(() {});
            },
          ),
          IconButton(
            icon: Icon(Icons.switch_camera_rounded),
            onPressed: () async {
              await qrViewController?.flipCamera();
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}
