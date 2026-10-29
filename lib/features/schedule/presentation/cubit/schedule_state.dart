import 'package:taskora/features/schedule/domain/entities/lecture_entity.dart';

class ScheduleState {
  final int selectedDayIndex; // 0: Sun, 1: Mon, ..., 6: Sat
  final bool isLoading;
  final List<LectureEntity> dayLectures;
  final List<LectureEntity> allLectures;
  final LectureEntity? nextLecture;
  final String? errorMessage;

  const ScheduleState({
    required this.selectedDayIndex,
    this.isLoading = false,
    this.dayLectures = const [],
    this.allLectures = const [],
    this.nextLecture,
    this.errorMessage,
  });

  ScheduleState copyWith({
    int? selectedDayIndex,
    bool? isLoading,
    List<LectureEntity>? dayLectures,
    List<LectureEntity>? allLectures,
    LectureEntity? nextLecture,
    bool clearNextLecture = false,
    String? errorMessage,
  }) {
    return ScheduleState(
      selectedDayIndex: selectedDayIndex ?? this.selectedDayIndex,
      isLoading: isLoading ?? this.isLoading,
      dayLectures: dayLectures ?? this.dayLectures,
      allLectures: allLectures ?? this.allLectures,
      nextLecture: clearNextLecture ? null : (nextLecture ?? this.nextLecture),
      errorMessage: errorMessage,
    );
  }
}
