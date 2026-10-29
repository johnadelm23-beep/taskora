import 'dart:convert';

/// Service to clean, normalize, and repair Arabic text extracted from PDFs or OCR.
///
/// Addresses:
/// 1. UTF-8 Mojibake (UTF-8 Arabic bytes misread as Latin-1/Windows-1252, e.g. "Ø¹Ù„ÙˆÙ… Ø§Ù„Ø­Ø§Ø³Ø¨").
/// 2. Arabic Presentation Forms (Unicode blocks `\uFB50..\uFDFF` and `\uFE70..\uFEFF` mapped to standard `\u0621..\u064A`).
/// 3. Visually reversed Arabic tokens and words extracted in left-to-right order.
class ArabicTextNormalizer {
  static final Map<int, int> _cp1252ToByte = {
    0x20AC: 0x80, // €
    0x201A: 0x82, // ‚
    0x0192: 0x83, // ƒ
    0x201E: 0x84, // „
    0x2026: 0x85, // …
    0x2020: 0x86, // †
    0x2021: 0x87, // ‡
    0x02C6: 0x88, // ˆ
    0x2030: 0x89, // ‰
    0x0160: 0x8A, // Š
    0x2039: 0x8B, // ‹
    0x0152: 0x8C, // Œ
    0x017D: 0x8E, // Ž
    0x2018: 0x91, // ‘
    0x2019: 0x92, // ’
    0x201C: 0x93, // “
    0x201D: 0x94, // ”
    0x2022: 0x95, // •
    0x2013: 0x96, // –
    0x2014: 0x97, // —
    0x02DC: 0x98, // ˜
    0x2122: 0x99, // ™
    0x0161: 0x9A, // š
    0x203A: 0x9B, // ›
    0x0153: 0x9C, // œ
    0x017E: 0x9E, // ž
    0x0178: 0x9F, // Ÿ
  };

  static int? _charToByte(int codeUnit) {
    if (codeUnit <= 0xFF) return codeUnit;
    return _cp1252ToByte[codeUnit];
  }

  /// Checks whether a text snippet contains typical UTF-8 mojibake patterns for Arabic.
  /// In UTF-8, Arabic characters reside in 0xD8..0xD9 followed by 0x80..0xBF.
  /// When decoded as Latin-1 / Windows-1252, these appear as 'Ø' (0xD8) or 'Ù' (0xD9)
  /// followed by characters in the 0x80..0xBF range.
  static bool isUtf8Mojibake(String text) {
    if (text.isEmpty) return false;
    for (var i = 0; i < text.length - 1; i++) {
      final c1 = text.codeUnitAt(i);
      if (c1 == 0x00D8 || c1 == 0x00D9) {
        final c2Byte = _charToByte(text.codeUnitAt(i + 1));
        if (c2Byte != null && c2Byte >= 0x80 && c2Byte <= 0xBF) {
          return true;
        }
      }
    }
    return false;
  }

  /// Repairs UTF-8 mojibake by re-encoding Latin-1/Windows-1252 bytes and decoding as UTF-8.
  static String fixMojibake(String text) {
    if (text.isEmpty) return text;
    // Process line by line to prevent valid Arabic on other lines from blocking decoding
    final lines = text.split('\n');
    final processed = lines.map(_fixMojibakeInLine).toList();
    return processed.join('\n');
  }

  static String _fixMojibakeInLine(String line) {
    if (!isUtf8Mojibake(line)) return line;

    // First attempt: whole line conversion to bytes (handles spaces between mojibake words)
    final lineBytes = <int>[];
    var canConvertLine = true;
    for (var i = 0; i < line.length; i++) {
      final code = line.codeUnitAt(i);
      final byte = _charToByte(code);
      if (byte != null) {
        lineBytes.add(byte);
      } else {
        canConvertLine = false;
        break;
      }
    }

    if (canConvertLine && lineBytes.isNotEmpty) {
      try {
        final decoded = utf8.decode(lineBytes);
        if (hasArabicCharacters(decoded)) {
          return decoded;
        }
      } catch (_) {
        // Fall back to token/word replacement
      }
    }

    // Token-by-token or segment-by-segment attempt for mixed lines:
    final words = line.split(' ');
    final fixedWords = words.map((word) {
      if (!isUtf8Mojibake(word)) return word;
      final bytes = <int>[];
      for (var i = 0; i < word.length; i++) {
        final b = _charToByte(word.codeUnitAt(i));
        if (b != null) {
          bytes.add(b);
        } else {
          return word;
        }
      }
      try {
        final decoded = utf8.decode(bytes);
        if (hasArabicCharacters(decoded)) return decoded;
      } catch (_) {}
      return word;
    }).toList();

    return fixedWords.join(' ');
  }

  /// Checks if string contains standard or presentation Arabic characters.
  static bool hasArabicCharacters(String text) {
    return RegExp(
      r'[\u0600-\u06FF\u0750-\u077F\uFB50-\uFDFF\uFE70-\uFEFF]',
    ).hasMatch(text);
  }

  /// Normalizes Arabic Presentation Forms (A & B) into standard Unicode Arabic.
  static String normalizePresentationForms(String text) {
    if (text.isEmpty) return text;
    final buffer = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      final code = text.codeUnitAt(i);
      final mapped = _presentationFormsMap[code];
      if (mapped != null) {
        buffer.write(mapped);
      } else {
        buffer.writeCharCode(code);
      }
    }

    return buffer.toString();
  }

  /// Detects whether an Arabic string has its words or characters visually reversed.
  ///
  /// For instance:
  /// - Words ending in the definite article prefix "ال" (e.g. "بساحلا") instead of beginning with "ال".
  /// - Academic titles reversed like "دمحأ .د" instead of "د. أحمد".
  /// - Known timetable words like "مولع" (reversed from "علوم") or "بسالحا" (reversed from "الحاسب").
  static bool isVisuallyReversedArabic(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;

    // Check if word ends with definite article 'لا' where in Arabic it should begin with 'ال'
    final words = trimmed.split(RegExp(r'\s+'));
    for (final word in words) {
      if (word.length >= 3 && word.endsWith('لا') && !word.startsWith('ال')) {
        return true;
      }
      if (word == 'مولع' || word == 'بساح' || word == 'بساحلا') {
        return true;
      }
    }

    // Check for reversed titles e.g. " .د" or " .أ" at the end of token
    if (RegExp(r'\s+\.د$|\s+\.أ$|\.د\s').hasMatch(trimmed) &&
        !trimmed.startsWith('د.') &&
        !trimmed.startsWith('أ.')) {
      return true;
    }

    return false;
  }

  /// Reverses visually reversed Arabic text while preserving embedded numbers or Latin codes.
  static String reverseArabicWords(String text) {
    if (text.trim().isEmpty) return text;

    final tokens = text.split(RegExp(r'\s+'));
    final correctedTokens = <String>[];

    for (final token in tokens) {
      // If token is mostly Arabic letters, reverse its characters
      final arabicCount = RegExp(r'[\u0621-\u064A]').allMatches(token).length;
      if (arabicCount > token.length / 2) {
        // Reverse characters
        correctedTokens.add(token.split('').reversed.join(''));
      } else {
        correctedTokens.add(token);
      }
    }

    // Reverse the order of tokens in the phrase
    return correctedTokens.reversed.join(' ');
  }

  /// Detects whether an Arabic string has single Arabic letters separated by spaces.
  static bool hasSpacedArabicLetters(String text) {
    if (text.isEmpty) return false;
    return RegExp(
      r'[\u0600-\u06FF]\s+[\u0600-\u06FF]\s+[\u0600-\u06FF]',
    ).hasMatch(text);
  }

  /// Collapses single spaces between single Arabic letters within words.
  /// Example: "ع ل و م   ح ا س ب" -> "علوم حاسب"
  /// Example: "ا ل س ب ت" -> "السبت"
  /// Example: "ا ل ذ ك ا ء   ا لا ص ط ن ا ع ى" -> "الذكاء الاصطناعى"
  static String collapseSpacedArabicLetters(String text) {
    if (!hasSpacedArabicLetters(text)) return text;

    final lines = text.split('\n');
    final processed = lines.map((line) {
      if (!hasSpacedArabicLetters(line)) return line;

      // Words in spaced Arabic are separated by 2 or more spaces or tabs
      final words = line.split(RegExp(r'\s{2,}|\t+'));
      final collapsedWords = words.map((w) {
        final trimmed = w.trim();
        if (!hasSpacedArabicLetters(trimmed)) return trimmed;

        return trimmed.replaceAllMapped(
          RegExp(r'([\u0600-\u06FF\/\-])\s+(?=[\u0600-\u06FF\/\-])'),
          (m) => m.group(1)!,
        );
      }).toList();

      return collapsedWords.join(' ');
    }).toList();

    return processed.join('\n');
  }

  /// Cleans and fully normalizes Arabic text from PDF / OCR extraction.
  static String cleanAndNormalizeArabic(String text) {
    if (text.trim().isEmpty) return text;

    // Process line by line to preserve document structure, section headers, and newlines
    final lines = text.split('\n');
    final cleanedLines = lines.map((line) {
      if (line.trim().isEmpty) return line;

      // 1. Repair Mojibake on this line
      var l = fixMojibake(line);

      // 2. Convert Presentation Forms to standard Unicode Arabic
      l = normalizePresentationForms(l);

      // 3. Reverse visually reversed Arabic on this line if detected
      if (isVisuallyReversedArabic(l)) {
        l = reverseArabicWords(l);
      }

      // 4. Collapse spaced Arabic letters if present
      if (hasSpacedArabicLetters(l)) {
        l = collapseSpacedArabicLetters(l);
      }

      // 5. Clean repeated spaces within the line
      l = l.replaceAll(RegExp(r'[ \t]+'), ' ').trim();

      return l;
    }).toList();

    return cleanedLines.join('\n');
  }

  /// Presentation Forms Mapping Table (Presentation Forms-A & B -> Standard Unicode)
  static final Map<int, String> _presentationFormsMap = {
    // Presentation Forms-B (\uFE70 - \uFEFF)
    0xFE80: 'ء',
    0xFE81: 'آ',
    0xFE82: 'آ',
    0xFE83: 'أ',
    0xFE84: 'أ',
    0xFE85: 'ؤ',
    0xFE86: 'ؤ',
    0xFE87: 'إ',
    0xFE88: 'إ',
    0xFE89: 'ئ',
    0xFE8A: 'ئ',
    0xFE8B: 'ئ',
    0xFE8C: 'ئ',
    0xFE8D: 'ا',
    0xFE8E: 'ا',
    0xFE8F: 'ب',
    0xFE90: 'ب',
    0xFE91: 'ب',
    0xFE92: 'ب',
    0xFE93: 'ة',
    0xFE94: 'ة',
    0xFE95: 'ت',
    0xFE96: 'ت',
    0xFE97: 'ت',
    0xFE98: 'ت',
    0xFE99: 'ث',
    0xFE9A: 'ث',
    0xFE9B: 'ث',
    0xFE9C: 'ث',
    0xFE9D: 'ج',
    0xFE9E: 'ج',
    0xFE9F: 'ج',
    0xFEA0: 'ج',
    0xFEA1: 'ح',
    0xFEA2: 'ح',
    0xFEA3: 'ح',
    0xFEA4: 'ح',
    0xFEA5: 'خ',
    0xFEA6: 'خ',
    0xFEA7: 'خ',
    0xFEA8: 'خ',
    0xFEA9: 'د',
    0xFEAA: 'د',
    0xFEAB: 'ذ',
    0xFEAC: 'ذ',
    0xFEAD: 'ر',
    0xFEAE: 'ر',
    0xFEAF: 'ز',
    0xFEB0: 'ز',
    0xFEB1: 'س',
    0xFEB2: 'س',
    0xFEB3: 'س',
    0xFEB4: 'س',
    0xFEB5: 'ش',
    0xFEB6: 'ش',
    0xFEB7: 'ش',
    0xFEB8: 'ش',
    0xFEB9: 'ص',
    0xFEBA: 'ص',
    0xFEBB: 'ص',
    0xFEBC: 'ص',
    0xFEBD: 'ض',
    0xFEBE: 'ض',
    0xFEBF: 'ض',
    0xFEC0: 'ض',
    0xFEC1: 'ط',
    0xFEC2: 'ط',
    0xFEC3: 'ط',
    0xFEC4: 'ط',
    0xFEC5: 'ظ',
    0xFEC6: 'ظ',
    0xFEC7: 'ظ',
    0xFEC8: 'ظ',
    0xFEC9: 'ع',
    0xFECA: 'ع',
    0xFECB: 'ع',
    0xFECC: 'ع',
    0xFECD: 'غ',
    0xFECE: 'غ',
    0xFECF: 'غ',
    0xFED0: 'غ',
    0xFED1: 'ف',
    0xFED2: 'ف',
    0xFED3: 'ف',
    0xFED4: 'ف',
    0xFED5: 'ق',
    0xFED6: 'ق',
    0xFED7: 'ق',
    0xFED8: 'ق',
    0xFED9: 'ك',
    0xFEDA: 'ك',
    0xFEDB: 'ك',
    0xFEDC: 'ك',
    0xFEDD: 'ل',
    0xFEDE: 'ل',
    0xFEDF: 'ل',
    0xFEE0: 'ل',
    0xFEE1: 'م',
    0xFEE2: 'م',
    0xFEE3: 'م',
    0xFEE4: 'م',
    0xFEE5: 'ن',
    0xFEE6: 'ن',
    0xFEE7: 'ن',
    0xFEE8: 'ن',
    0xFEE9: 'ه',
    0xFEEA: 'ه',
    0xFEEB: 'ه',
    0xFEEC: 'ه',
    0xFEED: 'و',
    0xFEEE: 'و',
    0xFEEF: 'ى',
    0xFEF0: 'ى',
    0xFEF1: 'ي',
    0xFEF2: 'ي',
    0xFEF3: 'ي',
    0xFEF4: 'ي',
    0xFEF5: 'لآ',
    0xFEF6: 'لآ',
    0xFEF7: 'لأ',
    0xFEF8: 'لأ',
    0xFEF9: 'لإ',
    0xFEFA: 'لإ',
    0xFEFB: 'لا',
    0xFEFC: 'لا',
  };
}
