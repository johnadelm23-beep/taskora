import 'package:flutter_test/flutter_test.dart';
import 'package:taskora/features/import_schedule/domain/entities/extracted_lecture_candidate.dart';
import 'package:taskora/features/import_schedule/domain/services/timetable_parser.dart';

void main() {
  late TimetableParser parser;

  setUp(() {
    parser = TimetableParser();
  });

  group('TimetableParser', () {
    test(
      'parses standard English block with course, code, instructor, room, day and 24h time',
      () {
        const text = '''
Monday
CS302 Mobile Development
Dr. John Smith
Hall 4
10:00 - 11:30
''';
        final candidates = parser.parse(text);
        expect(candidates.length, 1);
        final c = candidates.first;
        expect(c.dayOfWeek, 1); // Monday
        expect(c.startTime, '10:00');
        expect(c.endTime, '11:30');
        expect(c.courseCode, 'CS302');
        expect(c.courseName, contains('Mobile Development'));
        expect(c.room, 'Hall 4');
        expect(c.instructor, 'Dr. John Smith');
        expect(c.isValid, isTrue);
      },
    );

    test('parses 12-hour AM/PM times and converts to 24-hour', () {
      const text = '''
Wednesday
PHYS101 General Physics
Prof. Alan Walker
Room 201
09:00 AM - 10:30 AM

Wednesday
CHEM201 Organic Chemistry
Dr. Marie Curie
Lab B
01:00 PM - 02:30 PM
''';
      final candidates = parser.parse(text);
      expect(candidates.length, 2);

      final c1 = candidates[0];
      expect(c1.dayOfWeek, 3); // Wednesday
      expect(c1.startTime, '09:00');
      expect(c1.endTime, '10:30');

      final c2 = candidates[1];
      expect(c2.dayOfWeek, 3); // Wednesday
      expect(c2.startTime, '13:00');
      expect(c2.endTime, '14:30');
    });

    test('parses Arabic weekday, course name, room, instructor and time', () {
      const text = '''
الاثنين
برمجة الأجهزة الذكية
د. أحمد علي
قاعة 102
10:00 - 11:30
''';
      final candidates = parser.parse(text);
      expect(candidates.length, 1);
      final c = candidates.first;
      expect(c.dayOfWeek, 1); // Monday
      expect(c.startTime, '10:00');
      expect(c.endTime, '11:30');
      expect(c.courseName, contains('برمجة الأجهزة الذكية'));
      expect(c.instructor, contains('د. أحمد علي'));
      expect(c.room, 'قاعة 102');
      expect(c.isValid, isTrue);
    });

    test('parses Arabic digits and "إلى" separator', () {
      const text = '''
الخميس
قواعد البيانات
مختبر الحاسوب
٠٨:٠٠ إلى ٠٩:٣٠
''';
      final candidates = parser.parse(text);
      expect(candidates.length, 1);
      final c = candidates.first;
      expect(c.dayOfWeek, 4); // Thursday
      expect(c.startTime, '08:00');
      expect(c.endTime, '09:30');
      expect(c.courseName, contains('قواعد البيانات'));
      expect(c.room, contains('مختبر الحاسوب'));
      expect(c.isValid, isTrue);
    });

    test('handles single-line tabular schedule entry', () {
      const text =
          'Mon | 10:00 - 11:30 | CS101 Intro to CS | Hall B | Dr. Jack';
      final candidates = parser.parse(text);
      expect(candidates.length, 1);
      final c = candidates.first;
      expect(c.dayOfWeek, 1);
      expect(c.startTime, '10:00');
      expect(c.endTime, '11:30');
      expect(c.courseCode, 'CS101');
      expect(c.room, 'Hall B');
      expect(c.instructor, 'Dr. Jack');
      expect(c.isValid, isTrue);
    });

    test('detects overlapping lectures on the same weekday', () {
      const text = '''
Monday
CS301 Algorithms
Hall 1
10:00 - 11:30

Monday
CS302 Mobile Dev
Hall 2
11:00 - 12:30
''';
      final candidates = parser.parse(text);
      expect(candidates.length, 2);
      expect(candidates[0].hasConflict, isTrue);
      expect(candidates[1].hasConflict, isTrue);
    });

    test(
      'deduplicates identical candidates produced by overlapping text segments',
      () {
        const text = '''
Monday
CS301 Algorithms
Hall 1
10:00 - 11:30

Monday
CS301 Algorithms
Hall 1
10:00 - 11:30
''';
        final candidates = parser.parse(text);
        expect(candidates.length, 1);
      },
    );

    test(
      'leaves unresolved fields when information is missing without fabricating data',
      () {
        const text = '''
Algorithms Class
10:00 - 11:30
''';
        final candidates = parser.parse(text);
        expect(candidates.length, 1);
        final c = candidates.first;
        expect(c.dayOfWeek, isNull); // Missing weekday
        expect(c.room, isEmpty); // Missing room
        expect(c.instructor, isEmpty); // Missing instructor
        expect(c.isValid, isFalse); // Invalid because dayOfWeek is null
        expect(c.validationErrorMessage, contains('Weekday is required'));
      },
    );

    test('returns empty list for empty or unrecognizable text', () {
      expect(parser.parse(''), isEmpty);
      expect(parser.parse('   \n  \n '), isEmpty);
      expect(
        parser.parse(
          'Random document with no schedule or timetable times at all',
        ),
        isEmpty,
      );
    });

    test(
      'validates invalid time ranges when end time is earlier or equal to start time',
      () {
        const candidateInvalid = ExtractedLectureCandidate(
          id: 'test_1',
          courseName: 'Physics',
          dayOfWeek: 1,
          startTime: '11:30',
          endTime: '10:00', // Invalid: end time earlier than start time
        );

        expect(candidateInvalid.isTimeRangeValid, isFalse);
        expect(candidateInvalid.isTimeRangeReversed, isTrue);
        expect(candidateInvalid.isValid, isFalse);
        expect(
          candidateInvalid.validationErrorMessage,
          contains('earlier than start time'),
        );

        const candidateEqual = ExtractedLectureCandidate(
          id: 'test_2',
          courseName: 'Chemistry',
          dayOfWeek: 1,
          startTime: '10:00',
          endTime: '10:00', // Invalid: zero duration
        );

        expect(candidateEqual.isTimeRangeValid, isFalse);
        expect(candidateEqual.isValid, isFalse);
        expect(candidateEqual.validationErrorMessage, contains('identical'));
      },
    );

    test('fixes mojibake Arabic course names during parsing', () {
      const text = '''
الأحد
Ø¹Ù„ÙˆÙ… Ø§Ù„Ø­Ø§Ø³Ø¨
10:00 - 11:30
''';
      final candidates = parser.parse(text);
      expect(candidates.length, 1);
      final c = candidates.first;
      expect(c.courseName, 'علوم الحاسب');
      expect(c.dayOfWeek, 0); // Sunday
      expect(c.startTime, '10:00');
      expect(c.endTime, '11:30');
      expect(c.isValid, isTrue);
    });

    test('reverses visually reversed Arabic words during parsing', () {
      const text = '''
الاثنين
بساحلا مولع
10:00 - 11:30
''';
      final candidates = parser.parse(text);
      expect(candidates.length, 1);
      final c = candidates.first;
      expect(c.courseName, 'علوم الحاسب');
      expect(c.dayOfWeek, 1); // Monday
      expect(c.isValid, isTrue);
    });

    test(
      'preserves reversed time range (09:45 - 09:00) without silent swapping and marks invalid',
      () {
        const text = '''
الأحد
علوم الحاسب
09:45 - 09:00
''';
        final candidates = parser.parse(text);
        expect(candidates.length, 1);
        final c = candidates.first;
        expect(c.courseName, 'علوم الحاسب');
        expect(c.dayOfWeek, 0);
        // Must NOT be silently swapped:
        expect(c.startTime, '09:45');
        expect(c.endTime, '09:00');
        expect(c.isTimeRangeReversed, isTrue);
        expect(c.isTimeRangeValid, isFalse);
        expect(c.isValid, isFalse);
        expect(
          c.validationErrors,
          contains('End time (09:00) is earlier than start time (09:45)'),
        );
      },
    );

    test(
      'parses table with weekday column headers and maps columns to days',
      () {
        const text = '''
| الوقت | الأحد | الاثنين |
| 09:00 - 10:30 | علوم الحاسب | برمجة الأجهزة الذكية |
''';
        final candidates = parser.parse(text);
        expect(candidates.length, 2);

        final c1 = candidates.firstWhere((c) => c.dayOfWeek == 0);
        expect(c1.courseName, 'علوم الحاسب');
        expect(c1.startTime, '09:00');
        expect(c1.endTime, '10:30');
        expect(c1.isValid, isTrue);

        final c2 = candidates.firstWhere((c) => c.dayOfWeek == 1);
        expect(c2.courseName, 'برمجة الأجهزة الذكية');
        expect(c2.startTime, '09:00');
        expect(c2.endTime, '10:30');
        expect(c2.isValid, isTrue);
      },
    );

    test(
      'parses table rows with pipe-separated cells including room and instructor',
      () {
        const text = 'الأحد | 09:00 - 09:45 | علوم الحاسب | قاعة 102 | د. خالد';
        final candidates = parser.parse(text);
        expect(candidates.length, 1);
        final c = candidates.first;
        expect(c.dayOfWeek, 0);
        expect(c.startTime, '09:00');
        expect(c.endTime, '09:45');
        expect(c.courseName, 'علوم الحاسب');
        expect(c.room, 'قاعة 102');
        expect(c.instructor, 'د. خالد');
        expect(c.isValid, isTrue);
      },
    );

    test(
      'parses seven-row sample timetable with separate Start Time and End Time columns',
      () {
        const text = '''
Weekday | Course Name | Start Time | End Time | Instructor | Room
Sunday | Data Structures | 09:00 AM | 10:30 AM | Dr. Ahmed Hassan | Lab 2
Sunday | Database Systems | 11:00 AM | 12:30 PM | Dr. Mona Ali | Room 105
Monday | Object-Oriented Programming | 10:00 AM | 11:30 AM | Dr. Karim Nabil | Lab 1
Tuesday | Operating Systems | 09:30 AM | 11:00 AM | Dr. Salma Youssef | Room 201
Tuesday | Computer Networks | 12:00 PM | 01:30 PM | Dr. Omar Adel | Room 204
Wednesday | Database Systems | 10:00 AM | 11:30 AM | Dr. Mona Ali | Room 105
Thursday | Software Engineering | 09:00 AM | 10:30 AM | Dr. Nour Samir | Room 301
''';

        final candidates = parser.parse(text);
        expect(candidates.length, 7);

        // Row 1: Sunday, Data Structures, 09:00 - 10:30
        expect(candidates[0].courseName, 'Data Structures');
        expect(candidates[0].dayOfWeek, 0); // Sunday
        expect(candidates[0].startTime, '09:00');
        expect(candidates[0].endTime, '10:30');
        expect(candidates[0].instructor, 'Dr. Ahmed Hassan');
        expect(candidates[0].room, 'Lab 2');
        expect(candidates[0].isValid, isTrue);

        // Row 2: Sunday, Database Systems, 11:00 - 12:30
        expect(candidates[1].courseName, 'Database Systems');
        expect(candidates[1].dayOfWeek, 0); // Sunday
        expect(candidates[1].startTime, '11:00');
        expect(candidates[1].endTime, '12:30');
        expect(candidates[1].instructor, 'Dr. Mona Ali');
        expect(candidates[1].room, 'Room 105');
        expect(candidates[1].isValid, isTrue);

        // Row 3: Monday, Object-Oriented Programming, 10:00 - 11:30
        expect(candidates[2].courseName, 'Object-Oriented Programming');
        expect(candidates[2].dayOfWeek, 1); // Monday
        expect(candidates[2].startTime, '10:00');
        expect(candidates[2].endTime, '11:30');
        expect(candidates[2].instructor, 'Dr. Karim Nabil');
        expect(candidates[2].room, 'Lab 1');
        expect(candidates[2].isValid, isTrue);

        // Row 4: Tuesday, Operating Systems, 09:30 - 11:00
        expect(candidates[3].courseName, 'Operating Systems');
        expect(candidates[3].dayOfWeek, 2); // Tuesday
        expect(candidates[3].startTime, '09:30');
        expect(candidates[3].endTime, '11:00');
        expect(candidates[3].instructor, 'Dr. Salma Youssef');
        expect(candidates[3].room, 'Room 201');
        expect(candidates[3].isValid, isTrue);

        // Row 5: Tuesday, Computer Networks, 12:00 - 13:30 (01:30 PM)
        expect(candidates[4].courseName, 'Computer Networks');
        expect(candidates[4].dayOfWeek, 2); // Tuesday
        expect(candidates[4].startTime, '12:00');
        expect(candidates[4].endTime, '13:30');
        expect(candidates[4].instructor, 'Dr. Omar Adel');
        expect(candidates[4].room, 'Room 204');
        expect(candidates[4].isValid, isTrue);

        // Row 6: Wednesday, Database Systems, 10:00 - 11:30
        expect(candidates[5].courseName, 'Database Systems');
        expect(candidates[5].dayOfWeek, 3); // Wednesday
        expect(candidates[5].startTime, '10:00');
        expect(candidates[5].endTime, '11:30');
        expect(candidates[5].instructor, 'Dr. Mona Ali');
        expect(candidates[5].room, 'Room 105');
        expect(candidates[5].isValid, isTrue);

        // Row 7: Thursday, Software Engineering, 09:00 - 10:30
        expect(candidates[6].courseName, 'Software Engineering');
        expect(candidates[6].dayOfWeek, 4); // Thursday
        expect(candidates[6].startTime, '09:00');
        expect(candidates[6].endTime, '10:30');
        expect(candidates[6].instructor, 'Dr. Nour Samir');
        expect(candidates[6].room, 'Room 301');
        expect(candidates[6].isValid, isTrue);
      },
    );

    test(
      'parses seven-row sample timetable when times are separated only by whitespace without pipes',
      () {
        const text = '''
Sunday Data Structures 09:00 AM 10:30 AM Dr. Ahmed Hassan Lab 2
Sunday Database Systems 11:00 AM 12:30 PM Dr. Mona Ali Room 105
Monday Object-Oriented Programming 10:00 AM 11:30 AM Dr. Karim Nabil Lab 1
Tuesday Operating Systems 09:30 AM 11:00 AM Dr. Salma Youssef Room 201
Tuesday Computer Networks 12:00 PM 01:30 PM Dr. Omar Adel Room 204
Wednesday Database Systems 10:00 AM 11:30 AM Dr. Mona Ali Room 105
Thursday Software Engineering 09:00 AM 10:30 AM Dr. Nour Samir Room 301
''';

        final candidates = parser.parse(text);
        expect(candidates.length, 7);

        expect(candidates[0].courseName, 'Data Structures');
        expect(candidates[0].startTime, '09:00');
        expect(candidates[0].endTime, '10:30');
        expect(candidates[0].instructor, 'Dr. Ahmed Hassan');
        expect(candidates[0].room, 'Lab 2');

        expect(candidates[4].courseName, 'Computer Networks');
        expect(candidates[4].startTime, '12:00');
        expect(candidates[4].endTime, '13:30');
        expect(candidates[4].instructor, 'Dr. Omar Adel');
        expect(candidates[4].room, 'Room 204');
      },
    );

    test('ExtractedLectureCandidate correctly converts to LectureEntity', () {
      const candidate = ExtractedLectureCandidate(
        id: 'test_cand',
        courseName: 'Software Engineering',
        courseCode: 'CS401',
        room: 'Lab 3',
        instructor: 'Dr. Sarah',
        dayOfWeek: 2, // Tuesday
        startTime: '14:00',
        endTime: '15:30',
        colorHex: 0xFF123456,
        notes: 'Bring laptop',
      );

      final lecture = candidate.toLectureEntity(id: 42);
      expect(lecture.id, 42);
      expect(lecture.courseName, 'Software Engineering');
      expect(lecture.courseCode, 'CS401');
      expect(lecture.room, 'Lab 3');
      expect(lecture.instructor, 'Dr. Sarah');
      expect(lecture.dayOfWeek, 2);
      expect(lecture.startTime, '14:00');
      expect(lecture.endTime, '15:30');
      expect(lecture.colorHex, 0xFF123456);
      expect(lecture.notes, 'Bring laptop');
    });
  });
}
