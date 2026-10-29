import 'package:taskora/features/import_schedule/domain/entities/canonical_timetable_entry.dart';
import 'package:taskora/features/import_schedule/domain/entities/extracted_lecture_candidate.dart';
import 'package:taskora/features/import_schedule/domain/services/arabic_text_normalizer.dart';

class TimetableParser {
  static const Map<String, int> _englishDays = {
    'sunday': 0,
    'sun': 0,
    'monday': 1,
    'mon': 1,
    'tuesday': 2,
    'tue': 2,
    'tues': 2,
    'wednesday': 3,
    'wed': 3,
    'thursday': 4,
    'thu': 4,
    'thur': 4,
    'thurs': 4,
    'friday': 5,
    'fri': 5,
    'saturday': 6,
    'sat': 6,
  };

  static const Map<String, int> _arabicDays = {
    'الأحد': 0,
    'الاحد': 0,
    'أحد': 0,
    'احد': 0,
    'يوم الأحد': 0,
    'يوم الاحد': 0,
    'الإثنين': 1,
    'الاثنين': 1,
    'إثنين': 1,
    'اثنين': 1,
    'يوم الإثنين': 1,
    'يوم الاثنين': 1,
    'الثلاثاء': 2,
    'ثلاثاء': 2,
    'يوم الثلاثاء': 2,
    'الأربعاء': 3,
    'الاربعاء': 3,
    'أربعاء': 3,
    'اربعاء': 3,
    'يوم الأربعاء': 3,
    'يوم الاربعاء': 3,
    'الخميس': 4,
    'خميس': 4,
    'يوم الخميس': 4,
    'الجمعة': 5,
    'جمعة': 5,
    'يوم الجمعة': 5,
    'السبت': 6,
    'سبت': 6,
    'يوم السبت': 6,
    'ا ل س ب ت': 6,
    'ا لأ ح د': 0,
    'ا لإ ث ن ي ن': 1,
    'ا ل ث لا ث ا ء': 2,
    'ا لأ ر ب ع ا ء': 3,
    'ا ل خ م ي س': 4,
    'ا ل ج م ع ة': 5,
  };

  static int resultsCounter = 0;

  /// Parses the raw OCR/document text into candidate lectures.
  List<ExtractedLectureCandidate> parse(String text) {
    if (text.trim().isEmpty) return [];

    // 1. Clean and normalize Arabic text (repair mojibake, presentation forms, reversed text)
    final cleaned = ArabicTextNormalizer.cleanAndNormalizeArabic(text);

    // 2. Normalize numerals and dashes
    final normalized = _normalizeText(cleaned);

    final candidates = <ExtractedLectureCandidate>[];

    // Strategy 1: Grid Table with Weekday Column Headers (e.g. | الأحد | الاثنين | الثلاثاء |)
    final gridCandidates = _parseByWeekdayColumnGrid(normalized);
    if (gridCandidates.isNotEmpty) {
      candidates.addAll(gridCandidates);
    } else {
      // Strategy 2: Table Rows with cells (e.g. الأحد | 09:00 - 09:45 | علوم الحاسب | ...)
      final rowCandidates = _parseByTableRows(normalized);
      if (rowCandidates.isNotEmpty) {
        candidates.addAll(rowCandidates);
      } else {
        // Strategy 3: Section-based parsing (when text is split by standalone day headers)
        final sectionCandidates = _parseByDaySections(normalized);
        if (sectionCandidates.isNotEmpty) {
          candidates.addAll(sectionCandidates);
        } else {
          // Strategy 4: Free-form blocks / time-slot parsing
          final blockCandidates = _parseByBlocks(normalized);
          candidates.addAll(blockCandidates);
        }
      }
    }

    // Deduplicate and resolve cross-candidate conflicts
    final deduplicated = _deduplicate(candidates);
    return _detectInternalConflicts(deduplicated);
  }

  /// Parses document text and returns standardized [CanonicalTimetableEntry] objects.
  List<CanonicalTimetableEntry> parseToCanonical(String text) {
    final candidates = parse(text);
    return candidates.map((c) => c.toCanonical()).toList();
  }

  /// Normalizes Arabic digits to western digits and cleans common dash variations.
  String _normalizeText(String input) {
    var text = input;
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    for (int i = 0; i < 10; i++) {
      text = text.replaceAll(arabicDigits[i], i.toString());
    }
    // Replace non-standard dashes with standard hyphen
    text = text.replaceAll(RegExp(r'[–—―]'), '-');
    return text;
  }

  /// Strategy 1: Parses grid tables where columns represent weekdays
  /// Example header: "| Time | Sunday | Monday | Tuesday |"
  /// Example header: "| الوقت | الأحد | الاثنين | الثلاثاء |"
  List<ExtractedLectureCandidate> _parseByWeekdayColumnGrid(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.length < 2) return [];

    final results = <ExtractedLectureCandidate>[];

    // Find header line that contains multiple weekdays
    int? headerLineIdx;
    final colToDay = <int, int>{};

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final cells = _splitCells(line);
      if (cells.length < 2) continue;

      final detectedDays = <int, int>{};
      for (var colIdx = 0; colIdx < cells.length; colIdx++) {
        final cell = cells[colIdx];
        final day = _extractExactDay(cell);
        if (day != null) {
          detectedDays[colIdx] = day;
        }
      }

      // If at least 2 columns are weekdays, this is a weekday column header line
      if (detectedDays.length >= 2) {
        headerLineIdx = i;
        colToDay.addAll(detectedDays);
        break;
      }
    }

    if (headerLineIdx == null || colToDay.isEmpty) return [];

    // Parse data rows below the header
    for (var i = headerLineIdx + 1; i < lines.length; i++) {
      final row = lines[i];
      final cells = _splitCells(row);
      if (cells.isEmpty) continue;

      // Extract time from the row (either in a dedicated time column or within the row)
      final rowTimeRange = _extractTimeRange(row);

      for (var colIdx = 0; colIdx < cells.length; colIdx++) {
        final day = colToDay[colIdx];
        if (day == null) continue;

        final cellText = cells[colIdx].trim();
        if (cellText.isEmpty || cellText == '-' || cellText == '—') continue;

        // Check if the cell has its own time range, otherwise use row time range
        final cellTimeRange = _extractTimeRange(cellText) ?? rowTimeRange;
        if (cellTimeRange == null) continue;

        final courseCode = _extractCourseCode(cellText);
        final instructor = _extractInstructor([cellText]);
        final room = _extractRoom([cellText]);
        final courseName = _extractCourseName(
          lines: [cellText],
          timeRangeRaw: cellTimeRange.rawMatch,
          courseCode: courseCode,
          instructor: instructor,
          room: room,
          dayIndex: day,
        );

        // Do not add if cell text had no recognizable course name or code
        if (courseName.trim().isEmpty &&
            (courseCode == null || courseCode.isEmpty)) {
          continue;
        }

        final id =
            'cand_${DateTime.now().microsecondsSinceEpoch}_${resultsCounter++}';
        results.add(
          ExtractedLectureCandidate(
            id: id,
            courseName: courseName.isNotEmpty ? courseName : (courseCode ?? ''),
            courseCode: courseCode ?? '',
            room: room ?? '',
            instructor: instructor ?? '',
            dayOfWeek: day,
            startTime: cellTimeRange.startTime,
            endTime: cellTimeRange.endTime,
          ),
        );
      }
    }

    return results;
  }

  /// Strategy 2: Parses row-by-row table entries separated by `|` or tabs.
  /// Example: "الأحد | 09:00 - 09:45 | علوم الحاسب | قاعة 102 | د. أحمد"
  List<ExtractedLectureCandidate> _parseByTableRows(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final results = <ExtractedLectureCandidate>[];

    int? runningDay;

    for (final line in lines) {
      final lineTime = _extractTimeRange(line);
      final hasSeparators = line.contains('|') || line.contains('\t');
      final hasOtherContent =
          lineTime != null &&
          line.replaceAll(lineTime.rawMatch, '').trim().length >= 2;

      // Table row must have explicit cell separators or contain both time and lecture content
      if (!hasSeparators && !hasOtherContent) {
        // If line is a day header, track it for subsequent table rows
        final day = _extractDay(line);
        if (day != null) runningDay = day;
        continue;
      }

      final cells = _splitCells(line);
      if (lineTime == null) {
        // Could be a day header row or table header row
        final day = _extractDay(line);
        if (day != null) runningDay = day;
        continue;
      }

      // Detect day in row or inherit running day
      final day = _extractDay(line) ?? runningDay;
      if (day != null) runningDay = day;

      final courseCode = _extractCourseCode(line);
      final instructor = _extractInstructor(cells);
      final room = _extractRoom(cells);
      final courseName = _extractCourseName(
        lines: cells,
        timeRangeRaw: lineTime.rawMatch,
        courseCode: courseCode,
        instructor: instructor,
        room: room,
        dayIndex: day,
      );

      // Do not produce an empty candidate from a non-row line
      if (courseName.trim().isEmpty &&
          (courseCode == null || courseCode.isEmpty)) {
        continue;
      }

      final id =
          'cand_${DateTime.now().microsecondsSinceEpoch}_${resultsCounter++}';
      results.add(
        ExtractedLectureCandidate(
          id: id,
          courseName: courseName.isNotEmpty ? courseName : (courseCode ?? ''),
          courseCode: courseCode ?? '',
          room: room ?? '',
          instructor: instructor ?? '',
          dayOfWeek: day,
          startTime: lineTime.startTime,
          endTime: lineTime.endTime,
        ),
      );
    }

    return results;
  }

  List<String> _splitCells(String line) {
    if (line.contains('|')) {
      return line
          .split('|')
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty)
          .toList();
    }
    return line
        .split(RegExp(r'\t+|\s{3,}'))
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();
  }

  /// Attempts to parse text that is organized under Day Section headers.
  List<ExtractedLectureCandidate> _parseByDaySections(String text) {
    final lines = text.split('\n').map((l) => l.trim()).toList();
    final results = <ExtractedLectureCandidate>[];

    int? currentDay;
    final currentBlockLines = <String>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.isEmpty) {
        if (currentBlockLines.isNotEmpty && currentDay != null) {
          final parsed = _parseBlockLines(
            currentBlockLines,
            defaultDay: currentDay,
          );
          if (parsed != null) results.add(parsed);
          currentBlockLines.clear();
        }
        continue;
      }

      final dayFound = _detectStandaloneDayHeader(line);
      if (dayFound != null) {
        // Flush previous block
        if (currentBlockLines.isNotEmpty && currentDay != null) {
          final parsed = _parseBlockLines(
            currentBlockLines,
            defaultDay: currentDay,
          );
          if (parsed != null) results.add(parsed);
          currentBlockLines.clear();
        }
        currentDay = dayFound;
        continue;
      }

      if (currentDay != null) {
        // If currentBlockLines already contains a time range and this new line also has one,
        // it signals that a previous lecture block has finished and a new one has begun.
        if (_hasTimeRange(line) && currentBlockLines.any(_hasTimeRange)) {
          final parsed = _parseBlockLines(
            currentBlockLines,
            defaultDay: currentDay,
          );
          if (parsed != null) results.add(parsed);
          currentBlockLines.clear();
        }
        currentBlockLines.add(line);
      }
    }

    // Flush last block
    if (currentBlockLines.isNotEmpty && currentDay != null) {
      final parsed = _parseBlockLines(
        currentBlockLines,
        defaultDay: currentDay,
      );
      if (parsed != null) results.add(parsed);
    }

    return results;
  }

  /// Parses text by looking for time-slot blocks across the entire document.
  List<ExtractedLectureCandidate> _parseByBlocks(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) return [];

    final results = <ExtractedLectureCandidate>[];

    // Group lines into blocks whenever a new line with a time range is encountered
    var currentGroup = <String>[];
    int? runningDay;

    for (final line in lines) {
      final dayInLine = _extractDay(line);
      if (dayInLine != null) {
        runningDay = dayInLine;
      }

      if (_hasTimeRange(line) && currentGroup.any(_hasTimeRange)) {
        // Flush current group as candidate
        final candidate = _parseBlockLines(
          currentGroup,
          defaultDay: runningDay,
        );
        if (candidate != null) results.add(candidate);
        currentGroup = [line];
      } else {
        currentGroup.add(line);
      }
    }

    if (currentGroup.isNotEmpty) {
      final candidate = _parseBlockLines(currentGroup, defaultDay: runningDay);
      if (candidate != null) results.add(candidate);
    }

    return results;
  }

  ExtractedLectureCandidate? _parseBlockLines(
    List<String> lines, {
    int? defaultDay,
  }) {
    final fullBlockText = lines.join(' ');
    final timeRange = _extractTimeRange(fullBlockText);
    if (timeRange == null) return null;

    final day = _extractDay(fullBlockText) ?? defaultDay;
    final courseCode = _extractCourseCode(fullBlockText);
    final instructor = _extractInstructor(lines);
    final room = _extractRoom(lines);
    final courseName = _extractCourseName(
      lines: lines,
      timeRangeRaw: timeRange.rawMatch,
      courseCode: courseCode,
      instructor: instructor,
      room: room,
      dayIndex: day,
    );

    // Do not create a candidate if the block only contains a time range with no course info
    if (courseName.trim().isEmpty &&
        (courseCode == null || courseCode.isEmpty) &&
        (instructor == null || instructor.isEmpty) &&
        (room == null || room.isEmpty)) {
      return null;
    }

    final id =
        'cand_${DateTime.now().microsecondsSinceEpoch}_${resultsCounter++}';

    return ExtractedLectureCandidate(
      id: id,
      courseName: courseName.isNotEmpty ? courseName : (courseCode ?? ''),
      courseCode: courseCode ?? '',
      room: room ?? '',
      instructor: instructor ?? '',
      dayOfWeek: day,
      startTime: timeRange.startTime,
      endTime: timeRange.endTime,
    );
  }

  bool _hasTimeRange(String text) {
    return _extractTimeRange(text) != null;
  }

  /// Finds standalone day header on a line (e.g. "Monday", "--- Monday ---", "الأحد")
  int? _detectStandaloneDayHeader(String line) {
    final cleaned = line
        .replaceAll(RegExp(r'^[=\-*\s#|]+|[=\-*\s#|]+$'), '')
        .trim()
        .toLowerCase();
    if (_englishDays.containsKey(cleaned)) {
      return _englishDays[cleaned];
    }
    for (final entry in _arabicDays.entries) {
      if (cleaned == entry.key.toLowerCase()) {
        return entry.value;
      }
    }
    return null;
  }

  /// Exact day matcher for a table cell (e.g. "Sunday", "الأحد")
  int? _extractExactDay(String cell) {
    final cleaned = cell
        .replaceAll(RegExp(r'^[=\-*\s#|]+|[=\-*\s#|]+$'), '')
        .trim();
    if (_englishDays.containsKey(cleaned.toLowerCase())) {
      return _englishDays[cleaned.toLowerCase()];
    }
    for (final entry in _arabicDays.entries) {
      if (cleaned.toLowerCase() == entry.key.toLowerCase()) {
        return entry.value;
      }
    }
    return null;
  }

  /// Extracts weekday from arbitrary text snippet.
  int? _extractDay(String text) {
    final lower = text.toLowerCase();
    for (final entry in _englishDays.entries) {
      final regex = RegExp(r'\b' + entry.key + r'\b', caseSensitive: false);
      if (regex.hasMatch(lower)) {
        return entry.value;
      }
    }
    for (final entry in _arabicDays.entries) {
      final regex = RegExp(
        r'(^|\s|[|,-])' + RegExp.escape(entry.key) + r'($|\s|[|,-])',
      );
      if (regex.hasMatch(text)) {
        return entry.value;
      }
    }
    return null;
  }

  /// Matches time range like "09:00 - 10:30", "9:00 AM to 10:30 AM", "08:00 إلى 09:30", "09:45 - 09:00",
  /// or table columns like "09:00 AM | 10:30 AM" or "09:00 AM 10:30 AM".
  /// Note: Preserves exact start and end values as matched. Does NOT automatically swap reversed times.
  _TimeRangeResult? _extractTimeRange(String text) {
    // 1. Explicit range separators (dash, en-dash, em-dash, to, إلى, slash, or pipe column boundary)
    final explicitSeparatorPattern = RegExp(
      r'([01]?[0-9]|2[0-3])(?::|\.)([0-5][0-9])(?:\s*(am|pm|a\.m\.|p\.m\.|ص|م|صباحاً|مساءً))?'
      r'\s*(?:-|–|—|to|TO|إلى|الى|\/|\|)\s*'
      r'([01]?[0-9]|2[0-3])(?::|\.)([0-5][0-9])(?:\s*(am|pm|a\.m\.|p\.m\.|ص|م|صباحاً|مساءً))?',
      caseSensitive: false,
    );

    // 2. Whitespace-separated times (common across Start Time / End Time table columns)
    final spaceSeparatedPattern = RegExp(
      r'([01]?[0-9]|2[0-3])(?::|\.)([0-5][0-9])(?:\s*(am|pm|a\.m\.|p\.m\.|ص|م|صباحاً|مساءً))?'
      r'\s+'
      r'([01]?[0-9]|2[0-3])(?::|\.)([0-5][0-9])(?:\s*(am|pm|a\.m\.|p\.m\.|ص|م|صباحاً|مساءً))?',
      caseSensitive: false,
    );

    final match =
        explicitSeparatorPattern.firstMatch(text) ??
        spaceSeparatedPattern.firstMatch(text);

    if (match != null) {
      final startH = int.parse(match.group(1)!);
      final startM = int.parse(match.group(2)!);
      final startPeriod = match.group(3);

      final endH = int.parse(match.group(4)!);
      final endM = int.parse(match.group(5)!);
      final endPeriod = match.group(6);

      final start24 = _to24Hour(
        startH,
        startM,
        startPeriod ??
            (endPeriod != null && endPeriod.toLowerCase().contains('am')
                ? endPeriod
                : null),
      );
      final end24 = _to24Hour(endH, endM, endPeriod ?? startPeriod);

      // Note: Preserve matched order as specified in requirements.
      // If end time is earlier than start time (e.g. 09:45 - 09:00),
      // mark candidate as invalid and request correction. Do NOT silently swap.
      return _TimeRangeResult(
        startTime: start24,
        endTime: end24,
        rawMatch: match.group(0)!,
      );
    }

    return null;
  }

  String _to24Hour(int hour, int minute, String? period) {
    var h = hour;
    if (period != null) {
      final p = period.toLowerCase();
      final isPm =
          p.contains('pm') ||
          p.contains('p.m') ||
          p.contains('م') ||
          p.contains('مساء');
      final isAm =
          p.contains('am') ||
          p.contains('a.m') ||
          p.contains('ص') ||
          p.contains('صباح');

      if (isPm && h < 12) h += 12;
      if (isAm && h == 12) h = 0;
    } else {
      // Common college timetable heuristic: 1:00 to 6:00 is afternoon/evening PM
      if (h >= 1 && h <= 6) {
        h += 12;
      }
    }

    final hStr = h.toString().padLeft(2, '0');
    final mStr = minute.toString().padLeft(2, '0');
    return '$hStr:$mStr';
  }

  /// Extracts standard course codes like CS302, MATH 201, PHYS-101, IT401, EE210.
  String? _extractCourseCode(String text) {
    final regex = RegExp(r'\b([A-Z]{2,6}[-\s]?[0-9]{3,4}[A-Z]?)\b');
    final match = regex.firstMatch(text);
    return match?.group(1)?.replaceAll(' ', '');
  }

  /// Extracts instructor names prefixed with Dr., Prof., Eng., د., أ.د., م., etc.
  String? _extractInstructor(List<String> lines) {
    final instructorPrefixes = RegExp(
      r'^(Dr\.?|Prof\.?|Eng\.?|Doctor|Professor|Instructor:?|Lecturer:?|Teacher:?|د[\./]|أ\.د[\./]?|م[\./]|مهندس:?|معيد:?|دكتور|أستاذ:?)\s*(.+)$',
      caseSensitive: false,
    );

    for (final line in lines) {
      final trimmed = line.trim();
      final match = instructorPrefixes.firstMatch(trimmed);
      if (match != null) {
        final prefix = match.group(1)?.trim() ?? '';
        final name = match.group(2)?.trim() ?? '';
        if (name.isNotEmpty) {
          final cleanName = name.split(RegExp(r'\s{2,}|[|,;]')).first.trim();
          final fullInstructor = '$prefix $cleanName'.trim();
          return ArabicTextNormalizer.cleanAndNormalizeArabic(fullInstructor);
        }
      }
      // Inline match with boundary stopping before room identifiers or digits
      final inline = RegExp(
        r'(?:^|\s|[|,;])(Dr\.?|Prof\.?|Eng\.?|Doctor|Professor|د[\./]|أ\.د[\./]?|م[\./])\s+([A-Za-z\u0621-\u064A\s]{3,25}?)(?=\s+(?:Room|Hall|Lab|Bldg|Building|Auditorium|قاعة|مدرج|مختبر|\d)|[|,;]|$)',
        caseSensitive: false,
      );
      final inlineMatch = inline.firstMatch(line);
      if (inlineMatch != null) {
        final prefix = inlineMatch.group(1)?.trim() ?? '';
        final name = inlineMatch.group(2)?.trim() ?? '';
        final fullInstructor = '$prefix $name'.trim();
        return ArabicTextNormalizer.cleanAndNormalizeArabic(fullInstructor);
      }
    }
    return null;
  }

  /// Extracts location/hall/room like "Hall 4", "Room 201", "Lab B", "قاعة 102", "معمل 3", "3 معمل".
  String? _extractRoom(List<String> lines) {
    final roomRegex = RegExp(
      r'(?:^|\s|[|,;])(Hall|Room|Lab|Bldg|Building|Auditorium|قاعة|مدرج|مختبر|معمل|مبنى|غرفة)\s*[:#-]?\s*([A-Za-z0-9\u0621-\u064A\s\-]{1,20})',
      caseSensitive: false,
    );
    final invertedRoomRegex = RegExp(
      r'(?:^|\s|[|,;])([0-9]{1,4}|IoT|IOT)\s*(قاعة|مدرج|مختبر|معمل|مبنى|غرفة)',
      caseSensitive: false,
    );

    for (final line in lines) {
      final trimmed = line.trim();
      final match = roomRegex.firstMatch(trimmed);
      if (match != null) {
        final roomType = match.group(1)?.trim() ?? '';
        final roomName = match.group(2)?.trim() ?? '';
        final cleanRoom = '$roomType $roomName'.trim();
        return ArabicTextNormalizer.cleanAndNormalizeArabic(cleanRoom);
      }
      final invMatch = invertedRoomRegex.firstMatch(trimmed);
      if (invMatch != null) {
        final roomNumber = invMatch.group(1)?.trim() ?? '';
        final roomType = invMatch.group(2)?.trim() ?? '';
        final cleanRoom = '$roomType $roomNumber'.trim();
        return ArabicTextNormalizer.cleanAndNormalizeArabic(cleanRoom);
      }
    }
    return null;
  }

  /// Extracts the Course Name by filtering out times, codes, instructors, rooms, and days.
  String _extractCourseName({
    required List<String> lines,
    required String timeRangeRaw,
    String? courseCode,
    String? instructor,
    String? room,
    int? dayIndex,
  }) {
    final singleTimePattern = RegExp(
      r'\b([01]?[0-9]|2[0-3])(?::|\.)[0-5][0-9](?:\s*(?:am|pm|a\.m\.|p\.m\.|ص|م|صباحاً|مساءً))?\b',
      caseSensitive: false,
    );

    for (final line in lines) {
      var candidate = line;

      // Remove time range
      candidate = candidate.replaceAll(timeRangeRaw, '');

      // Remove standalone time tokens
      candidate = candidate.replaceAll(singleTimePattern, '');

      // Remove course code
      if (courseCode != null && courseCode.isNotEmpty) {
        candidate = candidate.replaceAll(courseCode, '');
      }

      // Remove instructor
      if (instructor != null && instructor.isNotEmpty) {
        candidate = candidate.replaceAll(instructor, '');
      }

      // Remove room
      if (room != null && room.isNotEmpty) {
        candidate = candidate.replaceAll(room, '');
      }

      // Remove table column headers if captured
      candidate = candidate.replaceAll(
        RegExp(
          r'\b(Weekday|Course Name|Start Time|End Time|Instructor|Room)\b',
          caseSensitive: false,
        ),
        '',
      );

      // Remove days
      for (final dayKey in _englishDays.keys) {
        candidate = candidate.replaceAll(
          RegExp(r'\b' + dayKey + r'\b', caseSensitive: false),
          '',
        );
      }
      for (final dayKey in _arabicDays.keys) {
        candidate = candidate.replaceAll(dayKey, '');
      }

      // Remove symbols and extraneous boundary punctuation while preserving intra-word hyphens (e.g. Object-Oriented)
      candidate = candidate.replaceAll(RegExp(r'[|:;()\[\]{}#*~`_]'), ' ');
      candidate = candidate.replaceAll(
        RegExp(r'(?:^\s*[-–—]+|[-–—]+\s*$)'),
        ' ',
      );
      candidate = candidate.replaceAll(RegExp(r'\s+[-–—]+\s+'), ' ');
      candidate = candidate.replaceAll(RegExp(r'\s{2,}'), ' ').trim();

      // Normalize Arabic text in the extracted course name
      candidate = ArabicTextNormalizer.cleanAndNormalizeArabic(candidate);

      // Check if candidate string has meaningful course title length
      if (candidate.length >= 2 && !RegExp(r'^\d+$').hasMatch(candidate)) {
        return candidate;
      }
    }

    return '';
  }

  List<ExtractedLectureCandidate> _deduplicate(
    List<ExtractedLectureCandidate> list,
  ) {
    final seen = <String>{};
    final unique = <ExtractedLectureCandidate>[];

    for (final item in list) {
      final key =
          '${item.dayOfWeek}_${item.startTime}_${item.endTime}_${item.courseName.toLowerCase()}_${item.courseCode.toLowerCase()}';
      if (!seen.contains(key)) {
        seen.add(key);
        unique.add(item);
      }
    }
    return unique;
  }

  List<ExtractedLectureCandidate> _detectInternalConflicts(
    List<ExtractedLectureCandidate> list,
  ) {
    final result = <ExtractedLectureCandidate>[];

    for (int i = 0; i < list.length; i++) {
      final current = list[i];
      var hasConflict = false;
      String? conflictReason;

      for (int j = 0; j < list.length; j++) {
        if (i == j) continue;
        final other = list[j];
        if (current.overlapsWith(other)) {
          hasConflict = true;
          conflictReason =
              'Overlaps with: ${other.courseName} (${other.startTime} - ${other.endTime})';
          break;
        }
      }

      result.add(
        current.copyWith(
          hasConflict: hasConflict,
          conflictReason: conflictReason,
        ),
      );
    }

    return result;
  }
}

class _TimeRangeResult {
  final String startTime;
  final String endTime;
  final String rawMatch;

  const _TimeRangeResult({
    required this.startTime,
    required this.endTime,
    required this.rawMatch,
  });
}
