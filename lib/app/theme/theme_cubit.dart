import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskora/core/storage/preferences_service.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  final PreferencesService _preferencesService;

  ThemeCubit(this._preferencesService)
    : super(_preferencesService.getThemeMode());

  Future<void> setThemeMode(ThemeMode mode) async {
    if (state == mode) return;
    await _preferencesService.setThemeMode(mode);
    emit(mode);
  }
}
