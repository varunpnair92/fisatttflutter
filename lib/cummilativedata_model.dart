class CumulativeData {
  final String className;
  final String subjectName;
  final String dates;

  CumulativeData({
    required this.className,
    required this.subjectName,
    required this.dates,
  });

  factory CumulativeData.fromJson(Map<String, dynamic> json) {
    return CumulativeData(
      className: json["class_name"],
      subjectName: json["subject_name"],
      dates: json["dates"],
    );
  }
}
