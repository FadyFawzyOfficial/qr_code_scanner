import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_code_example/pages/home_page.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class BoothScannerPage extends StatefulWidget {
  final int boothNumber;
  final String sessionType;

  const BoothScannerPage({
    Key? key,
    required this.boothNumber,
    required this.sessionType,
  }) : super(key: key);

  @override
  _BoothScannerPageState createState() => _BoothScannerPageState();
}

class _BoothScannerPageState extends State<BoothScannerPage> {
  final qrKey = GlobalKey(debugLabel: 'QR');

  bool _isLoading = false;
  bool _isCompleted = false;
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
      appBar: AppBar(
        title: const Text('Booth Scanner'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : _isCompleted
                    ? Center(
                        child: FlatButton(
                          color: Theme.of(context).primaryColor,
                          child: const Text('Scan Again'),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HomePage(),
                              ),
                            );
                          },
                        ),
                      )
                    : buildQrView(context),
            if (!_isLoading || _isCompleted)
              // Show the result of scanned qrcode (in toast message)
              Positioned(bottom: 24, child: buildResult()),
            if (!_isLoading || _isCompleted)
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
    qrViewController.scannedDataStream.first.then((scanData) {
      setState(() => this.barcode = scanData);

      //* Note that because onQRViewCreated function listens to a stream it will
      //* fire multiple times before we can check the result.
      //! This could lead to launching multiple instances of the same page.
      //* To prevent that we pause and resume camera work when we check for
      //* validity of found data.
      // qrViewController.pauseCamera();

      showDialog<String>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Visitor'),
          content: Text('Visitor Code: ${barcode!.code}'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, 'Cancel'),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Find the ScaffoldMessenger in the widget tree
                // and use it to show a SnackBar.
                post();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });
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
            // Display Flash icon depend on Flash Status of Camera
            icon: FutureBuilder<bool?>(
                future: qrViewController?.getFlashStatus(),
                builder: (context, snapshot) {
                  if (snapshot.data != null)
                    return snapshot.data!
                        ? Icon(Icons.flash_on_rounded)
                        : Icon(Icons.flash_off_rounded);
                  else
                    return Container();
                }),
            onPressed: () async {
              await qrViewController?.toggleFlash();
              setState(() {});
            },
          ),
          IconButton(
            // Display Switch Camera Icon if camera info (front one) is available
            icon: FutureBuilder(
                future: qrViewController?.getCameraInfo(),
                builder: (context, snapshot) {
                  if (snapshot.data != null)
                    return Icon(Icons.switch_camera_rounded);
                  else
                    return Container();
                }),
            onPressed: () async {
              await qrViewController?.flipCamera();
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Future<void> post() async {
    try {
      setState(() {
        _isLoading = true;
      });
      await http.post(
        Uri.parse('https://expo5.macber-eg.com/api/session'),
        body: json.encode({
          'type': '${widget.sessionType}',
          'pos': '${widget.boothNumber}',
          'visitor_id': '${barcode!.code}',
        }),
        headers: {
          'Content-Type': 'application/json',
        },
      ).then((response) {
        print(response.body);
        setState(() {
          _isCompleted = true;
          _isLoading = false;
        });
      });
    } catch (error) {
      // Throw the error to handle it in Widget level
      throw error;
    }
  }
}
