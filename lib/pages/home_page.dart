import 'package:flutter/material.dart';
import 'package:flutter_material_pickers/helpers/show_number_picker.dart';
import 'package:qr_code_example/pages/booth_scanner_page.dart';
import 'package:qr_code_example/widgets/go_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  final bool isScanner;

  const HomePage({Key? key, required this.isScanner}) : super(key: key);
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const boothNumberKey = 'booth_number';
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late Future<int> _boothNumber;
  late int boothNumber;

  @override
  void initState() {
    super.initState();
    _boothNumber = _prefs.then((prefs) => prefs.getInt(boothNumberKey) ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Status'),
      ),
      body: Center(
        child: FutureBuilder<int>(
          future: _boothNumber,
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
                return const CircularProgressIndicator();
              case ConnectionState.done:
              default:
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (snapshot.data == 0)
                  return FlatButton(
                    color: Theme.of(context).primaryColor,
                    child: Text('Pick a Booth'),
                    onPressed: () => showMaterialNumberPicker(
                      context: context,
                      title: "Pick Your Booth",
                      maxNumber: 32,
                      minNumber: 1,
                      selectedNumber: snapshot.data,
                      onChanged: (value) => setBooth(value),
                    ),
                  );
                else if (widget.isScanner)
                  return GoScanner(boothNumber: snapshot.data!);
                else
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        'Booth Number: ${snapshot.data}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      FlatButton(
                        child: Text('Start Session'),
                        color: Theme.of(context).primaryColor,
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BoothScannerPage(
                              isScanner: widget.isScanner,
                              boothNumber: snapshot.data!,
                              sessionType: 'start',
                            ),
                          ),
                        ),
                      ),
                      FlatButton(
                        child: Text('End Session'),
                        color: Theme.of(context).primaryColor,
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BoothScannerPage(
                              isScanner: widget.isScanner,
                              boothNumber: snapshot.data!,
                              sessionType: 'end',
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
            }
          },
        ),
      ),
    );
  }

  Future<void> setBooth(int value) async {
    final SharedPreferences prefs = await _prefs;
    setState(() {
      boothNumber = value;
      _boothNumber = prefs
          .setInt(boothNumberKey, boothNumber)
          .then((value) => boothNumber);
    });
  }
}
