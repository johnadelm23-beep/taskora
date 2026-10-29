import 'package:flutter/foundation.dart';

/// Diagnostic logger for the timetable extraction and parsing pipeline.
///
/// Designed to capture debugging information during development without
/// leaking student document contents into production or crash logs.
class ImportDiagnosticLogger {
  static final List<String> _diagnosticEvents = [];

  /// Returns recent diagnostic events (useful for in-app debug panels if needed).
  static List<String> get events => List.unmodifiable(_diagnosticEvents);

  /// Clears logged diagnostic events.
  static void clear() {
    _diagnosticEvents.clear();
  }

  /// Records an extraction stage event.
  static void log(String stage, {Map<String, dynamic>? metadata}) {
    final timestamp = DateTime.now().toIso8601String();
    final buffer = StringBuffer('[$timestamp] [ImportDiagnostic] [$stage]');

    if (metadata != null && metadata.isNotEmpty) {
      buffer.write(' - ');
      final safeEntries = metadata.entries.map((e) {
        // Redact or summarize potentially private student text in production
        if (!kDebugMode && _isSensitiveKey(e.key)) {
          return '${e.key}: [REDACTED_LENGTH_${(e.value?.toString().length ?? 0)}]';
        }
        return '${e.key}: ${e.value}';
      });
      buffer.write(safeEntries.join(', '));
    }

    final entry = buffer.toString();
    _diagnosticEvents.add(entry);

    if (kDebugMode) {
      debugPrint(entry);
    }
  }

  static bool _isSensitiveKey(String key) {
    final lower = key.toLowerCase();
    return lower.contains('text') ||
        lower.contains('raw') ||
        lower.contains('content') ||
        lower.contains('name') ||
        lower.contains('student');
  }
}
