import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SyncData extends StatefulWidget {
  const SyncData({Key? key}) : super(key: key);

  @override
  _SyncDataState createState() => _SyncDataState();
}

class _SyncDataState extends State<SyncData> {
  String path = '';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Data'),
      ),
      body: Center(
        child: FutureBuilder(
          future: retrievePath(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done)
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 60,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text('Result: Data Loaded'),
                  )
                ],
              );
            else
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    child: CircularProgressIndicator(),
                    width: 60,
                    height: 60,
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text('Awaiting result...'),
                  )
                ],
              );
          },
        ),
      ),
    );
  }

  Future<void> retrievePath() async {
    print('Path $path');
    print('Start retrievePath');
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.containsKey('Path') ? path = prefs.getString('Path')! : path = '';

    print(path);
    if (path.isNotEmpty) {
      await postAll().then((_) {
        int fileNumber = path.indexOf('.csv') - 1;
        int newFileNumber = int.parse(path[fileNumber]) + 1;
        String newPath = path.replaceRange(
            fileNumber, fileNumber + 1, newFileNumber.toString());
        print('NewPath: $newPath');
        prefs.setString('Path', newPath);
      });
    }
  }

  Future<void> postAll() async {
    print('Start postAll');
    await convertCsvDataToJson().then(
      (jsonList) async {
        for (String json in jsonList) await postOneJson(json);
      },
    );
  }

  Future<void> postOneJson(String json) async {
    print('Start postOneJson');
    print(json);
    try {
      final response = await http.post(
        Uri.parse('https://expo5.macber-eg.com/api/session'),
        body: json,
        headers: {
          'Content-Type': 'application/json',
        },
      );
      print(response.body);
    } catch (error) {
      // Throw the error to handle it in Widget level
      throw error;
    }
  }

  Future<List<String>> convertCsvDataToJson() async {
    print('Start convertCsvDataToJson');
    return await readCsvData().then(
      (data) {
        print(data);
        return data.map(
          (row) {
            print(row);
            return json.encode(
              {
                'type': '${row[0]}',
                'pos': '${row[1]}',
                'visitor_id': '${row[2]}',
                'date': '${row[3]}'
              },
            );
          },
        ).toList();
      },
    );
  }

  Future<List<List<dynamic>>> readCsvData() async {
    print('Start readCsvData');
    print(path);
    final csvFile = new File(path).openRead();
    return await csvFile
        .transform(utf8.decoder)
        .transform(
          CsvToListConverter(),
        )
        .toList();
  }
}
