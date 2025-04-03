class Labexternal {
  int? id; // ✅ Make it nullable
  String labName;
  String dayAllotted;
  String hoursAllotted;
  String subjectName;
  String className;
  String startDate;
  String endDate;
  String labexternalExternal;

  Labexternal({
    this.id, // ✅ Nullable to prevent errors
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
        id: json["id"] ?? 0, // ✅ Default to 0 if null
        labName: json["lab_name"] ?? "Unknown",
        dayAllotted: json["day_allotted"] ?? "Unknown",
        hoursAllotted: json["hours_allotted"] ?? "0",
        subjectName: json["subject_name"] ?? "Unknown",
        className: json["class_name"] ?? "Unknown",
        startDate: json["start_date"] ?? "00-00-0000",
        endDate: json["end_date"] ?? "00-00-0000",
        labexternalExternal: json["external"] ?? "",
      );

  Map<String, dynamic> toJson() => {
        "id": id ?? 0, // ✅ Ensure it's not null when encoding
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
