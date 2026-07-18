// To parse this JSON data, do
//
//     final labexternal = labexternalFromJson(jsonString);

import 'dart:convert';

List<Labexternal> labexternalFromJson(String str) => List<Labexternal>.from(
    json.decode(str).map((x) => Labexternal.fromJson(x)));

String labexternalToJson(List<Labexternal> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Labexternal {
  int id;
  String labName;
  String dayAllotted;
  String hoursAllotted;
  String subjectName;
  String className;
  String startDate;
  String endDate;
  String labexternalExternal;

  Labexternal({
    required this.id,
    required this.labName,
    required this.dayAllotted,
    required this.hoursAllotted,
    required this.subjectName,
    required this.className,
    required this.startDate,
    required this.endDate,
    required this.labexternalExternal,
  });

  factory Labexternal.fromJson(Map<String, dynamic> json) => Labexternal(
        id: json["id"],
        labName: json["lab_name"],
        dayAllotted: json["day_allotted"],
        hoursAllotted: json["hours_allotted"],
        subjectName: json["subject_name"],
        className: json["class_name"],
        startDate: json["start_date"],
        endDate: json["end_date"],
        labexternalExternal: json["external"],
      );

  //get id => null;

  Map<String, dynamic> toJson() => {
        "id": id,
        "lab_name": labName,
        "day_allotted": dayAllotted,
        "hours_allotted": hoursAllotted,
        "subject_name": subjectName,
        "class_name": className,
        "start_date": startDate,
        "end_date": endDate,
        "external": labexternalExternal,
      };
}
