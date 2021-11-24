import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/call_back.dart';
import 'home_page.dart';

class IntroPage extends StatefulWidget {
  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  static const scannerKey = 'ScannerKey';
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late Future<bool?> _isScanner;
  late bool isScanner;

  @override
  void initState() {
    super.initState();
    _isScanner = _prefs.then((prefs) => prefs.getBool(scannerKey));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanning Method'),
      ),
      body: Center(
        child: FutureBuilder<bool?>(
          future: _isScanner,
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
                return const CircularProgressIndicator();
              case ConnectionState.done:
              default:
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (snapshot.hasData)
                  return CallBack(isScanner: snapshot.data!);
                else
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FlatButton(
                        child: Text('By Camera'),
                        textColor: Colors.white,
                        color: Theme.of(context).primaryColor,
                        onPressed: () => setScanner(false).then(
                          (_) => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HomePage(
                                isScanner: false,
                              ),
                            ),
                          ),
                        ),
                      ),
                      FlatButton(
                        child: Text('By Scanner'),
                        textColor: Colors.white,
                        color: Theme.of(context).primaryColor,
                        onPressed: () => setScanner(true).then(
                          (_) => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HomePage(
                                isScanner: true,
                              ),
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

  Future<void> setScanner(bool value) async {
    final SharedPreferences prefs = await _prefs;
    setState(() {
      isScanner = value;
      _isScanner =
          prefs.setBool(scannerKey, isScanner).then((value) => isScanner);
    });
  }
}
