import 'package:flutter/material.dart';

/// Centralized modern icon family for Taskora.
/// Adheres strictly to a polished, minimal outline aesthetic for default states
/// and filled/rounded variants for active/selected states.
class AppIcons {
  AppIcons._();

  // Standard Icon Sizes
  static const double sizeSmall = 16.0;
  static const double sizeMedium = 20.0;
  static const double sizeDefault = 24.0;
  static const double sizeLarge = 28.0;
  static const double sizeHero = 48.0;

  // Navigation (Outline for inactive, filled for active)
  static const IconData navHome = Icons.home_outlined;
  static const IconData navHomeActive = Icons.home_rounded;
  static const IconData navSchedule = Icons.calendar_today_outlined;
  static const IconData navScheduleActive = Icons.calendar_today_rounded;
  static const IconData navTasks = Icons.check_circle_outline_rounded;
  static const IconData navTasksActive = Icons.check_circle_rounded;
  static const IconData navSettings = Icons.settings_outlined;
  static const IconData navSettingsActive = Icons.settings_rounded;

  // Schedule & Academic
  static const IconData lecture = Icons.school_outlined;
  static const IconData courseCode = Icons.tag_rounded;
  static const IconData instructor = Icons.person_outline_rounded;
  static const IconData room = Icons.location_on_outlined;
  static const IconData time = Icons.access_time_rounded;
  static const IconData notes = Icons.description_outlined;
  static const IconData calendar = Icons.calendar_today_outlined;
  static const IconData conflict = Icons.warning_amber_rounded;
  static const IconData academicCap = Icons.school_outlined;

  // Tasks & Productivity
  static const IconData taskPending = Icons.radio_button_unchecked_rounded;
  static const IconData taskCompleted = Icons.check_circle_rounded;
  static const IconData taskAdd = Icons.add_task_rounded;
  static const IconData taskFilter = Icons.tune_rounded;
  static const IconData taskOverdue = Icons.warning_amber_rounded;
  static const IconData category = Icons.folder_outlined;
  static const IconData priorityHigh = Icons.flag_rounded;
  static const IconData priorityMedium = Icons.flag_outlined;
  static const IconData priorityLow = Icons.outlined_flag_rounded;

  // Import & Export
  static const IconData csvImport = Icons.file_upload_outlined;
  static const IconData csvExport = Icons.file_download_outlined;
  static const IconData table = Icons.table_chart_outlined;
  static const IconData copy = Icons.content_copy_rounded;
  static const IconData share = Icons.share_outlined;

  // Settings & System
  static const IconData theme = Icons.palette_outlined;
  static const IconData language = Icons.translate_rounded;
  static const IconData notifications = Icons.notifications_outlined;
  static const IconData notificationsActive =
      Icons.notifications_active_outlined;
  static const IconData backup = Icons.cloud_upload_outlined;
  static const IconData about = Icons.info_outline_rounded;
  static const IconData help = Icons.help_outline_rounded;
  static const IconData chevronRight = Icons.chevron_right_rounded;

  // Common Actions
  static const IconData add = Icons.add_rounded;
  static const IconData edit = Icons.edit_outlined;
  static const IconData delete = Icons.delete_outline_rounded;
  static const IconData close = Icons.close_rounded;
  static const IconData search = Icons.search_rounded;
  static const IconData check = Icons.check_rounded;
  static const IconData info = Icons.info_outline_rounded;
  static const IconData warning = Icons.warning_amber_rounded;
  static const IconData error = Icons.error_outline_rounded;
}
