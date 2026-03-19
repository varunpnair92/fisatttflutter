void main() {
  // Sample data extracted from user message
  final json = {
    "L1": [
      {
        "class_name": "S4 CSA",
        "subject_name": "OS",
        "external": "no",
        "hours": "5"
      },
      {
        "class_name": "S4 CSA",
        "subject_name": "OS",
        "external": "no",
        "hours": "6"
      },
      {
        "class_name": "S4 CSA",
        "subject_name": "OS",
        "external": "no",
        "hours": "7"
      },
    ],
  };

  const hourOrder = [1, 2, 3, 4, 8, 5, 6, 7];

  final lbl = json["L1"] as List<dynamic>;

  // Build grouped entries
  final grouped = <String, Map<String, dynamic>>{};
  for (var e in lbl) {
    final key = "${e['class_name']}_${e['subject_name']}_${e['external']}";
    final hours = _parseHours(e['hours']);
    if (hours.isEmpty) continue;

    if (!grouped.containsKey(key)) {
      grouped[key] = {
        'class_name': e['class_name'],
        'subject_name': e['subject_name'],
        'external': e['external'],
        'hours': _normalizeHours(hours, hourOrder),
      };
    } else {
      final existing = (grouped[key]!['hours'] as List<int>);
      existing.addAll(hours);
      grouped[key]!['hours'] = _normalizeHours(existing, hourOrder);
    }
  }

  final groupedValues = grouped.values.toList();
  print('Grouped entries:');
  for (var g in groupedValues) {
    print(
        '  ${g['class_name']} ${g['subject_name']} ${g['external']} -> ${g['hours']}');
  }

  // Build hour map and blocks as generator does
  final todays = groupedValues;
  final hourMap = {for (var h in hourOrder) h: <Map<String, dynamic>>[]};
  for (var e in todays) {
    final hrs = (e['hours'] as List).cast<int>();
    for (var h in hrs) {
      hourMap[h]!.add(e);
    }
  }

  // Create blocks
  final blocks = <Map<String, dynamic>>[];
  List currentEntries = [];
  List<int> currentHours = [];

  bool same(List a, List b) {
    if (a.length != b.length) return false;
    final ak = a
        .map((e) => "${e['class_name']}_${e['subject_name']}_${e['external']}")
        .toList()
      ..sort();
    final bk = b
        .map((e) => "${e['class_name']}_${e['subject_name']}_${e['external']}")
        .toList()
      ..sort();
    for (int i = 0; i < ak.length; i++) {
      if (ak[i] != bk[i]) return false;
    }
    return true;
  }

  for (var h in hourOrder) {
    final entries = hourMap[h]!;
    if (currentHours.isEmpty) {
      currentEntries = List.from(entries);
      currentHours = [h];
      continue;
    }
    if (same(entries, currentEntries)) {
      currentHours.add(h);
    } else {
      blocks.add({
        'entries': List.from(currentEntries),
        'hours': List.from(currentHours)
      });
      currentEntries = List.from(entries);
      currentHours = [h];
    }
  }

  if (currentHours.isNotEmpty) {
    blocks.add({
      'entries': List.from(currentEntries),
      'hours': List.from(currentHours)
    });
  }

  print('Blocks:');
  for (var b in blocks) {
    final hrs = (b['hours'] as List).cast<int>();
    final isFree = (b['entries'] as List).isEmpty;
    print('  ${isFree ? 'FREE' : 'BUSY'} hours=$hrs');
  }
}

List<int> _parseHours(dynamic value) {
  if (value == null) return [];

  var str = value.toString();
  if (str.trim().isEmpty) return [];

  str = str.replaceAll(RegExp(r"[\[\]]"), "");

  final hours = <int>{};
  final tokens = str.split(RegExp(r"[\s,]+"));
  for (var token in tokens) {
    token = token.trim();
    if (token.isEmpty) continue;

    final rangeMatch =
        RegExp(r"^(\d+|lb)\s*[-–—]\s*(\d+|lb)", caseSensitive: false)
            .firstMatch(token);
    if (rangeMatch != null) {
      final start = _parseHourValue(rangeMatch.group(1));
      final end = _parseHourValue(rangeMatch.group(2));
      if (start > 0 && end > 0) {
        final step = start <= end ? 1 : -1;
        for (var i = start; i != end; i += step) {
          hours.add(i);
        }
        hours.add(end);
        continue;
      }
    }

    final h = _parseHourValue(token);
    if (h > 0) hours.add(h);
  }

  return hours.toList();
}

int _parseHourValue(dynamic value) {
  final s = value?.toString().trim().toLowerCase() ?? "";
  if (s.isEmpty) return 0;
  if (s == "lb") return 8;
  return int.tryParse(s) ?? 0;
}

List<int> _normalizeHours(List<int> hours, List<int> hourOrder) {
  final unique = hours.toSet().toList();
  unique.sort((a, b) => hourOrder.indexOf(a).compareTo(hourOrder.indexOf(b)));
  return unique;
}
