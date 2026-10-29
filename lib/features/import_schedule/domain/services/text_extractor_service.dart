abstract class TextExtractorService {
  Future<String> extractTextFromImage(String imagePath);
  Future<String> extractTextFromPdf(String pdfPath);
}
