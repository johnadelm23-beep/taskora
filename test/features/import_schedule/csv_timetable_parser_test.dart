import 'package:flutter_test/flutter_test.dart';
import 'package:taskora/features/import_schedule/domain/entities/canonical_timetable_entry.dart';
import 'package:taskora/features/import_schedule/domain/services/csv_timetable_parser.dart';
import 'package:taskora/features/import_schedule/domain/services/timetable_template_service.dart';

void main() {
  late CsvTimetableParser parser;

  setUp(() {
    parser = CsvTimetableParser();
  });

  group('CsvTimetableParser - Standard Template Import', () {
    test('parses predictable CSV with exact standard headers', () {
      const csv = '''
Weekday,Course Name,Start Time,End Time,Instructor,Room
Sunday,Data Structures,09:00 AM,10:30 AM,Dr. Ahmed Hassan,Lab 2
Monday,Database Systems,11:00 AM,12:30 PM,Dr. Mona Ali,Room 105
Tuesday,Computer Networks,01:30 PM,03:00 PM,Dr. Omar Adel,Room 204
''';

      final candidates = parser.parseToCandidates(csv);
      expect(candidates.length, 3);

      final c1 = candidates[0];
      expect(c1.dayOfWeek, 0); // Sunday
      expect(c1.courseName, 'Data Structures');
      expect(c1.startTime, '09:00');
      expect(c1.endTime, '10:30');
      expect(c1.instructor, 'Dr. Ahmed Hassan');
      expect(c1.room, 'Lab 2');
      expect(c1.isValid, isTrue);

      final c2 = candidates[1];
      expect(c2.dayOfWeek, 1); // Monday
      expect(c2.courseName, 'Database Systems');
      expect(c2.startTime, '11:00');
      expect(c2.endTime, '12:30');
      expect(c2.instructor, 'Dr. Mona Ali');
      expect(c2.room, 'Room 105');
      expect(c2.isValid, isTrue);

      final c3 = candidates[2];
      expect(c3.dayOfWeek, 2); // Tuesday
      expect(c3.courseName, 'Computer Networks');
      expect(c3.startTime, '13:30');
      expect(c3.endTime, '15:00');
      expect(c3.instructor, 'Dr. Omar Adel');
      expect(c3.room, 'Room 204');
      expect(c3.isValid, isTrue);
    });

    test('handles case-insensitive headers and trimming whitespace/quotes', () {
      const csv = '''
"WEEKDAY","COURSE NAME","START TIME","END TIME","INSTRUCTOR","ROOM"
 "Wednesday" , "Operating Systems" , "09:00" , "10:30" , "Dr. Salma" , "Room 201"
''';

      final candidates = parser.parseToCandidates(csv);
      expect(candidates.length, 1);

      final c = candidates.first;
      expect(c.dayOfWeek, 3); // Wednesday
      expect(c.courseName, 'Operating Systems');
      expect(c.startTime, '09:00');
      expect(c.endTime, '10:30');
      expect(c.instructor, 'Dr. Salma');
      expect(c.room, 'Room 201');
      expect(c.isValid, isTrue);
    });

    test('supports semicolon-delimited CSV formats', () {
      const csv = '''
Weekday;Course Name;Start Time;End Time;Instructor;Room
Thursday;Software Engineering;08:30;10:00;Dr. Nour;Room 301
''';

      final candidates = parser.parseToCandidates(csv);
      expect(candidates.length, 1);
      expect(candidates.first.dayOfWeek, 4); // Thursday
      expect(candidates.first.courseName, 'Software Engineering');
      expect(candidates.first.startTime, '08:30');
      expect(candidates.first.endTime, '10:00');
      expect(candidates.first.isValid, isTrue);
    });

    test('supports Arabic headers and Arabic weekday names', () {
      const csv = '''
اليوم,اسم المقرر,وقت البدء,وقت الانتهاء,المحاضر,القاعة
الأحد,هندسة البرمجيات,09:00 ص,10:30 ص,د. أحمد علي,قاعة 102
السبت,نظم التشغيل,11:00 ص,12:30 م,م. سارة,معمل 3
''';

      final candidates = parser.parseToCandidates(csv);
      expect(candidates.length, 2);

      expect(candidates[0].dayOfWeek, 0); // الأحد
      expect(candidates[0].courseName, 'هندسة البرمجيات');
      expect(candidates[0].startTime, '09:00');
      expect(candidates[0].endTime, '10:30');
      expect(candidates[0].instructor, 'د. أحمد علي');
      expect(candidates[0].room, 'قاعة 102');
      expect(candidates[0].isValid, isTrue);

      expect(candidates[1].dayOfWeek, 6); // السبت
      expect(candidates[1].courseName, 'نظم التشغيل');
      expect(candidates[1].startTime, '11:00');
      expect(candidates[1].endTime, '12:30');
      expect(candidates[1].isValid, isTrue);
    });

    test(
      'missing optional fields (Instructor and Room) produces valid entries',
      () {
        const csv = '''
Weekday,Course Name,Start Time,End Time,Instructor,Room
Monday,Algorithms,09:00,10:30,,
Tuesday,Linear Algebra,11:00,12:30,Prof. Euler,
Wednesday,Physics Lab,14:00,15:30,,Lab 4
''';

        final candidates = parser.parseToCandidates(csv);
        expect(candidates.length, 3);

        // Both optional fields missing -> still valid!
        expect(candidates[0].courseName, 'Algorithms');
        expect(candidates[0].instructor, '');
        expect(candidates[0].room, '');
        expect(candidates[0].isValid, isTrue);

        // Room missing -> still valid!
        expect(candidates[1].courseName, 'Linear Algebra');
        expect(candidates[1].instructor, 'Prof. Euler');
        expect(candidates[1].room, '');
        expect(candidates[1].isValid, isTrue);

        // Instructor missing -> still valid!
        expect(candidates[2].courseName, 'Physics Lab');
        expect(candidates[2].instructor, '');
        expect(candidates[2].room, 'Lab 4');
        expect(candidates[2].isValid, isTrue);
      },
    );

    test(
      'invalid rows are retained as invalid candidates with explicit error messages',
      () {
        const csv = '''
Weekday,Course Name,Start Time,End Time,Instructor,Room
,Missing Day Course,09:00,10:30,Dr. A,Room 1
Monday,,11:00,12:30,Dr. B,Room 2
Tuesday,Reversed Times,10:30,09:00,Dr. C,Room 3
Wednesday,Identical Times,09:00,09:00,Dr. D,Room 4
Thursday,Invalid Start Time,not_a_time,10:30,Dr. E,Room 5
''';

        final candidates = parser.parseToCandidates(csv);
        expect(candidates.length, 5);

        // Row 1: Missing Day
        expect(candidates[0].isValid, isFalse);
        expect(candidates[0].validationErrors, contains('Weekday is required'));

        // Row 2: Missing Course Name
        expect(candidates[1].isValid, isFalse);
        expect(
          candidates[1].validationErrors,
          contains('Course name is required'),
        );

        // Row 3: Reversed Time Range (end before start)
        expect(candidates[2].isValid, isFalse);
        expect(
          candidates[2].validationErrors.any(
            (e) => e.contains('earlier than start time'),
          ),
          isTrue,
        );

        // Row 4: Identical Times
        expect(candidates[3].isValid, isFalse);
        expect(
          candidates[3].validationErrors.any(
            (e) => e.contains('cannot be identical'),
          ),
          isTrue,
        );

        // Row 5: Invalid Start Time
        expect(candidates[4].isValid, isFalse);
        expect(
          candidates[4].validationErrors,
          contains('Start time is required'),
        );
      },
    );

    test('skips comment lines and example rows', () {
      const csv = '''
Weekday,Course Name,Start Time,End Time,Instructor,Room
# This is a comment
# EXAMPLES (Delete or replace):
Sunday,Real Lecture,09:00 AM,10:30 AM,Dr. Real,Room 1
// Another comment line
Monday,[EXAMPLE] Sample Class,11:00 AM,12:30 PM,Dr. Fake,Room 2
Tuesday,EXAMPLE ROW: Demo Class,01:00 PM,02:30 PM,Dr. Demo,Room 3
''';

      final candidates = parser.parseToCandidates(csv);
      // Only "Real Lecture" should be parsed; comments and [EXAMPLE] rows are skipped
      expect(candidates.length, 1);
      expect(candidates.first.courseName, 'Real Lecture');
      expect(candidates.first.isValid, isTrue);
    });

    test(
      'TimetableTemplateService.templateCsv contains valid headers and comments out examples',
      () {
        final template = TimetableTemplateService.templateCsv;
        expect(
          template,
          contains('Weekday,Course Name,Start Time,End Time,Instructor,Room'),
        );
        expect(template, contains('# EXAMPLES'));

        // When parsed directly, all example rows starting with # are safely ignored as comments
        final candidates = parser.parseToCandidates(template);
        expect(candidates.isEmpty, isTrue);
      },
    );

    test(
      'converts cleanly between CanonicalTimetableEntry and ExtractedLectureCandidate',
      () {
        const canonical = CanonicalTimetableEntry(
          weekday: 1, // Monday
          courseName: 'Computer Architecture',
          courseCode: 'CS202',
          startTime: '10:00',
          endTime: '11:30',
          instructor: 'Dr. Turing',
          room: 'Lab 5',
        );

        expect(canonical.isValid, isTrue);
        expect(canonical.hasRequiredFields, isTrue);
        expect(canonical.isTimeRangeValid, isTrue);

        final candidate = canonical.toCandidate(id: 'test_123');
        expect(candidate.id, 'test_123');
        expect(candidate.courseName, 'Computer Architecture');
        expect(candidate.courseCode, 'CS202');
        expect(candidate.dayOfWeek, 1);
        expect(candidate.startTime, '10:00');
        expect(candidate.endTime, '11:30');
        expect(candidate.instructor, 'Dr. Turing');
        expect(candidate.room, 'Lab 5');
        expect(candidate.isValid, isTrue);

        final reconstructed = candidate.toCanonical();
        expect(reconstructed, equals(canonical));
      },
    );
  });
}
