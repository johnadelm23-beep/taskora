import 'package:taskora/features/import_schedule/domain/entities/canonical_timetable_entry.dart';
import 'package:taskora/features/import_schedule/domain/entities/extracted_lecture_candidate.dart';
import 'package:taskora/features/import_schedule/domain/services/arabic_text_normalizer.dart';
import 'package:taskora/features/import_schedule/domain/services/timetable_normalizer.dart';

/// Parses timetable files in CSV format into canonical timetable entries.
///
/// Standard CSV Header schema:
/// - Weekday (required)
/// - Course Name (required)
/// - Start Time (required)
/// - End Time (required)
/// - Instructor (optional)
/// - Room (optional)
class CsvTimetableParser {
  static const List<String> standardHeaders = [
    'Weekday',
    'Course Name',
    'Start Time',
    'End Time',
    'Instructor',
    'Room',
  ];

  static int candidateCounter = 0;

  /// Parses CSV text content into a list of [CanonicalTimetableEntry] objects.
  List<CanonicalTimetableEntry> parseToCanonical(String csvContent) {
    if (csvContent.trim().isEmpty) return [];

    final rawLines = _splitCsvLines(csvContent);
    if (rawLines.isEmpty) return [];

    int? headerRowIndex;
    Map<String, int>? columnIndices;

    // 1. Identify header row
    for (var i = 0; i < rawLines.length; i++) {
      final cells = _parseCsvRow(rawLines[i]);
      final indices = _matchHeaderIndices(cells);
      if (indices != null) {
        headerRowIndex = i;
        columnIndices = indices;
        break;
      }
    }

    if (headerRowIndex == null || columnIndices == null) {
      // If no valid header found, throw or return empty list
      return [];
    }

    final results = <CanonicalTimetableEntry>[];

    // 2. Parse data rows following the header
    for (var i = headerRowIndex + 1; i < rawLines.length; i++) {
      final line = rawLines[i].trim();
      if (line.isEmpty) continue;

      // Ignore comment lines
      if (line.startsWith('#') || line.startsWith('//')) {
        continue;
      }

      final cells = _parseCsvRow(line);
      if (cells.isEmpty) continue;

      // Extract values by header column index
      final rawDay = _getCell(cells, columnIndices['weekday']!);
      final rawCourse = _getCell(cells, columnIndices['courseName']!);
      final rawStart = _getCell(cells, columnIndices['startTime']!);
      final rawEnd = _getCell(cells, columnIndices['endTime']!);
      final rawInstructor = _getCell(cells, columnIndices['instructor']);
      final rawRoom = _getCell(cells, columnIndices['room']);

      // Skip example rows
      final upperCourse = rawCourse.toUpperCase();
      if (upperCourse.contains('[EXAMPLE]') ||
          upperCourse.startsWith('EXAMPLE') ||
          upperCourse.contains('EXAMPLE ROW')) {
        continue;
      }

      // Check if all cells are empty
      if (rawDay.isEmpty &&
          rawCourse.isEmpty &&
          rawStart.isEmpty &&
          rawEnd.isEmpty) {
        continue;
      }

      // Normalize weekday
      final normalizedDay = TimetableNormalizer.normalizeWeekday(rawDay);

      // Normalize times
      final normalizedStart = TimetableNormalizer.normalizeTime(rawStart);
      final normalizedEnd = TimetableNormalizer.normalizeTime(rawEnd);

      // Clean text fields
      final cleanedCourse = ArabicTextNormalizer.cleanAndNormalizeArabic(
        rawCourse,
      );
      final cleanedInstructor = ArabicTextNormalizer.cleanAndNormalizeArabic(
        rawInstructor,
      );
      final cleanedRoom = ArabicTextNormalizer.cleanAndNormalizeArabic(rawRoom);

      // Extract optional course code if present inside course name (e.g., "CS302 Mobile Apps")
      final courseCodeMatch = RegExp(
        r'\b([A-Z]{2,6}[-\s]?[0-9]{3,4}[A-Z]?)\b',
      ).firstMatch(cleanedCourse);
      final courseCode = courseCodeMatch?.group(1)?.replaceAll(' ', '') ?? '';

      results.add(
        CanonicalTimetableEntry(
          weekday: normalizedDay,
          courseName: cleanedCourse,
          courseCode: courseCode,
          startTime: normalizedStart,
          endTime: normalizedEnd,
          instructor: cleanedInstructor,
          room: cleanedRoom,
          rawWeekday: rawDay,
          rawStartTime: rawStart,
          rawEndTime: rawEnd,
        ),
      );
    }

    return results;
  }

  /// Parses CSV text and directly outputs [ExtractedLectureCandidate] list for the review UI.
  List<ExtractedLectureCandidate> parseToCandidates(String csvContent) {
    final canonicalEntries = parseToCanonical(csvContent);
    final results = <ExtractedLectureCandidate>[];

    for (final entry in canonicalEntries) {
      final id =
          'csv_${DateTime.now().microsecondsSinceEpoch}_${candidateCounter++}';
      results.add(entry.toCandidate(id: id));
    }

    return results;
  }

  /// Maps CSV header column names to their 0-indexed column positions.
  /// Requires at least Weekday, Course Name, Start Time, and End Time.
  Map<String, int>? _matchHeaderIndices(List<String> cells) {
    if (cells.length < 4) return null;

    int? weekdayIdx;
    int? courseNameIdx;
    int? startTimeIdx;
    int? endTimeIdx;
    int? instructorIdx;
    int? roomIdx;

    for (var i = 0; i < cells.length; i++) {
      final name = cells[i].trim().toLowerCase();

      // Weekday / Day / اليوم
      if (_matchesHeader(name, [
        'weekday',
        'day',
        'day of week',
        'اليوم',
        'يوم',
      ])) {
        weekdayIdx = i;
      }
      // Course Name / Course / Subject / اسم المقرر / المقرر
      else if (_matchesHeader(name, [
        'course name',
        'course',
        'subject',
        'course title',
        'title',
        'اسم المقرر',
        'المقرر',
        'المادة',
      ])) {
        courseNameIdx = i;
      }
      // Start Time / Start / وقت البدء / البداية
      else if (_matchesHeader(name, [
        'start time',
        'start',
        'from',
        'وقت البدء',
        'وقت البداية',
        'البداية',
        'من',
      ])) {
        startTimeIdx = i;
      }
      // End Time / End / وقت الانتهاء / النهاية
      else if (_matchesHeader(name, [
        'end time',
        'end',
        'to',
        'وقت الانتهاء',
        'وقت النهاية',
        'النهاية',
        'إلى',
        'الى',
      ])) {
        endTimeIdx = i;
      }
      // Instructor / Teacher / Professor / المحاضر / الدكتور
      else if (_matchesHeader(name, [
        'instructor',
        'teacher',
        'professor',
        'doctor',
        'dr',
        'المحاضر',
        'الدكتور',
        'الأستاذ',
        'المدرس',
      ])) {
        instructorIdx = i;
      }
      // Room / Hall / Location / Lab / القاعة / المعمل
      else if (_matchesHeader(name, [
        'room',
        'hall',
        'location',
        'lab',
        'classroom',
        'building',
        'القاعة',
        'المعمل',
        'المختبر',
        'المكان',
      ])) {
        roomIdx = i;
      }
    }

    // Required headers must all be present
    if (weekdayIdx == null ||
        courseNameIdx == null ||
        startTimeIdx == null ||
        endTimeIdx == null) {
      return null;
    }

    return {
      'weekday': weekdayIdx,
      'courseName': courseNameIdx,
      'startTime': startTimeIdx,
      'endTime': endTimeIdx,
      'instructor': instructorIdx ?? -1,
      'room': roomIdx ?? -1,
    };
  }

  bool _matchesHeader(String text, List<String> options) {
    final cleaned = text
        .replaceAll(RegExp(r'[\s_]+'), ' ')
        .trim()
        .toLowerCase();
    for (final opt in options) {
      if (cleaned == opt.toLowerCase()) return true;
    }
    for (final opt in options) {
      final regex = RegExp(
        r'(^|\s)' + RegExp.escape(opt.toLowerCase()) + r'($|\s)',
      );
      if (regex.hasMatch(cleaned)) return true;
    }
    return false;
  }

  String _getCell(List<String> cells, int? index) {
    if (index == null || index < 0 || index >= cells.length) return '';
    return cells[index].trim();
  }

  /// Splits CSV content by lines, respecting multi-line quoted fields.
  List<String> _splitCsvLines(String content) {
    final lines = <String>[];
    final sb = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < content.length; i++) {
      final char = content[i];
      if (char == '"') {
        inQuotes = !inQuotes;
        sb.write(char);
      } else if ((char == '\n' || char == '\r') && !inQuotes) {
        if (char == '\r' && i + 1 < content.length && content[i + 1] == '\n') {
          i++; // Skip \n in \r\n
        }
        final line = sb.toString();
        if (line.trim().isNotEmpty) {
          lines.add(line);
        }
        sb.clear();
      } else {
        sb.write(char);
      }
    }

    final remaining = sb.toString();
    if (remaining.trim().isNotEmpty) {
      lines.add(remaining);
    }

    return lines;
  }

  /// Parses a single CSV line into cells, handling comma, semicolon, tab, and quotes.
  List<String> _parseCsvRow(String line) {
    // Detect delimiter: check whether commas, semicolons, or tabs are used
    var delimiter = ',';
    if (!line.contains(',') && line.contains(';')) {
      delimiter = ';';
    } else if (!line.contains(',') &&
        !line.contains(';') &&
        line.contains('\t')) {
      delimiter = '\t';
    }

    final cells = <String>[];
    final sb = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          sb.write('"');
          i++; // Skip escaped quote
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == delimiter && !inQuotes) {
        cells.add(sb.toString().trim());
        sb.clear();
      } else {
        sb.write(char);
      }
    }

    cells.add(sb.toString().trim());
    return cells;
  }
}
