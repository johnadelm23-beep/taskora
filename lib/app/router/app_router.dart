import 'package:flutter/material.dart';
import 'package:taskora/features/import_schedule/presentation/screens/import_review_screen.dart';
import 'package:taskora/features/shell/presentation/screens/main_shell_screen.dart';

class AppRouter {
  AppRouter._();

  static const String initialRoute = '/';
  static const String importReviewRoute = '/import-review';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case importReviewRoute:
        return MaterialPageRoute(
          builder: (_) => const ImportReviewScreen(),
          settings: settings,
        );
      case initialRoute:
      default:
        return MaterialPageRoute(
          builder: (_) => const MainShellScreen(),
          settings: settings,
        );
    }
  }
}
