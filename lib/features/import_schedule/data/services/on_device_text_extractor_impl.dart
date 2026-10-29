import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart'
    hide TextLine;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:taskora/features/import_schedule/domain/services/arabic_text_normalizer.dart';
import 'package:taskora/features/import_schedule/domain/services/import_diagnostic_logger.dart';
import 'package:taskora/features/import_schedule/domain/services/text_extractor_service.dart';

class OnDeviceTextExtractorImpl implements TextExtractorService {
  @override
  Future<String> extractTextFromImage(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      throw FileSystemException('Image file does not exist', imagePath);
    }

    ImportDiagnosticLogger.log(
      'extractTextFromImage:start',
      metadata: {'path': file.path, 'size': await file.length()},
    );

    final inputImage = InputImage.fromFilePath(imagePath);
    // Note: Google ML Kit on-device text recognition v2 uses TextRecognitionScript.latin.
    // It provides robust on-device extraction for Latin schedules.
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final recognizedText = await textRecognizer.processImage(inputImage);
      var text = recognizedText.text;

      // Apply Arabic normalization in case mixed content or mojibake is present
      text = ArabicTextNormalizer.cleanAndNormalizeArabic(text);

      ImportDiagnosticLogger.log(
        'extractTextFromImage:complete',
        metadata: {
          'blocksCount': recognizedText.blocks.length,
          'extractedLength': text.length,
        },
      );

      return text;
    } finally {
      await textRecognizer.close();
    }
  }

  @override
  Future<String> extractTextFromPdf(String pdfPath) async {
    final file = File(pdfPath);
    if (!await file.exists()) {
      throw FileSystemException('PDF file does not exist', pdfPath);
    }

    final fileSize = await file.length();
    ImportDiagnosticLogger.log(
      'extractTextFromPdf:start',
      metadata: {'path': file.path, 'fileSize': fileSize},
    );

    // Offload CPU-heavy PDF reading, layout analysis, and text extraction
    // to a background isolate using compute() to keep the UI thread running at 60 fps.
    final fullText = await compute(_extractPdfTextInternal, pdfPath);

    ImportDiagnosticLogger.log(
      'extractTextFromPdf:complete',
      metadata: {'extractedLength': fullText.length},
    );

    return fullText;
  }

  static Future<String> _extractPdfTextInternal(String pdfPath) async {
    final file = File(pdfPath);
    final bytes = await file.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    try {
      final pageCount = document.pages.count;
      final extractor = PdfTextExtractor(document);
      final pageOutputs = <String>[];

      for (var pageIdx = 0; pageIdx < pageCount; pageIdx++) {
        final lines = extractor.extractTextLines(
          startPageIndex: pageIdx,
          endPageIndex: pageIdx,
        );

        if (lines.isNotEmpty) {
          // Check if this page is a 2D grid timetable (time slot column headers with matrix cells)
          final gridTableText = _tryExtract2DGridTable(lines);
          if (gridTableText != null && gridTableText.trim().isNotEmpty) {
            pageOutputs.add(gridTableText);
            continue;
          }

          // Otherwise, sort lines vertically from top to bottom (y ascending)
          final sortedLines = List<TextLine>.from(lines)
            ..sort((a, b) => a.bounds.top.compareTo(b.bounds.top));

          final pageBuffer = StringBuffer();

          for (final line in sortedLines) {
            final isRtlLine = ArabicTextNormalizer.hasArabicCharacters(
              line.text,
            );
            final words = line.wordCollection;

            if (words.isEmpty || isRtlLine) {
              // In Arabic/RTL, line.text contains full coherent words.
              // Normalize presentation forms and mojibake directly without splitting into letters.
              final rawLine = ArabicTextNormalizer.cleanAndNormalizeArabic(
                line.text,
              );
              if (rawLine.isNotEmpty) {
                pageBuffer.writeln(rawLine);
              }
              continue;
            }

            // For Latin/English text, reconstruct line with column cell boundary detection
            final sortedWords = List<TextWord>.from(words)
              ..sort((a, b) => a.bounds.left.compareTo(b.bounds.left));

            TextWord? lastNonEmptyWord;
            final lineWords = <String>[];
            for (var wIdx = 0; wIdx < sortedWords.length; wIdx++) {
              final word = sortedWords[wIdx];
              final cleanedWord = word.text.trim();
              if (cleanedWord.isEmpty) continue;

              if (lastNonEmptyWord != null) {
                final gap = word.bounds.left - lastNonEmptyWord.bounds.right;
                // Significant horizontal gap (>= 18.0) indicates a table column cell boundary
                if (gap.abs() >= 18.0) {
                  lineWords.add('|');
                }
              }
              lastNonEmptyWord = word;
              lineWords.add(cleanedWord);
            }

            final reconstructedLine = lineWords.join(' ').trim();
            if (reconstructedLine.isNotEmpty) {
              pageBuffer.writeln(reconstructedLine);
            }
          }

          final pageText = pageBuffer.toString().trim();
          if (pageText.isNotEmpty) {
            pageOutputs.add(pageText);
          }
        } else {
          // Fallback to extractText() for this page if extractTextLines yielded no items
          final rawPageText = extractor.extractText(
            startPageIndex: pageIdx,
            endPageIndex: pageIdx,
          );
          final cleaned = ArabicTextNormalizer.cleanAndNormalizeArabic(
            rawPageText,
          );
          if (cleaned.isNotEmpty) {
            pageOutputs.add(cleaned);
          }
        }
      }

      var fullText = pageOutputs.join('\n\n');

      // Final fallback if page extraction produced empty string
      if (fullText.trim().isEmpty) {
        final fallbackRaw = extractor.extractText();
        fullText = ArabicTextNormalizer.cleanAndNormalizeArabic(fallbackRaw);
      }

      return fullText;
    } finally {
      document.dispose();
    }
  }

  /// Extracts structured table rows from a 2D grid timetable page.
  /// Detects day header, time columns across horizontal header band, and clusters content cells.
  static String? _tryExtract2DGridTable(List<TextLine> lines) {
    if (lines.length < 5) return null;

    // 1. Detect Day at page header (typically top < 85)
    String? dayName;
    for (final line in lines) {
      if (line.bounds.top > 85) break;
      final norm = ArabicTextNormalizer.cleanAndNormalizeArabic(line.text);
      if (norm.contains('السبت') || norm.toLowerCase().contains('saturday')) {
        dayName = 'السبت';
        break;
      }
      if (norm.contains('الأحد') ||
          norm.contains('الاحد') ||
          norm.toLowerCase().contains('sunday')) {
        dayName = 'الأحد';
        break;
      }
      if (norm.contains('الإثنين') ||
          norm.contains('الاثنين') ||
          norm.toLowerCase().contains('monday')) {
        dayName = 'الإثنين';
        break;
      }
      if (norm.contains('الثلاثاء') || norm.toLowerCase().contains('tuesday')) {
        dayName = 'الثلاثاء';
        break;
      }
      if (norm.contains('الأربعاء') ||
          norm.contains('الاربعاء') ||
          norm.toLowerCase().contains('wednesday')) {
        dayName = 'الأربعاء';
        break;
      }
      if (norm.contains('الخميس') || norm.toLowerCase().contains('thursday')) {
        dayName = 'الخميس';
        break;
      }
      if (norm.contains('الجمعة') || norm.toLowerCase().contains('friday')) {
        dayName = 'الجمعة';
        break;
      }
    }

    // 2. Detect Time Columns across the page header band (top >= 80 && top <= 110)
    final timePattern = RegExp(
      r'([01]?[0-9]|2[0-3]):([0-5][0-9])\s*[-–—]\s*([01]?[0-9]|2[0-3]):([0-5][0-9])',
    );
    final timeCols =
        <({double left, double right, String start, String end})>[];

    for (final line in lines) {
      final norm = ArabicTextNormalizer.cleanAndNormalizeArabic(line.text);
      final m = timePattern.firstMatch(norm);
      if (m != null && line.bounds.top >= 80 && line.bounds.top <= 110) {
        var t1h = int.parse(m.group(1)!);
        final t1m = int.parse(m.group(2)!);
        var t2h = int.parse(m.group(3)!);
        final t2m = int.parse(m.group(4)!);

        // Afternoon 1-6 converted to 24-hour (13-18)
        if (t1h >= 1 && t1h <= 6) t1h += 12;
        if (t2h >= 1 && t2h <= 6) t2h += 12;

        int startH = t2h, startM = t2m, endH = t1h, endM = t1m;
        if (t1h < t2h || (t1h == t2h && t1m < t2m)) {
          startH = t1h;
          startM = t1m;
          endH = t2h;
          endM = t2m;
        }

        final startStr =
            '${startH.toString().padLeft(2, '0')}:${startM.toString().padLeft(2, '0')}';
        final endStr =
            '${endH.toString().padLeft(2, '0')}:${endM.toString().padLeft(2, '0')}';
        timeCols.add((
          left: line.bounds.left,
          right: line.bounds.right,
          start: startStr,
          end: endStr,
        ));
      }
    }

    // If fewer than 2 time columns found in the header, this is not a 2D grid table
    if (timeCols.length < 2) return null;

    // Sort time columns from right to left (x descending) for RTL timetables
    timeCols.sort((a, b) => b.left.compareTo(a.left));

    // 3. Extract content lines below the header band (top > 105), excluding row index column (left > 780)
    final contentLines = lines
        .where((l) => l.bounds.top > 105 && l.bounds.left < 780)
        .toList();
    if (contentLines.isEmpty) return null;

    // Cluster content lines into cells based on horizontal alignment (X center within 35)
    // and vertical line contiguity (top gap < 13.0)
    final clusters = <List<TextLine>>[];
    for (final line in contentLines) {
      final lineCenterX = (line.bounds.left + line.bounds.right) / 2;
      List<TextLine>? matchedCluster;
      for (final cluster in clusters) {
        final lastLine = cluster.last;
        final clusterCenterX =
            (lastLine.bounds.left + lastLine.bounds.right) / 2;
        if ((lineCenterX - clusterCenterX).abs() < 35 &&
            (line.bounds.top - lastLine.bounds.top).abs() < 13.0) {
          matchedCluster = cluster;
          break;
        }
      }
      if (matchedCluster != null) {
        matchedCluster.add(line);
      } else {
        clusters.add([line]);
      }
    }

    final buffer = StringBuffer();
    final effectiveDay = dayName ?? '';

    for (final cluster in clusters) {
      final minLeft = cluster
          .map((l) => l.bounds.left)
          .reduce((a, b) => a < b ? a : b);
      final maxRight = cluster
          .map((l) => l.bounds.right)
          .reduce((a, b) => a > b ? a : b);
      final texts = cluster
          .map((l) => ArabicTextNormalizer.cleanAndNormalizeArabic(l.text))
          .toList();

      // Find matching time columns that overlap this cluster's horizontal bounds
      final matchingCols = timeCols.where((col) {
        return col.left <= (maxRight + 15) && col.right >= (minLeft - 15);
      }).toList();

      if (matchingCols.isEmpty) continue;
      matchingCols.sort((a, b) => a.start.compareTo(b.start));
      final start = matchingCols.first.start;
      final end = matchingCols.last.end;

      // Extract course, instructor, room
      String course = '';
      String instructor = '';
      String room = '';

      for (var t in texts) {
        // Standardize inverted room numbers: "3 معمل" -> "معمل 3"
        t = t.replaceAllMapped(
          RegExp(r'^(\d+)\s+(معمل|مدرج|قاعة|مختبر)$'),
          (m) => '${m.group(2)} ${m.group(1)}',
        );
        t = t.replaceAllMapped(
          RegExp(r'^(معمل|مدرج|قاعة|مختبر)\s+(\d+)$'),
          (m) => '${m.group(1)} ${m.group(2)}',
        );

        if (t.startsWith('م/') ||
            t.startsWith('د/') ||
            t.startsWith('أ.د/') ||
            t.startsWith('Dr.') ||
            t.startsWith('Prof.')) {
          instructor = t;
        } else if (t.contains('معمل') ||
            t.contains('مدرج') ||
            t.contains('قاعة') ||
            t.contains('مختبر') ||
            t.contains('عمل') ||
            t.contains('Room') ||
            t.contains('Lab') ||
            t.contains('Hall')) {
          room = t;
        } else if (course.isEmpty && !RegExp(r'^\d+$').hasMatch(t)) {
          course = t;
        }
      }

      if (course.isNotEmpty) {
        buffer.writeln(
          '$effectiveDay | $start - $end | $course | $room | $instructor',
        );
      }
    }

    final result = buffer.toString().trim();
    return result.isNotEmpty ? result : null;
  }
}
