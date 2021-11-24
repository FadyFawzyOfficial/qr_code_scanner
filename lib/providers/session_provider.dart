import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/session.dart';

class SessionProvider with ChangeNotifier {
  static const String sessionListKey = 'SESSIONLIST';
  List<Session> sessions = [];

  String convertListToJson(List<Session> sessions) => json.encode(sessions
      .map<Map<String, dynamic>>((session) => session.toMap())
      .toList());

  List<Session> convertJsonToList(String sessionMap) =>
      (json.decode(sessionMap) as List<dynamic>)
          .map<Session>((session) => Session.fromMap(session))
          .toList();

  Future<void> addSession(Session session) async {
    sessions.add(session);
    await updateSessionList();
    notifyListeners();
  }

  Future<void> updateSessionList() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(sessionListKey, convertListToJson(sessions));
  }

  Future<void> retrieveSesssionList() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.containsKey(sessionListKey)
        ? sessions = convertJsonToList(prefs.getString(sessionListKey)!)
        : sessions = [];
  }
}
