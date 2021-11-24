import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import 'home_page.dart';

class BoothScannerPage extends StatefulWidget {
  final bool isScanner;
  final int boothNumber;
  final String sessionType;

  const BoothScannerPage({
    Key? key,
    required this.isScanner,
    required this.boothNumber,
    required this.sessionType,
  }) : super(key: key);

  @override
  _BoothScannerPageState createState() => _BoothScannerPageState();
}

class _BoothScannerPageState extends State<BoothScannerPage> {
  final controller = TextEditingController();
  final qrKey = GlobalKey(debugLabel: 'QR');

  bool _isLoading = false;
  bool _isCompleted = false;
  QRViewController? qrViewController;
  String? code;
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
    // final sessionProvider =
    //     Provider.of<SessionProvider>(context, listen: false);
    // final sessions = sessionProvider.sessions;

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
                                builder: (context) => HomePage(
                                  isScanner: widget.isScanner,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : widget.isScanner
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: TextField(
                                enabled: true,
                                autocorrect: false,
                                autofocus: true,
                                textInputAction: TextInputAction.done,
                                keyboardType: TextInputType.text,
                                controller: controller,
                                decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: 'Enter a Visitor Code'),
                                onSubmitted: (value) {
                                  print(value);
                                  setState(() {
                                    code = value;
                                  });
                                  showDialog<String>(
                                    context: context,
                                    builder: (BuildContext context) =>
                                        AlertDialog(
                                      title: const Text('Visitor'),
                                      content: Text('Visitor Code: $code'),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            // Find the ScaffoldMessenger in the widget tree
                                            // and use it to show a SnackBar.
                                            writeToCsv(widget.isScanner);
                                          },
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          )
                        : buildQrView(context),
            if (_isCompleted)
              // Show the result of scanned qrcode (in toast message)
              Positioned(bottom: 24, child: buildResult()),
            if (_isCompleted)
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
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => BoothScannerPage(
                      isScanner: widget.isScanner,
                      boothNumber: widget.boothNumber,
                      sessionType: widget.sessionType),
                ),
              ),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Find the ScaffoldMessenger in the widget tree
                // and use it to show a SnackBar.
                writeToCsv(widget.isScanner);
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

  // Future<void> addSession() async {
  //   setState(() {
  //     _isLoading = true;
  //   });

  //   await Provider.of<SessionProvider>(context, listen: false)
  //       .addSession(
  //     Session(
  //       number: '${widget.boothNumber}',
  //       type: '${widget.sessionType}',
  //       visitorId: '${barcode!.code}',
  //       timeStamp: DateTime.now().millisecondsSinceEpoch,
  //     ),
  //   )
  //       .then((_) {
  //     setState(() {
  //       _isCompleted = true;
  //       _isLoading = false;
  //     });
  //   });
  // }

  // Future<void> post() async {
  //   try {
  //     setState(() {
  //       _isLoading = true;
  //     });
  //     await http.post(
  //       Uri.parse('https://expo5.macber-eg.com/api/session'),
  //       body: json.encode({
  //         'type': '${widget.sessionType}',
  //         'pos': '${widget.boothNumber}',
  //         'visitor_id': '${barcode!.code}',
  //       }),
  //       headers: {
  //         'Content-Type': 'application/json',
  //       },
  //     ).then((response) {
  //       print(response.body);
  //       setState(() {
  //         _isCompleted = true;
  //         _isLoading = false;
  //       });
  //     });
  //   } catch (error) {
  //     // Throw the error to handle it in Widget level
  //     throw error;
  //   }
  // }

  Future<void> writeToCsv(bool isScanner) async {
    setState(() {
      _isLoading = true;
    });
    List<List<String>> data = [
      [
        widget.sessionType,
        widget.boothNumber.toString(),
        isScanner ? code! : barcode!.code,
        DateTime.now().millisecondsSinceEpoch.toString(),
        // (DateTime.now().millisecondsSinceEpoch / 1000).round().toString(),
      ],
    ];
    String csvData = ListToCsvConverter().convert(data);
    print('csvData: $csvData');
    final String directory = (await getExternalStorageDirectory())!.path;
    final path = "$directory/booth${widget.boothNumber}.csv";
    print('path: $path');
    final File file = File(path);
    await file
        .writeAsString('$csvData\n', mode: FileMode.writeOnlyAppend)
        .then((_) {
      setState(() {
        _isCompleted = true;
        _isLoading = false;
      });
    });
    // Navigator.of(context).push(
    //   MaterialPageRoute(
    //     builder: (_) {
    //       return LoadCsvDataScreen(path: path);
    //     },
    //   ),
    // );
  }
}
