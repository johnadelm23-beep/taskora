# Taskora (تاسكورا)

Taskora is an offline-first academic schedule and task management Flutter application built specifically for university students (optimized for Egyptian university timetables, including Benha University formats). It empowers students to import their academic timetables seamlessly from images (English, Arabic, and bilingual), selectable-text PDFs, scanned/image-only PDFs, or CSV files into a structured, editable schedule with automatic lecture reminder notifications.

---

## Key Features

- **Multi-Format Timetable Import**:
  - **Images**: Arabic, English, and bilingual timetables recognized via an offline Hybrid OCR engine (`FlutterTesseractOcr` + Google ML Kit).
  - **Selectable PDFs**: High-speed vector text extraction via Syncfusion PDF.
  - **Scanned / Image-Only PDFs**: Automatic detection and rasterization fallback via `pdfx` (rendering pages to high-DPI bitmaps for on-device OCR).
  - **CSV Files**: Standardized comma/semicolon/tab-separated timetable parsing.
- **Robust Arabic & English Text Normalization**:
  - Full Arabic diacritics (tashkeel `\u064B..\u065F`) and tatweel/kashida (`ـ`) stripping for consistent OCR matching.
  - Eastern Arabic numeral conversion (٠-٩ → 0-9).
  - Bilingual day of week mapping (السبت - الجمعة, Saturday - Friday).
  - Normalization of common OCR misrecognitions and varied course-type keywords (محاضرة, سكشن, تمرين, معمل, Lab, Lecture, Tutorial).
- **Import Review & Conflict Detection**:
  - Unified `CanonicalTimetableEntry` representation.
  - In-memory time-overlap conflict detection and duplicate detection.
  - Interactive candidate editing and manual entry creation before committing to the database.
- **Offline-First Persistence**:
  - Relational SQLite storage powered by **Drift**.
  - Immediate local availability without network dependencies.
- **Smart Reminders**:
  - Automatic lecture reminders scheduled via `flutter_local_notifications`.
- **Modern UI & Theming**:
  - Dark and light themes using Taskora's signature Black, Orange, and White palette.
  - Responsive layout scaling with `flutter_screenutil`.
  - Full RTL (Right-to-Left) and LTR bilingual support.

---

## Timetable Import Pipeline

```
  [ Timetable Source ]
  (Image / Selectable PDF / Scanned PDF / CSV)
           │
           ▼
  ┌─────────────────────────────────────────────────────────┐
  │              Input Ingestion & Detection                │
  └──────────────────────────┬──────────────────────────────┘
                             │
            ┌────────────────┴────────────────┐
            ▼                                 ▼
   [ PDF Document ]                   [ Image File ]
            │                                 │
     (Syncfusion PDF)                         │
     Try vector text                          │
            │                                 │
     Is Scanned / Empty?                      │
     ├── No  ─► [ Vector Text ]               │
     └── Yes ─► Render Pages (pdfx)           │
                     │                        │
                     └──────────┬─────────────┘
                                │
                                ▼
  ┌─────────────────────────────────────────────────────────┐
  │                 Hybrid OCR Engine                       │
  │  - Primary: Tesseract (ara + eng offline traineddata)   │
  │  - Secondary / Failover: Google ML Kit (Latin fallback) │
  └──────────────────────────┬──────────────────────────────┘
                             │
                             ▼
  ┌─────────────────────────────────────────────────────────┐
  │            Arabic & Latin Normalization                 │
  │  - Tashkeel & Tatweel stripping                         │
  │  - Eastern Arabic numeral normalization                 │
  │  - Day/time regex pattern standardization               │
  └──────────────────────────┬──────────────────────────────┘
                             │
                             ▼
  ┌─────────────────────────────────────────────────────────┐
  │                  Timetable Parser                       │
  │  - CanonicalTimetableEntry generation                   │
  └──────────────────────────┬──────────────────────────────┘
                             │
                             ▼
  ┌─────────────────────────────────────────────────────────┐
  │               Validation & Conflict Check               │
  │  - Time overlap detection                               │
  │  - Duplicate entry identification                       │
  └──────────────────────────┬──────────────────────────────┘
                             │
                             ▼
  ┌─────────────────────────────────────────────────────────┐
  │               Interactive Review Screen                 │
  │  - User candidate adjustment / additions                │
  └──────────────────────────┬──────────────────────────────┘
                             │
                             ▼
  ┌─────────────────────────────────────────────────────────┐
  │            Drift Local SQLite Database                  │
  │         + Local Notification Reminders                  │
  └─────────────────────────────────────────────────────────┘
```

---

## Technology Stack

| Category | Technology |
|---|---|
| **Framework** | Flutter (Channel stable, 3.44.8) / Dart (3.12.2) |
| **State Management** | `flutter_bloc` / Cubit |
| **Dependency Injection** | `get_it` service locator |
| **Database** | `drift` (SQLite) + `sqlite3_flutter_libs` + `path_provider` |
| **OCR & Document Processing**| `flutter_tesseract_ocr` (ara + eng), `google_mlkit_text_recognition`, `pdfx`, `syncfusion_flutter_pdf` |
| **Notifications** | `flutter_local_notifications`, `timezone` |
| **UI & Styling** | `flutter_screenutil`, `google_fonts`, Material 3 |
| **Data Parsing** | `csv`, Custom Regex Parsers |

---

## Getting Started

### Prerequisites

- Flutter SDK `^3.44.8` or compatible 3.x
- Dart SDK `^3.12.2`
- Android Studio / Xcode for device deployment

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/taskora.git
   cd taskora
   ```

2. **Install Flutter dependencies**:
   ```bash
   flutter pub get
   ```

3. **Verify OCR Trained Data**:
   Ensure `assets/tessdata/ara.traineddata` and `assets/tessdata/eng.traineddata` are present (registered in `pubspec.yaml` and `assets/tessdata_config.json`).

4. **Run Drift Code Generation** (if updating tables):
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

5. **Run the App**:
   ```bash
   flutter run
   ```

---

## Testing

Run the automated test suite across all modules:

```bash
flutter test
```

Run Phase 1 OCR and scanned PDF fallback tests specifically:

```bash
flutter test test/features/import_schedule/arabic_ocr_test.dart
flutter test test/features/import_schedule/scanned_pdf_fallback_test.dart
flutter test test/features/import_schedule/arabic_text_normalizer_test.dart
```

---

## License

This project is licensed under the MIT License - see the LICENSE file for details.
