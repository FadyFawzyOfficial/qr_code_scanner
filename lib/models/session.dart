import 'dart:convert';

class Session {
  String number;
  String type;
  String visitorId;
  int timeStamp;

  Session({
    required this.number,
    required this.type,
    required this.visitorId,
    required this.timeStamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'pos': number,
      'visitor_id': visitorId,
      'date': timeStamp,
    };
  }

  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      number: map['type'],
      type: map['pos'],
      visitorId: map['visitor_id'],
      timeStamp: map['date'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Session.fromJson(String source) =>
      Session.fromMap(json.decode(source));
}
