import 'package:flutter_test/flutter_test.dart';
import 'package:taskora/features/import_schedule/domain/services/timetable_normalizer.dart';

void main() {
  group('TimetableNormalizer - Weekday Normalization', () {
    test(
      'normalizes standard English weekday names (full and abbreviated)',
      () {
        expect(TimetableNormalizer.normalizeWeekday('Sunday'), 0);
        expect(TimetableNormalizer.normalizeWeekday('sun'), 0);
        expect(TimetableNormalizer.normalizeWeekday('Monday'), 1);
        expect(TimetableNormalizer.normalizeWeekday('mon'), 1);
        expect(TimetableNormalizer.normalizeWeekday('Tuesday'), 2);
        expect(TimetableNormalizer.normalizeWeekday('tue'), 2);
        expect(TimetableNormalizer.normalizeWeekday('tues'), 2);
        expect(TimetableNormalizer.normalizeWeekday('Wednesday'), 3);
        expect(TimetableNormalizer.normalizeWeekday('wed'), 3);
        expect(TimetableNormalizer.normalizeWeekday('Thursday'), 4);
        expect(TimetableNormalizer.normalizeWeekday('thu'), 4);
        expect(TimetableNormalizer.normalizeWeekday('thurs'), 4);
        expect(TimetableNormalizer.normalizeWeekday('Friday'), 5);
        expect(TimetableNormalizer.normalizeWeekday('fri'), 5);
        expect(TimetableNormalizer.normalizeWeekday('Saturday'), 6);
        expect(TimetableNormalizer.normalizeWeekday('sat'), 6);
      },
    );

    test('normalizes standard Arabic weekday names with and without hamza', () {
      expect(TimetableNormalizer.normalizeWeekday('الأحد'), 0);
      expect(TimetableNormalizer.normalizeWeekday('الاحد'), 0);
      expect(TimetableNormalizer.normalizeWeekday('يوم الأحد'), 0);

      expect(TimetableNormalizer.normalizeWeekday('الإثنين'), 1);
      expect(TimetableNormalizer.normalizeWeekday('الاثنين'), 1);
      expect(TimetableNormalizer.normalizeWeekday('اثنين'), 1);

      expect(TimetableNormalizer.normalizeWeekday('الثلاثاء'), 2);
      expect(TimetableNormalizer.normalizeWeekday('ثلاثاء'), 2);

      expect(TimetableNormalizer.normalizeWeekday('الأربعاء'), 3);
      expect(TimetableNormalizer.normalizeWeekday('الاربعاء'), 3);

      expect(TimetableNormalizer.normalizeWeekday('الخميس'), 4);
      expect(TimetableNormalizer.normalizeWeekday('خميس'), 4);

      expect(TimetableNormalizer.normalizeWeekday('الجمعة'), 5);
      expect(TimetableNormalizer.normalizeWeekday('جمعة'), 5);

      expect(TimetableNormalizer.normalizeWeekday('السبت'), 6);
      expect(TimetableNormalizer.normalizeWeekday('سبت'), 6);
    });

    test(
      'normalizes spaced Arabic weekday letters from OCR / PDF line layout',
      () {
        expect(TimetableNormalizer.normalizeWeekday('ا لأ ح د'), 0);
        expect(TimetableNormalizer.normalizeWeekday('ا لإ ث ن ي ن'), 1);
        expect(TimetableNormalizer.normalizeWeekday('ا ل ث لا ث ا ء'), 2);
        expect(TimetableNormalizer.normalizeWeekday('ا لأ ر ب ع ا ء'), 3);
        expect(TimetableNormalizer.normalizeWeekday('ا ل خ م ي س'), 4);
        expect(TimetableNormalizer.normalizeWeekday('ا ل ج م ع ة'), 5);
        expect(TimetableNormalizer.normalizeWeekday('ا ل س ب ت'), 6);
      },
    );

    test('normalizes direct integer strings 0..6', () {
      expect(TimetableNormalizer.normalizeWeekday('0'), 0);
      expect(TimetableNormalizer.normalizeWeekday('1'), 1);
      expect(TimetableNormalizer.normalizeWeekday('6'), 6);
      expect(TimetableNormalizer.normalizeWeekday('٠'), 0);
      expect(TimetableNormalizer.normalizeWeekday('٤'), 4);
    });

    test('returns null for unrecognized or empty weekday without guessing', () {
      expect(TimetableNormalizer.normalizeWeekday(''), isNull);
      expect(TimetableNormalizer.normalizeWeekday(null), isNull);
      expect(TimetableNormalizer.normalizeWeekday('NotADay'), isNull);
      expect(TimetableNormalizer.normalizeWeekday('CS101'), isNull);
      expect(TimetableNormalizer.normalizeWeekday('9'), isNull);
    });

    test('formats weekdays correctly in English and Arabic', () {
      expect(TimetableNormalizer.formatWeekday(0), 'Sunday');
      expect(TimetableNormalizer.formatWeekday(0, isArabic: true), 'الأحد');
      expect(TimetableNormalizer.formatWeekday(6), 'Saturday');
      expect(TimetableNormalizer.formatWeekday(6, isArabic: true), 'السبت');
      expect(TimetableNormalizer.formatWeekday(null), 'Unspecified');
      expect(
        TimetableNormalizer.formatWeekday(null, isArabic: true),
        'غير محدد',
      );
    });
  });

  group('TimetableNormalizer - Time Normalization', () {
    test('normalizes standard 24-hour time strings', () {
      expect(TimetableNormalizer.normalizeTime('09:00'), '09:00');
      expect(TimetableNormalizer.normalizeTime('9:00'), '09:00');
      expect(TimetableNormalizer.normalizeTime('14:30'), '14:30');
      expect(TimetableNormalizer.normalizeTime('00:15'), '00:15');
      expect(TimetableNormalizer.normalizeTime('23:59'), '23:59');
    });

    test('normalizes 12-hour AM/PM formats to 24-hour representations', () {
      // AM
      expect(TimetableNormalizer.normalizeTime('9:00 AM'), '09:00');
      expect(TimetableNormalizer.normalizeTime('09:00 AM'), '09:00');
      expect(TimetableNormalizer.normalizeTime('9:00am'), '09:00');
      expect(TimetableNormalizer.normalizeTime('9 AM'), '09:00');
      expect(TimetableNormalizer.normalizeTime('11:45 AM'), '11:45');

      // 12 AM (Midnight)
      expect(TimetableNormalizer.normalizeTime('12:00 AM'), '00:00');
      expect(TimetableNormalizer.normalizeTime('12:30 AM'), '00:30');

      // 12 PM (Noon)
      expect(TimetableNormalizer.normalizeTime('12:00 PM'), '12:00');
      expect(TimetableNormalizer.normalizeTime('12:45 PM'), '12:45');

      // PM Afternoon
      expect(TimetableNormalizer.normalizeTime('1:00 PM'), '13:00');
      expect(TimetableNormalizer.normalizeTime('01:30 PM'), '13:30');
      expect(TimetableNormalizer.normalizeTime('2:15 PM'), '14:15');
      expect(TimetableNormalizer.normalizeTime('9:00 PM'), '21:00');
      expect(TimetableNormalizer.normalizeTime('11:00 PM'), '23:00');
    });

    test(
      'normalizes Arabic time period indicators (ص / م / صباحاً / مساءً)',
      () {
        expect(TimetableNormalizer.normalizeTime('09:00 ص'), '09:00');
        expect(TimetableNormalizer.normalizeTime('9:00 ص'), '09:00');
        expect(TimetableNormalizer.normalizeTime('10:30 صباحاً'), '10:30');
        expect(TimetableNormalizer.normalizeTime('01:30 م'), '13:30');
        expect(TimetableNormalizer.normalizeTime('1:30 م'), '13:30');
        expect(TimetableNormalizer.normalizeTime('02:00 مساءً'), '14:00');
      },
    );

    test('normalizes Arabic numerals to standard 24h digits', () {
      expect(TimetableNormalizer.normalizeTime('٠٩:٠٠'), '09:00');
      expect(TimetableNormalizer.normalizeTime('١٠:٣٠'), '10:30');
      expect(TimetableNormalizer.normalizeTime('٠١:٣٠ م'), '13:30');
      expect(TimetableNormalizer.normalizeTime('٠٨:١٥ ص'), '08:15');
    });

    test('normalizes dot separator (e.g. 09.00 or 9.00 AM)', () {
      expect(TimetableNormalizer.normalizeTime('09.00'), '09:00');
      expect(TimetableNormalizer.normalizeTime('9.00 AM'), '09:00');
      expect(TimetableNormalizer.normalizeTime('01.30 PM'), '13:30');
    });

    test(
      'returns null for invalid time strings without silently inventing times',
      () {
        expect(TimetableNormalizer.normalizeTime(''), isNull);
        expect(TimetableNormalizer.normalizeTime(null), isNull);
        expect(TimetableNormalizer.normalizeTime('not_a_time'), isNull);
        expect(TimetableNormalizer.normalizeTime('25:00'), isNull);
        expect(TimetableNormalizer.normalizeTime('12:65'), isNull);
      },
    );
  });
}
