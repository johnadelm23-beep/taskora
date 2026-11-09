import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:taskora/features/schedule/domain/entities/lecture_entity.dart';

/// Service for exporting saved timetable lecture records from Drift into standard CSV format.
///
/// Features:
/// - Supports both English and Arabic column headers and day names.
/// - Encodes with UTF-8 Byte Order Mark (BOM: \uFEFF) for native Excel and cross-platform compatibility.
/// - Complies with RFC 4180 CSV escaping rules (handling commas, double quotes, and line breaks).
/// - Provides Save to file and Copy/Share to clipboard operations.
class ScheduleCsvExporter {
  static const List<String> englishHeaders = [
    'Weekday',
    'Course Name',
    'Course Code',
    'Start Time',
    'End Time',
    'Instructor',
    'Room',
    'Notes',
  ];

  static const List<String> arabicHeaders = [
    'اليوم',
    'اسم المقرر',
    'كود المقرر',
    'وقت البدء',
    'وقت الانتهاء',
    'المحاضر',
    'القاعة',
    'ملاحظات',
  ];

  static const List<String> englishDays = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  static const List<String> arabicDays = [
    'الأحد',
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
  ];

  /// Generates RFC 4180 compliant CSV string with UTF-8 BOM prefix from a list of [LectureEntity] records.
  static String generateCsv(
    List<LectureEntity> lectures, {
    bool isArabic = false,
  }) {
    final buffer = StringBuffer();

    // 1. Prepend UTF-8 Byte Order Mark (BOM: \uFEFF)
    buffer.write('\uFEFF');

    // 2. Write Header Row
    final headers = isArabic ? arabicHeaders : englishHeaders;
    buffer.write('${headers.map(_escapeCell).join(',')}\r\n');

    // 3. Sort chronologically: dayOfWeek (0-6) ascending, then startTime ascending
    final sortedLectures = List<LectureEntity>.from(lectures)
      ..sort((a, b) {
        final dayCmp = a.dayOfWeek.compareTo(b.dayOfWeek);
        if (dayCmp != 0) return dayCmp;
        return a.startTime.compareTo(b.startTime);
      });

    // 4. Write Data Rows
    for (final lecture in sortedLectures) {
      final dayName = _getDayName(lecture.dayOfWeek, isArabic);
      final row = [
        dayName,
        lecture.courseName,
        lecture.courseCode,
        lecture.startTime,
        lecture.endTime,
        lecture.instructor,
        lecture.room,
        lecture.notes ?? '',
      ];
      buffer.write('${row.map(_escapeCell).join(',')}\r\n');
    }

    return buffer.toString();
  }

  /// Maps day of week (0: Sunday ... 6: Saturday) to day name in requested language.
  static String _getDayName(int dayOfWeek, bool isArabic) {
    final days = isArabic ? arabicDays : englishDays;
    if (dayOfWeek >= 0 && dayOfWeek < days.length) {
      return days[dayOfWeek];
    }
    return dayOfWeek.toString();
  }

  /// Escapes CSV cells according to RFC 4180.
  /// If the value contains commas, quotes, or newlines, wrap in quotes and escape internal quotes.
  static String _escapeCell(String value) {
    if (value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Copies the CSV text content to the system clipboard for easy sharing.
  static Future<bool> copyToClipboard(String csvContent) async {
    try {
      await Clipboard.setData(ClipboardData(text: csvContent));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Prompts user to save the CSV file to device storage.
  static Future<String?> saveCsvFile(
    String csvContent, {
    String? defaultFileName,
  }) async {
    try {
      final bytes = utf8.encode(csvContent);
      final fileName =
          defaultFileName ??
          'taskora_schedule_${DateTime.now().millisecondsSinceEpoch}.csv';

      final resultPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Schedule CSV',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: bytes,
      );

      // On platforms where saveFile returns path without auto-persisting bytes
      if (resultPath != null && resultPath.isNotEmpty) {
        final file = File(resultPath);
        if (!await file.exists() || (await file.length()) == 0) {
          await file.writeAsBytes(bytes, flush: true);
        }
      }

      return resultPath;
    } catch (_) {
      return null;
    }
  }
}
