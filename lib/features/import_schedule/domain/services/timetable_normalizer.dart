import 'package:taskora/features/import_schedule/domain/services/arabic_text_normalizer.dart';

/// Centralized service for normalizing timetable weekdays and times across all
/// import paths (CSV template and freeform PDF/image OCR).
class TimetableNormalizer {
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
    // Spaced Arabic letters from OCR or PDF line glyph separation
    'ا ل س ب ت': 6,
    'ا لأ ح د': 0,
    'ا لإ ث ن ي ن': 1,
    'ا ل ث لا ث ا ء': 2,
    'ا لأ ر ب ع ا ء': 3,
    'ا ل خ م ي س': 4,
    'ا ل ج م ع ة': 5,
  };

  /// Normalizes English and Arabic weekday text into integer representation:
  /// `0: Sunday ... 6: Saturday`.
  ///
  /// Returns `null` if the weekday cannot be recognized. Never silently guesses.
  static int? normalizeWeekday(String? input) {
    if (input == null) return null;
    final cleaned = _normalizeDigits(
      input.replaceAll(RegExp(r'^[=\-*\s#|]+|[=\-*\s#|]+$'), '').trim(),
    );
    if (cleaned.isEmpty) return null;

    final lower = cleaned.toLowerCase();

    // 1. Direct digit string (0..6 where 0 = Sunday)
    final parsedInt = int.tryParse(lower);
    if (parsedInt != null && parsedInt >= 0 && parsedInt <= 6) {
      return parsedInt;
    }

    // 2. English lookup
    if (_englishDays.containsKey(lower)) {
      return _englishDays[lower];
    }

    // 3. Arabic lookup
    final normalizedArabic = ArabicTextNormalizer.cleanAndNormalizeArabic(
      cleaned,
    );
    for (final entry in _arabicDays.entries) {
      if (cleaned == entry.key ||
          lower == entry.key.toLowerCase() ||
          normalizedArabic == entry.key) {
        return entry.value;
      }
    }

    // 4. Substring match for English day
    for (final entry in _englishDays.entries) {
      final regex = RegExp(r'\b' + entry.key + r'\b', caseSensitive: false);
      if (regex.hasMatch(lower)) {
        return entry.value;
      }
    }

    // 5. Substring match for Arabic day
    for (final entry in _arabicDays.entries) {
      final regex = RegExp(
        r'(^|\s|[|,-])' + RegExp.escape(entry.key) + r'($|\s|[|,-])',
      );
      if (regex.hasMatch(cleaned) || regex.hasMatch(normalizedArabic)) {
        return entry.value;
      }
    }

    return null;
  }

  /// Normalizes a single time string (e.g., "9:00 AM", "09:00", "01:30 PM", "9:00 ص")
  /// into standard 24-hour `HH:mm` format.
  ///
  /// Returns `null` if the input is not a recognized valid time format.
  static String? normalizeTime(
    String? input, {
    bool assumeAfternoonForSmallHours = false,
  }) {
    if (input == null) return null;
    final cleaned = _normalizeDigits(input.trim());
    if (cleaned.isEmpty) return null;

    // Pattern matching:
    // Group 1: Hour (0..23)
    // Group 2: Minute (0..59)
    // Group 3: Period indicator (am, pm, ص, م, صباحاً, مساءً)
    final timePattern = RegExp(
      r'^\s*([01]?[0-9]|2[0-3])(?::|\.)([0-5][0-9])(?:\s*(am|pm|a\.m\.|p\.m\.|ص|م|صباحاً|مساءً))?\s*$',
      caseSensitive: false,
    );

    final match = timePattern.firstMatch(cleaned);
    if (match != null) {
      final hour = int.parse(match.group(1)!);
      final minute = int.parse(match.group(2)!);
      final period = match.group(3);

      return _to24Hour(
        hour,
        minute,
        period,
        assumeAfternoonForSmallHours: assumeAfternoonForSmallHours,
      );
    }

    // Match hour without minutes if period is present (e.g. "9 AM", "1 PM", "9 ص")
    final hourOnlyPattern = RegExp(
      r'^\s*([01]?[0-9]|2[0-3])\s*(am|pm|a\.m\.|p\.m\.|ص|م|صباحاً|مساءً)\s*$',
      caseSensitive: false,
    );
    final hourOnlyMatch = hourOnlyPattern.firstMatch(cleaned);
    if (hourOnlyMatch != null) {
      final hour = int.parse(hourOnlyMatch.group(1)!);
      final period = hourOnlyMatch.group(2);
      return _to24Hour(
        hour,
        0,
        period,
        assumeAfternoonForSmallHours: assumeAfternoonForSmallHours,
      );
    }

    // If input contains a time token anywhere in the string, extract the first valid time
    final tokenPattern = RegExp(
      r'\b([01]?[0-9]|2[0-3])(?::|\.)([0-5][0-9])(?:\s*(am|pm|a\.m\.|p\.m\.|ص|م|صباحاً|مساءً))?\b',
      caseSensitive: false,
    );
    final tokenMatch = tokenPattern.firstMatch(cleaned);
    if (tokenMatch != null) {
      final hour = int.parse(tokenMatch.group(1)!);
      final minute = int.parse(tokenMatch.group(2)!);
      final period = tokenMatch.group(3);
      return _to24Hour(
        hour,
        minute,
        period,
        assumeAfternoonForSmallHours: assumeAfternoonForSmallHours,
      );
    }

    return null;
  }

  static String _to24Hour(
    int hour,
    int minute,
    String? period, {
    bool assumeAfternoonForSmallHours = false,
  }) {
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
    } else if (assumeAfternoonForSmallHours) {
      // Common college timetable heuristic: 1:00 to 6:00 is afternoon/evening PM
      if (h >= 1 && h <= 6) {
        h += 12;
      }
    }

    final hStr = h.toString().padLeft(2, '0');
    final mStr = minute.toString().padLeft(2, '0');
    return '$hStr:$mStr';
  }

  /// Converts Arabic numerals (٠-٩) to Western standard digits (0-9).
  static String _normalizeDigits(String input) {
    var text = input;
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    for (int i = 0; i < 10; i++) {
      text = text.replaceAll(arabicDigits[i], i.toString());
    }
    return text;
  }

  /// Human-readable English or Arabic weekday name for display.
  static String formatWeekday(int? day, {bool isArabic = false}) {
    if (day == null || day < 0 || day > 6) {
      return isArabic ? 'غير محدد' : 'Unspecified';
    }
    const englishNames = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    const arabicNames = [
      'الأحد',
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
    ];
    return isArabic ? arabicNames[day] : englishNames[day];
  }
}
