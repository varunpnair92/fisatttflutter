import 'dart:convert';

Keemmodel keemmodelFromJson(String str) => Keemmodel.fromJson(json.decode(str));

String keemmodelToJson(Keemmodel data) => json.encode(data.toJson());

class Keemmodel {
  List<L1> l7;
  List<L1> l6;
  List<L1> l1;
  List<L1> l2;
  List<L1> l3;
  List<L1> l4;
  List<L1> pgLab;
  List<L1> l5;

  Keemmodel({
    required this.l7,
    required this.l6,
    required this.l1,
    required this.l2,
    required this.l3,
    required this.l4,
    required this.pgLab,
    required this.l5,
  });

  factory Keemmodel.fromJson(Map<String, dynamic> json) => Keemmodel(
    l7: List<L1>.from(json["L7"].map((x) => L1.fromJson(x))),
    l6: List<L1>.from(json["L6"].map((x) => L1.fromJson(x))),
    l1: List<L1>.from(json["L1"].map((x) => L1.fromJson(x))),
    l2: List<L1>.from(json["L2"].map((x) => L1.fromJson(x))),
    l3: List<L1>.from(json["L3"].map((x) => L1.fromJson(x))),
    l4: List<L1>.from(json["L4"].map((x) => L1.fromJson(x))),
    pgLab: List<L1>.from(json["PG LAB"].map((x) => L1.fromJson(x))),
    l5: List<L1>.from(json["L5"].map((x) => L1.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "L7": List<dynamic>.from(l7.map((x) => x.toJson())),
    "L6": List<dynamic>.from(l6.map((x) => x.toJson())),
    "L1": List<dynamic>.from(l1.map((x) => x.toJson())),
    "L2": List<dynamic>.from(l2.map((x) => x.toJson())),
    "L3": List<dynamic>.from(l3.map((x) => x.toJson())),
    "L4": List<dynamic>.from(l4.map((x) => x.toJson())),
    "PG LAB": List<dynamic>.from(pgLab.map((x) => x.toJson())),
    "L5": List<dynamic>.from(l5.map((x) => x.toJson())),
  };
}

class L1 {
  String className;
  String subjectName;
  String day;
  String hours;
  String startDate;
  String endDate;

  L1({
    required this.className,
    required this.subjectName,
    required this.day,
    required this.hours,
    required this.startDate,
    required this.endDate,
  });

  factory L1.fromJson(Map<String, dynamic> json) => L1(
    className: json["class_name"],
    subjectName: json["subject_name"],
    day: json["day"],
    hours: json["hours"],
    startDate: json["start_date"],
    endDate: json["end_date"],
  );

  Map<String, dynamic> toJson() => {
    "class_name": className,
    "subject_name": subjectName,
    "day": day,
    "hours": hours,
    "start_date": startDate,
    "end_date": endDate,
  };
}
