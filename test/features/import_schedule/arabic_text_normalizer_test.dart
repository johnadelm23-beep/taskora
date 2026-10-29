import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskora/features/import_schedule/domain/services/arabic_text_normalizer.dart';

void main() {
  group('ArabicTextNormalizer', () {
    test('repairs UTF-8 Mojibake for Arabic course name', () {
      const original = 'علوم الحاسب';
      // Simulate mojibake: UTF-8 decoded as Latin-1
      final mojibake = latin1.decode(utf8.encode(original));
      expect(ArabicTextNormalizer.isUtf8Mojibake(mojibake), isTrue);

      final repaired = ArabicTextNormalizer.cleanAndNormalizeArabic(mojibake);
      expect(repaired, 'علوم الحاسب');
    });

    test('normalizes Arabic Presentation Forms-B into standard Arabic', () {
      // Presentation forms for "علوم"
      // \uFECB = ع (initial), \uFEE0 = ل (medial), \uFEED = و (final), \uFEE1 = م (isolated)
      const presentationForms = '\uFECB\uFEE0\uFEED\uFEE1';
      final normalized = ArabicTextNormalizer.cleanAndNormalizeArabic(
        presentationForms,
      );
      expect(normalized, 'علوم');
    });

    test('restores visually reversed Arabic words', () {
      // Visually reversed letters in tokens and reversed word order:
      // "بساحلا" is "الحاسب" reversed, "مولع" is "علوم" reversed.
      const reversed = 'بساحلا مولع';
      expect(ArabicTextNormalizer.isVisuallyReversedArabic(reversed), isTrue);

      final restored = ArabicTextNormalizer.cleanAndNormalizeArabic(reversed);
      expect(restored, 'علوم الحاسب');
    });

    test(
      'handles mixed Arabic and English text without corrupting English',
      () {
        const mixed = 'CS101 علوم الحاسب Dr. Ahmed';
        final cleaned = ArabicTextNormalizer.cleanAndNormalizeArabic(mixed);
        expect(cleaned, 'CS101 علوم الحاسب Dr. Ahmed');
      },
    );

    test('collapses spaced Arabic letters into proper words', () {
      const spaced = 'ع ل و م   ح ا س ب';
      expect(ArabicTextNormalizer.hasSpacedArabicLetters(spaced), isTrue);
      final cleaned = ArabicTextNormalizer.cleanAndNormalizeArabic(spaced);
      expect(cleaned, 'علوم حاسب');

      const spacedDay = 'ا ل س ب ت';
      expect(ArabicTextNormalizer.cleanAndNormalizeArabic(spacedDay), 'السبت');

      const spacedAi = 'ا ل ذ ك ا ء   ا لا ص ط ن ا ع ى';
      expect(
        ArabicTextNormalizer.cleanAndNormalizeArabic(spacedAi),
        'الذكاء الاصطناعى',
      );
    });

    test('leaves already correct Arabic untouched', () {
      const correct = 'برمجة النظم والأجهزة الذكية';
      final cleaned = ArabicTextNormalizer.cleanAndNormalizeArabic(correct);
      expect(cleaned, correct);
    });
  });
}
