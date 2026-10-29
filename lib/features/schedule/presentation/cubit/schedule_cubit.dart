import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskora/features/schedule/data/repositories/schedule_repository.dart';
import 'package:taskora/features/schedule/domain/entities/lecture_entity.dart';
import 'package:taskora/features/schedule/presentation/cubit/schedule_state.dart';

class ScheduleCubit extends Cubit<ScheduleState> {
  final ScheduleRepository _scheduleRepository;
  StreamSubscription<List<LectureEntity>>? _daySubscription;
  StreamSubscription<List<LectureEntity>>? _allSubscription;

  ScheduleCubit(this._scheduleRepository)
    : super(
        ScheduleState(
          selectedDayIndex: DateTime.now().weekday % 7,
          isLoading: true,
        ),
      ) {
    _initSubscriptions();
  }

  void _initSubscriptions() {
    _subscribeToDay(state.selectedDayIndex);

    _allSubscription = _scheduleRepository.watchAllLectures().listen(
      (allLectures) {
        final next = _calculateNextLecture(allLectures);
        emit(
          state.copyWith(
            allLectures: allLectures,
            nextLecture: next,
            clearNextLecture: next == null,
          ),
        );
      },
      onError: (e) {
        emit(state.copyWith(errorMessage: e.toString()));
      },
    );
  }

  void selectDay(int dayIndex) {
    if (dayIndex < 0 || dayIndex > 6) return;
    if (state.selectedDayIndex == dayIndex && !state.isLoading) return;

    emit(state.copyWith(selectedDayIndex: dayIndex, isLoading: true));
    _subscribeToDay(dayIndex);
  }

  void _subscribeToDay(int dayIndex) {
    _daySubscription?.cancel();
    _daySubscription = _scheduleRepository
        .watchLecturesForDay(dayIndex)
        .listen(
          (lectures) {
            emit(
              state.copyWith(
                dayLectures: lectures,
                isLoading: false,
                errorMessage: null,
              ),
            );
          },
          onError: (e) {
            emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
          },
        );
  }

  Future<void> refreshSchedule() async {
    emit(state.copyWith(isLoading: true));
    try {
      final dayLectures = await _scheduleRepository.getLecturesForDay(
        state.selectedDayIndex,
      );
      final allLectures = await _scheduleRepository.getAllLectures();
      final next = _calculateNextLecture(allLectures);
      emit(
        state.copyWith(
          dayLectures: dayLectures,
          allLectures: allLectures,
          nextLecture: next,
          clearNextLecture: next == null,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<LectureEntity?> checkConflict(LectureEntity lecture) {
    return _scheduleRepository.findConflictingLecture(lecture);
  }

  Future<bool> addLecture(LectureEntity lecture) async {
    try {
      final conflict = await _scheduleRepository.findConflictingLecture(
        lecture,
      );
      if (conflict != null) {
        emit(
          state.copyWith(
            errorMessage:
                'Time conflict with "${conflict.courseName}" (${conflict.startTime} - ${conflict.endTime})',
          ),
        );
        return false;
      }

      await _scheduleRepository.addLecture(lecture);
      emit(state.copyWith(errorMessage: null));
      return true;
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
      return false;
    }
  }

  Future<bool> updateLecture(LectureEntity lecture) async {
    try {
      final conflict = await _scheduleRepository.findConflictingLecture(
        lecture,
      );
      if (conflict != null) {
        emit(
          state.copyWith(
            errorMessage:
                'Time conflict with "${conflict.courseName}" (${conflict.startTime} - ${conflict.endTime})',
          ),
        );
        return false;
      }

      await _scheduleRepository.updateLecture(lecture);
      emit(state.copyWith(errorMessage: null));
      return true;
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
      return false;
    }
  }

  Future<void> deleteLecture(int id) async {
    try {
      await _scheduleRepository.deleteLecture(id);
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  LectureEntity? _calculateNextLecture(List<LectureEntity> lectures) {
    if (lectures.isEmpty) return null;

    final now = DateTime.now();
    final todayDayOfWeek = now.weekday % 7;
    final currentTimeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // 1. Look for remaining lectures today
    final todayLectures = lectures
        .where((l) => l.dayOfWeek == todayDayOfWeek)
        .toList();
    for (final lecture in todayLectures) {
      // In accordance with Step 6: Identify the next upcoming lecture when its start time is still in the future
      if (lecture.startTime.compareTo(currentTimeStr) >= 0) {
        return lecture;
      }
    }

    // If none has start time in future today, look for currently ongoing lecture
    for (final lecture in todayLectures) {
      if (lecture.endTime.compareTo(currentTimeStr) > 0) {
        return lecture;
      }
    }

    // 2. Look for upcoming lectures in the following days of the week
    for (int offset = 1; offset < 7; offset++) {
      final targetDay = (todayDayOfWeek + offset) % 7;
      final dayMatches = lectures
          .where((l) => l.dayOfWeek == targetDay)
          .toList();
      if (dayMatches.isNotEmpty) {
        return dayMatches.first;
      }
    }

    return null;
  }

  @override
  Future<void> close() {
    _daySubscription?.cancel();
    _allSubscription?.cancel();
    return super.close();
  }
}
