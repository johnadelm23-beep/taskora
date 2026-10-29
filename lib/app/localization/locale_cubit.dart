import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskora/core/storage/preferences_service.dart';

class LocaleCubit extends Cubit<Locale?> {
  final PreferencesService _preferencesService;

  LocaleCubit(this._preferencesService)
    : super(_preferencesService.getLocale());

  Future<void> setLocale(Locale? locale) async {
    if (state == locale) return;
    await _preferencesService.setLocale(locale);
    emit(locale);
  }
}
