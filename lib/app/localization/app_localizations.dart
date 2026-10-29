import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static const List<Locale> supportedLocales = [Locale('en'), Locale('ar')];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final localizations = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    return localizations ?? AppLocalizations(const Locale('en'));
  }

  bool get isRtl => locale.languageCode == 'ar';

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'Taskora',
      'nav_home': 'Home',
      'nav_schedule': 'Schedule',
      'nav_tasks': 'Tasks',
      'nav_settings': 'Settings',

      // Greetings & Header
      'greeting_morning': 'Good morning',
      'greeting_afternoon': 'Good afternoon',
      'greeting_evening': 'Good evening',
      'home_title': 'Welcome to Taskora',
      'home_subtitle': 'Academic schedule & task companion',

      // Overview KPI Cards
      'overview_lectures': 'Classes Today',
      'overview_tasks': 'Pending Tasks',
      'overview_deadlines': 'Upcoming Due',

      // Next Lecture Card
      'next_lecture_title': 'Next Lecture',
      'no_upcoming_lecture': 'No upcoming lectures today',
      'no_upcoming_lecture_desc':
          'Enjoy your free time or prepare for upcoming classes.',
      'view_weekly_schedule': 'View Full Schedule',
      'course_name': 'Course',
      'time': 'Time',
      'location': 'Location',
      'instructor': 'Instructor',

      // Today's Schedule Preview
      'todays_schedule': "Today's Schedule",
      'view_all': 'View All',
      'empty_schedule_msg':
          'No lectures on your schedule for today. Add a class to stay organized.',
      'add_lecture': 'Add Lecture',
      'import_schedule': 'Import Schedule',

      // Tasks Preview
      'tasks_preview_title': 'Upcoming Tasks',
      'all_caught_up': 'All caught up!',
      'empty_tasks_msg': 'No pending tasks or deadlines right now.',
      'add_task': 'Add Task',

      // Quick Actions
      'quick_actions': 'Quick Actions',
      'quick_action_add_task': 'New Task',
      'quick_action_add_lecture': 'New Class',
      'quick_action_import': 'Import Schedule',

      // Schedule Screen
      'schedule_title': 'Weekly Timetable',
      'schedule_page_subtitle':
          'Manage your weekly course schedule and lecture halls',
      'schedule_placeholder':
          'Weekly timetable management will be powered by local SQLite in the next phase.',
      'empty_day_lectures': 'No lectures for this day',
      'empty_day_desc':
          'Add a class or import your semester schedule to populate this day.',
      'day_sun': 'Sun',
      'day_mon': 'Mon',
      'day_tue': 'Tue',
      'day_wed': 'Wed',
      'day_thu': 'Thu',
      'day_fri': 'Fri',
      'day_sat': 'Sat',

      // Tasks Screen
      'tasks_title': 'Assignments & Deadlines',
      'tasks_page_subtitle': 'Track homework, assignments, and exam deadlines',
      'tasks_placeholder':
          'Task tracking and priority flags are stored offline in local SQLite.',
      'tasks_summary_pending': 'Pending',
      'tasks_summary_completed': 'Completed',
      'tasks_summary_overdue': 'Overdue',
      'search_tasks_hint': 'Search assignments or courses...',
      'filter_all': 'All',
      'filter_pending': 'Pending',
      'filter_completed': 'Completed',
      'filter_overdue': 'Overdue',
      'filter_high': 'High',
      'filter_medium': 'Medium',
      'filter_low': 'Low',
      'priority_high': 'High Priority',
      'priority_medium': 'Medium Priority',
      'priority_low': 'Low Priority',
      'due_date': 'Due Date',
      'due_time': 'Due Time',
      'due_today': 'Due Today',
      'due_tomorrow': 'Due Tomorrow',
      'task_overdue': 'Overdue',
      'task_completed': 'Completed',
      'no_tasks_in_filter': 'No tasks found in this category',
      'create_first_task':
          'Add your assignments or exam dates to track them here.',
      'pending_tasks_tab': 'Pending',
      'completed_tasks_tab': 'Completed',
      'delete': 'Delete',
      'edit_task': 'Edit Task',
      'delete_task': 'Delete Task',
      'delete_task_confirm': 'Are you sure you want to delete this task?',
      'task_title_label': 'Task Title',
      'task_title_hint': 'e.g. Distributed Systems Lab 2',
      'task_title_required': 'Task title cannot be empty',
      'task_desc_label': 'Description (Optional)',
      'task_desc_hint': 'Add notes, submission link, or requirements...',
      'task_course_label': 'Course / Subject (Optional)',
      'task_course_hint': 'e.g. CS401',
      'save_task': 'Save Task',
      'update_task': 'Update Task',
      'empty_tasks_all': 'No tasks created yet',
      'empty_tasks_all_desc':
          'Add your homework, assignments, or study deadlines.',
      'empty_tasks_pending': 'All caught up!',
      'empty_tasks_pending_desc':
          'No pending tasks on your schedule right now.',
      'empty_tasks_completed': 'No completed tasks yet',
      'empty_tasks_completed_desc':
          'Finished tasks will be kept here for reference.',
      'empty_tasks_overdue': 'No overdue tasks',
      'empty_tasks_overdue_desc': "You're on track with all your deadlines!",
      'empty_tasks_search': 'No matching tasks found',
      'empty_tasks_search_desc': 'Try searching with a different term.',

      // Settings Screen
      'settings_title': 'Settings',
      'preferences_section': 'Preferences',
      'theme_mode': 'Theme Mode',
      'theme_system': 'System Default',
      'theme_light': 'Light',
      'theme_dark': 'Dark',
      'language': 'Language',
      'lang_english': 'English',
      'lang_arabic': 'العربية (Arabic)',
      'storage_privacy_section': 'Storage & Privacy',
      'offline_status_title': 'Offline Mode Active',
      'offline_status_desc':
          'Data is stored locally on this device. No account required.',
      'offline_private_storage': '100% Offline & Private',
      'offline_private_desc':
          'Your schedule and tasks stay strictly on your device. Zero tracking, zero cloud login required.',
      'about_title': 'About',
      'about_architecture': 'Architecture Foundation',
      'about_architecture_desc':
          'Feature-First with Cubit, GetIt, and Drift SQLite offline storage.',
      'app_version': 'Version 1.0.0',

      // Feature Preview Sheets
      'action_preview_title': 'Feature Preview',
      'action_preview_desc':
          'This entry point will connect to local SQLite storage in Phase 3.',
      'import_sheet_title': 'Import Schedule',
      'import_sheet_desc':
          'Import your timetable from a photo, screenshot, or PDF document. This feature is planned for a future update after schedule and task management foundations are complete, with timetable extraction and an interactive review step.',
      'import_from_image': 'Import from Image (Photo / Screenshot)',
      'import_from_pdf': 'Import from PDF Document',
      'feature_coming_soon': 'Coming Soon',
      'close': 'Close',
      'got_it': 'Got it',

      // Import Schedule Feature
      'import_source_title': 'Select Schedule Document',
      'import_source_desc':
          'Select a timetable image, screenshot, or PDF document. All processing is performed strictly on your device.',
      'import_from_gallery': 'Choose from Gallery',
      'import_from_camera': 'Take Photo with Camera',
      'import_processing_ocr': 'Extracting text with on-device OCR...',
      'import_processing_pdf': 'Extracting text from PDF document...',
      'import_processing_parsing': 'Analyzing timetable schedule...',
      'import_review_title': 'Review Extracted Schedule',
      'import_review_subtitle':
          'Verify and correct detected lectures before saving to your schedule',
      'import_ready_count': '{count} Ready',
      'import_needs_fix_count': '{count} Incomplete',
      'import_conflicts_count': '{count} Overlaps',
      'import_duplicates_count': '{count} Duplicates',
      'import_add_lecture': 'Add Class',
      'import_confirm_button': 'Import Classes',
      'import_saving_message': 'Saving lectures to schedule database...',
      'import_success_title': 'Import Completed!',
      'import_success_message': 'Successfully added classes to your schedule.',
      'import_skipped_duplicates': 'existing duplicate classes skipped.',
      'import_empty_title': 'No Classes Detected',
      'import_empty_desc':
          'Could not automatically identify timetable entries in this document. You can add lectures manually or try another clear image/PDF.',
      'import_view_schedule': 'View Schedule',
      'import_edit_candidate': 'Edit Class',
      'import_save_changes': 'Save Changes',
      'import_missing_day': 'Select weekday',
      'import_invalid_time': 'End time must be after start time',
      'import_missing_title': 'Course name required',
      'import_duplicate_badge': 'Already in schedule',
      'import_conflict_badge': 'Time conflict',
      'import_from_csv': 'Import CSV File',
      'import_from_csv_desc': 'Predictable timetable with standard headers',
      'download_csv_template': 'Download CSV Template',
      'download_csv_template_desc':
          'Standard spreadsheet template with clearly labeled examples. Open in Excel, Google Sheets, or any text editor.',
      'csv_template_copied': 'CSV template copied to clipboard!',
      'csv_template_saved': 'CSV template saved to your device!',
      'copy_to_clipboard': 'Copy to Clipboard',
      'save_csv_file': 'Save CSV File',
      'import_processing_csv': 'Analyzing and validating CSV timetable...',
    },
    'ar': {
      'app_title': 'تاسكورا',
      'nav_home': 'الرئيسية',
      'nav_schedule': 'الجدول',
      'nav_tasks': 'المهام',
      'nav_settings': 'الإعدادات',

      // Greetings & Header
      'greeting_morning': 'صباح الخير',
      'greeting_afternoon': 'مساء الخير',
      'greeting_evening': 'مساء الخير',
      'home_title': 'مرحباً بك في تاسكورا',
      'home_subtitle': 'رفيقك لتنظيم جدولك الدراسي ومهامك الجامعية',

      // Overview KPI Cards
      'overview_lectures': 'محاضرات اليوم',
      'overview_tasks': 'مهام معلقة',
      'overview_deadlines': 'مواعيد قادمة',

      // Next Lecture Card
      'next_lecture_title': 'المحاضرة القادمة',
      'no_upcoming_lecture': 'لا توجد محاضرات قادمة اليوم',
      'no_upcoming_lecture_desc':
          'استمتع بوقت فراغك أو استعد للمحاضرات القادمة.',
      'view_weekly_schedule': 'عرض الجدول الأسبوعي',
      'course_name': 'المقرر',
      'time': 'الوقت',
      'location': 'القاعة',
      'instructor': 'المحاضر',

      // Today's Schedule Preview
      'todays_schedule': 'جدول اليوم',
      'view_all': 'عرض الكل',
      'empty_schedule_msg':
          'لا توجد محاضرات مجدولة لليوم. أضف مقرراتك لبناء جدولك.',
      'add_lecture': 'إضافة محاضرة',
      'import_schedule': 'استيراد جدول',

      // Tasks Preview
      'tasks_preview_title': 'المهام القادمة',
      'all_caught_up': 'أحسنت! لا توجد مهام',
      'empty_tasks_msg': 'لا توجد واجبات أو مواعيد نهائية معلقة حالياً.',
      'add_task': 'إضافة مهمة',

      // Quick Actions
      'quick_actions': 'إجراءات سريعة',
      'quick_action_add_task': 'مهمة جديدة',
      'quick_action_add_lecture': 'محاضرة جديدة',
      'quick_action_import': 'استيراد جدول',

      // Schedule Screen
      'schedule_title': 'الجدول الأسبوعي',
      'schedule_page_subtitle':
          'إدارة مواعيد محاضراتك وقاعاتك الدراسية خلال الأسبوع',
      'schedule_placeholder':
          'إدارة الجدول الأسبوعي ستعمل عبر قاعدة بيانات SQLite المحلية في المرحلة القادمة.',
      'empty_day_lectures': 'لا توجد محاضرات في هذا اليوم',
      'empty_day_desc':
          'أضف محاضرة أو استورد جدولك للفصل الدراسي لإضافتها لهذا اليوم.',
      'day_sun': 'الأحد',
      'day_mon': 'الإثنين',
      'day_tue': 'الثلاثاء',
      'day_wed': 'الأربعاء',
      'day_thu': 'الخميس',
      'day_fri': 'الجمعة',
      'day_sat': 'السبت',

      // Tasks Screen
      'tasks_title': 'الواجبات والمواعيد النهائية',
      'tasks_page_subtitle':
          'تتبع الواجبات المنزلية، المشاريع، ومواعيد الاختبارات',
      'tasks_placeholder':
          'تتبع المهام والأولويات مخزن محلياً بالكامل عبر SQLite.',
      'tasks_summary_pending': 'قيد الانتظار',
      'tasks_summary_completed': 'المكتملة',
      'tasks_summary_overdue': 'المتأخرة',
      'search_tasks_hint': 'البحث في المهام والمقررات...',
      'filter_all': 'الكل',
      'filter_pending': 'قيد الانتظار',
      'filter_completed': 'المكتملة',
      'filter_overdue': 'المتأخرة',
      'filter_high': 'عالية',
      'filter_medium': 'متوسطة',
      'filter_low': 'منخفضة',
      'priority_high': 'أولوية عالية',
      'priority_medium': 'أولوية متوسطة',
      'priority_low': 'أولوية منخفضة',
      'due_date': 'تاريخ التسليم',
      'due_time': 'وقت التسليم',
      'due_today': 'الموعد اليوم',
      'due_tomorrow': 'الموعد غداً',
      'task_overdue': 'متأخرة',
      'task_completed': 'مكتملة',
      'no_tasks_in_filter': 'لا توجد مهام في هذا التصنيف',
      'create_first_task':
          'أضف واجباتك أو مواعيد اختباراتك لتتبعها بسهولة هنا.',
      'pending_tasks_tab': 'قيد الانتظار',
      'completed_tasks_tab': 'المكتملة',
      'delete': 'حذف',
      'edit_task': 'تعديل المهمة',
      'delete_task': 'حذف المهمة',
      'delete_task_confirm': 'هل أنت متأكد من رغبتك في حذف هذه المهمة؟',
      'task_title_label': 'عنوان المهمة',
      'task_title_hint': 'مثال: تسليم تقرير النظم الموزعة',
      'task_title_required': 'عنوان المهمة مطلوب ولا يمكن تركه فارغاً',
      'task_desc_label': 'الوصف (اختياري)',
      'task_desc_hint': 'أضف أي تفاصيل أو متطلبات للمهمة...',
      'task_course_label': 'المقرر / المادة (اختياري)',
      'task_course_hint': 'مثال: CS401',
      'save_task': 'حفظ المهمة',
      'update_task': 'تحديث المهمة',
      'empty_tasks_all': 'لا توجد مهام حتى الآن',
      'empty_tasks_all_desc': 'أضف واجباتك، مشاريعك، ومواعيد تسليمك الدراسية.',
      'empty_tasks_pending': 'أحسنت! لا توجد مهام معلقة',
      'empty_tasks_pending_desc': 'لقد أنجزت جميع واجباتك الحالية.',
      'empty_tasks_completed': 'لا توجد مهام مكتملة بعد',
      'empty_tasks_completed_desc':
          'المهام التي تنجزها ستبقى محفوظة هنا للرجوع إليها.',
      'empty_tasks_overdue': 'لا توجد مهام متأخرة',
      'empty_tasks_overdue_desc': 'رائع! أنت ملتزم بجميع مواعيدك النهائية.',
      'empty_tasks_search': 'لم يتم العثور على نتائج مطابقة',
      'empty_tasks_search_desc': 'جرب البحث باستخدام كلمة مفتاحية أخرى.',

      // Settings Screen
      'settings_title': 'الإعدادات',
      'preferences_section': 'التفضيلات',
      'theme_mode': 'المظهر',
      'theme_system': 'تلقائي (حسب النظام)',
      'theme_light': 'فاتح',
      'theme_dark': 'داكن',
      'language': 'اللغة',
      'lang_english': 'English (الإنجليزية)',
      'lang_arabic': 'العربية',
      'storage_privacy_section': 'التخزين والخصوصية',
      'offline_status_title': 'وضع عدم الاتصال مفعل',
      'offline_status_desc':
          'البيانات مخزنة محلياً بالكامل على هذا الجهاز دون الحاجة لحساب.',
      'offline_private_storage': 'بيانات محلية وخاصة 100%',
      'offline_private_desc':
          'تبقى بياناتك الأكاديمية على جهازك بأمان تام بدون تتبع أو مزامنة سحابية أو حاجة لحساب.',
      'about_title': 'عن التطبيق',
      'about_architecture': 'أساس البنية البرمجية',
      'about_architecture_desc':
          'معمارية Feature-First باستخدام Cubit و GetIt وقاعدة بيانات SQLite عبر Drift.',
      'app_version': 'الإصدار 1.0.0',

      // Feature Preview Sheets
      'action_preview_title': 'معاينة الميزة',
      'action_preview_desc':
          'سيرتبط هذا الإجراء بقاعدة بيانات SQLite المحلية في المرحلة القادمة.',
      'import_sheet_title': 'استيراد الجدول الدراسي',
      'import_sheet_desc':
          'استيراد جدولك الدراسي من صورة أو لقطة شاشة أو مستند PDF. ستتوفر هذه الميزة في تحديث قادم بعد اكتمال أساسيات إدارة الجدول والمهام، مع استخراج بيانات الجدول ومراجعتها وتعديلها.',
      'import_from_image': 'استيراد من صورة (لقطة شاشة / كاميرا)',
      'import_from_pdf': 'استيراد من مستند PDF',
      'feature_coming_soon': 'قادمة قريباً',
      'close': 'إغلاق',
      'got_it': 'حسناً',

      // Import Schedule Feature
      'import_source_title': 'تحديد مستند الجدول',
      'import_source_desc':
          'اختر صورة للجدول، لقطة شاشة، أو مستند PDF. تتم المعالجة بالكامل محلياً على جهازك دون اتصال بالإنترنت.',
      'import_from_gallery': 'اختيار من المعرض',
      'import_from_camera': 'التقاط صورة بالكاميرا',
      'import_processing_ocr': 'جارٍ استخراج النصوص محلياً (OCR)...',
      'import_processing_pdf': 'جارٍ استخراج النصوص من ملف PDF...',
      'import_processing_parsing': 'جارٍ تحليل الجدول الأكاديمي...',
      'import_review_title': 'مراجعة الجدول المستخرج',
      'import_review_subtitle':
          'تحقق من المحاضرات المستخرجة وقم بتصحيحها قبل حفظها',
      'import_ready_count': '{count} جاهزة',
      'import_needs_fix_count': '{count} بحاجة لتعديل',
      'import_conflicts_count': '{count} تعارضات',
      'import_duplicates_count': '{count} مكررة',
      'import_add_lecture': 'إضافة محاضرة',
      'import_confirm_button': 'استيراد المحاضرات',
      'import_saving_message': 'جارٍ حفظ المحاضرات في قاعدة البيانات...',
      'import_success_title': 'تم الاستيراد بنجاح!',
      'import_success_message': 'تمت إضافة المحاضرات إلى جدولك الأسبوعي.',
      'import_skipped_duplicates': 'محاضرة مكررة تم تخطيها.',
      'import_empty_title': 'لم يتم العثور على محاضرات',
      'import_empty_desc':
          'تعذر التعرف التلقائي على بيانات جدول في هذا المستند. يمكنك إضافة المحاضرات يدوياً أو تجربة مستند أكثر وضوحاً.',
      'import_view_schedule': 'عرض الجدول',
      'import_edit_candidate': 'تعديل المحاضرة',
      'import_save_changes': 'حفظ التعديلات',
      'import_missing_day': 'حدد اليوم الدراسي',
      'import_invalid_time': 'وقت النهاية يجب أن يكون بعد وقت البداية',
      'import_missing_title': 'اسم المقرر مطلوب',
      'import_duplicate_badge': 'موجودة مسبقاً',
      'import_conflict_badge': 'تعارض في التوقيت',
      'import_from_csv': 'استيراد من ملف CSV',
      'import_from_csv_desc': 'جدول مهيكل بدقة مع رؤوس الأعمدة القياسية',
      'download_csv_template': 'تحميل نموذج CSV',
      'download_csv_template_desc':
          'نموذج جدول قياسي جاهز يحتوي على أمثلة توضيحية. يمكنك فتحه عبر Excel أو Google Sheets أو أي محرر نصوص.',
      'csv_template_copied': 'تم نسخ نموذج CSV إلى الحافظة بنجاح!',
      'csv_template_saved': 'تم حفظ نموذج CSV على جهازك بنجاح!',
      'copy_to_clipboard': 'نسخ إلى الحافظة',
      'save_csv_file': 'حفظ ملف CSV',
      'import_processing_csv': 'جارٍ فحص وتحليل جدول CSV...',
    },
  };

  String translate(String key) {
    final languageCode = locale.languageCode;
    return _localizedValues[languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }

  // Getters for convenience
  String get appTitle => translate('app_title');
  String get navHome => translate('nav_home');
  String get navSchedule => translate('nav_schedule');
  String get navTasks => translate('nav_tasks');
  String get navSettings => translate('nav_settings');

  String get greetingMorning => translate('greeting_morning');
  String get greetingAfternoon => translate('greeting_afternoon');
  String get greetingEvening => translate('greeting_evening');
  String get homeTitle => translate('home_title');
  String get homeSubtitle => translate('home_subtitle');

  String get overviewLectures => translate('overview_lectures');
  String get overviewTasks => translate('overview_tasks');
  String get overviewDeadlines => translate('overview_deadlines');

  String get nextLectureTitle => translate('next_lecture_title');
  String get noUpcomingLecture => translate('no_upcoming_lecture');
  String get noLecturesToday => translate('no_upcoming_lecture');
  String get noUpcomingLectureDesc => translate('no_upcoming_lecture_desc');
  String get viewWeeklySchedule => translate('view_weekly_schedule');
  String get courseName => translate('course_name');
  String get time => translate('time');
  String get location => translate('location');
  String get instructor => translate('instructor');

  String get todaysSchedule => translate('todays_schedule');
  String get viewAll => translate('view_all');
  String get emptyScheduleMsg => translate('empty_schedule_msg');
  String get addLecture => translate('add_lecture');
  String get importSchedule => translate('import_schedule');

  String get tasksPreviewTitle => translate('tasks_preview_title');
  String get allCaughtUp => translate('all_caught_up');
  String get emptyTasksMsg => translate('empty_tasks_msg');
  String get addTask => translate('add_task');

  String get quickActions => translate('quick_actions');
  String get quickActionAddTask => translate('quick_action_add_task');
  String get quickActionAddLecture => translate('quick_action_add_lecture');
  String get quickActionImport => translate('quick_action_import');

  String get scheduleTitle => translate('schedule_title');
  String get schedulePageSubtitle => translate('schedule_page_subtitle');
  String get schedulePlaceholder => translate('schedule_placeholder');
  String get emptyDayLectures => translate('empty_day_lectures');
  String get emptyDayDesc => translate('empty_day_desc');

  String get tasksTitle => translate('tasks_title');
  String get tasksPageSubtitle => translate('tasks_page_subtitle');
  String get tasksPlaceholder => translate('tasks_placeholder');
  String get tasksSummaryPending => translate('tasks_summary_pending');
  String get tasksSummaryCompleted => translate('tasks_summary_completed');
  String get tasksSummaryOverdue => translate('tasks_summary_overdue');
  String get searchTasksHint => translate('search_tasks_hint');
  String get filterAll => translate('filter_all');
  String get filterPending => translate('filter_pending');
  String get filterCompleted => translate('filter_completed');
  String get filterOverdue => translate('filter_overdue');
  String get filterHigh => translate('filter_high');
  String get filterMedium => translate('filter_medium');
  String get filterLow => translate('filter_low');
  String get priorityHigh => translate('priority_high');
  String get priorityMedium => translate('priority_medium');
  String get priorityLow => translate('priority_low');
  String get dueDateLabel => translate('due_date');
  String get dueTimeLabel => translate('due_time');
  String get dueToday => translate('due_today');
  String get dueTomorrow => translate('due_tomorrow');
  String get taskOverdue => translate('task_overdue');
  String get taskCompleted => translate('task_completed');
  String get noTasksInFilter => translate('no_tasks_in_filter');
  String get createFirstTask => translate('create_first_task');
  String get pendingTasksTab => translate('pending_tasks_tab');
  String get completedTasksTab => translate('completed_tasks_tab');
  String get editTask => translate('edit_task');
  String get delete => translate('delete');
  String get deleteTask => translate('delete_task');
  String get deleteTaskConfirm => translate('delete_task_confirm');
  String get taskTitleLabel => translate('task_title_label');
  String get taskTitleHint => translate('task_title_hint');
  String get taskTitleRequired => translate('task_title_required');
  String get taskDescLabel => translate('task_desc_label');
  String get taskDescHint => translate('task_desc_hint');
  String get taskCourseLabel => translate('task_course_label');
  String get taskCourseHint => translate('task_course_hint');
  String get saveTask => translate('save_task');
  String get updateTask => translate('update_task');
  String get emptyTasksAll => translate('empty_tasks_all');
  String get emptyTasksAllDesc => translate('empty_tasks_all_desc');
  String get emptyTasksPending => translate('empty_tasks_pending');
  String get emptyTasksPendingDesc => translate('empty_tasks_pending_desc');
  String get emptyTasksCompleted => translate('empty_tasks_completed');
  String get emptyTasksCompletedDesc => translate('empty_tasks_completed_desc');
  String get emptyTasksOverdue => translate('empty_tasks_overdue');
  String get emptyTasksOverdueDesc => translate('empty_tasks_overdue_desc');
  String get emptyTasksSearch => translate('empty_tasks_search');
  String get emptyTasksSearchDesc => translate('empty_tasks_search_desc');

  String get settingsTitle => translate('settings_title');
  String get preferencesSection => translate('preferences_section');
  String get themeMode => translate('theme_mode');
  String get themeSystem => translate('theme_system');
  String get themeLight => translate('theme_light');
  String get themeDark => translate('theme_dark');
  String get language => translate('language');
  String get langEnglish => translate('lang_english');
  String get langArabic => translate('lang_arabic');
  String get storagePrivacySection => translate('storage_privacy_section');
  String get offlineStatusTitle => translate('offline_status_title');
  String get offlineStatusDesc => translate('offline_status_desc');
  String get offlinePrivateStorage => translate('offline_private_storage');
  String get offlinePrivateDesc => translate('offline_private_desc');
  String get aboutTitle => translate('about_title');
  String get aboutArchitecture => translate('about_architecture');
  String get aboutArchitectureDesc => translate('about_architecture_desc');
  String get appVersion => translate('app_version');

  String get actionPreviewTitle => translate('action_preview_title');
  String get actionPreviewDesc => translate('action_preview_desc');
  String get importSheetTitle => translate('import_sheet_title');
  String get importSheetDesc => translate('import_sheet_desc');
  String get importFromImage => translate('import_from_image');
  String get importFromPdf => translate('import_from_pdf');
  String get featureComingSoon => translate('feature_coming_soon');
  String get close => translate('close');
  String get gotIt => translate('got_it');

  // Import Schedule Getters
  String get importSourceTitle => translate('import_source_title');
  String get importSourceDesc => translate('import_source_desc');
  String get importFromGallery => translate('import_from_gallery');
  String get importFromCamera => translate('import_from_camera');
  String get importProcessingOcr => translate('import_processing_ocr');
  String get importProcessingPdf => translate('import_processing_pdf');
  String get importProcessingParsing => translate('import_processing_parsing');
  String get importReviewTitle => translate('import_review_title');
  String get importReviewSubtitle => translate('import_review_subtitle');
  String importReadyCount(int count) =>
      translate('import_ready_count').replaceAll('{count}', count.toString());
  String importNeedsFixCount(int count) => translate(
    'import_needs_fix_count',
  ).replaceAll('{count}', count.toString());
  String importConflictsCount(int count) => translate(
    'import_conflicts_count',
  ).replaceAll('{count}', count.toString());
  String importDuplicatesCount(int count) => translate(
    'import_duplicates_count',
  ).replaceAll('{count}', count.toString());
  String get importAddLecture => translate('import_add_lecture');
  String get importConfirmButton => translate('import_confirm_button');
  String get importSavingMessage => translate('import_saving_message');
  String get importSuccessTitle => translate('import_success_title');
  String get importSuccessMessage => translate('import_success_message');
  String get importSkippedDuplicates => translate('import_skipped_duplicates');
  String get importEmptyTitle => translate('import_empty_title');
  String get importEmptyDesc => translate('import_empty_desc');
  String get importViewSchedule => translate('import_view_schedule');
  String get importEditCandidate => translate('import_edit_candidate');
  String get importSaveChanges => translate('import_save_changes');
  String get importMissingDay => translate('import_missing_day');
  String get importInvalidTime => translate('import_invalid_time');
  String get importMissingTitle => translate('import_missing_title');
  String get importDuplicateBadge => translate('import_duplicate_badge');
  String get importConflictBadge => translate('import_conflict_badge');
  String get importFromCsv => translate('import_from_csv');
  String get importFromCsvDesc => translate('import_from_csv_desc');
  String get downloadCsvTemplate => translate('download_csv_template');
  String get downloadCsvTemplateDesc => translate('download_csv_template_desc');
  String get csvTemplateCopied => translate('csv_template_copied');
  String get csvTemplateSaved => translate('csv_template_saved');
  String get copyToClipboard => translate('copy_to_clipboard');
  String get saveCsvFile => translate('save_csv_file');
  String get importProcessingCsv => translate('import_processing_csv');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
