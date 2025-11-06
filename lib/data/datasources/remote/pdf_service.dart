import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PDFService {
  /// 🔹 Tách text cơ bản (giữ layout)
  Future<String> extractText(File file) async {
    try {
      final PdfDocument document = PdfDocument(
        inputBytes: await file.readAsBytes(),
      );

      final PdfTextExtractor extractor = PdfTextExtractor(document);
      final List<TextLine> lines = extractor.extractTextLines();

      final buffer = StringBuffer();
      for (final line in lines) {
        buffer.writeln(line.text.trim());
      }

      document.dispose();
      return _normalizeText(buffer.toString());
    } catch (e) {
      throw Exception('❌ Lỗi đọc file PDF: $e');
    }
  }

  /// 🔹 Tách text tối ưu cho AI (giữ layout, remove ký tự thừa)
  Future<String> extractTextForAI(File file) async {
    try {
      final rawText = await extractText(file);

      // Chuẩn hóa text: xóa ký tự đặc biệt, nhiều line break, "Phần A/B"
      final aiReadyText = rawText
          .replaceAll(RegExp(r'Phần\s+[A-Z]+', caseSensitive: false), '')
          .replaceAll(RegExp(r'\n{2,}'), '\n')
          .trim();

      return aiReadyText;
    } catch (e) {
      throw Exception('❌ Lỗi chuẩn hóa text cho AI: $e');
    }
  }

  /// 🔹 Lấy metadata PDF
  Future<PdfMetadata> getMetadata(File file) async {
    try {
      final PdfDocument document = PdfDocument(
        inputBytes: await file.readAsBytes(),
      );

      final metadata = PdfMetadata(
        pageCount: document.pages.count,
        fileName: file.path.split('/').last,
        fileSize: await file.length(),
      );

      document.dispose();
      return metadata;
    } catch (e) {
      throw Exception('❌ Lỗi đọc metadata PDF: $e');
    }
  }

  /// 🔧 Chuẩn hóa text cơ bản
  String _normalizeText(String text) {
    return text
        .replaceAll('\u0000', '')
        .replaceAll('\ufeff', '')
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join('\n')
        .trim();
  }
}

class PdfMetadata {
  final int pageCount;
  final String fileName;
  final int fileSize;

  PdfMetadata({
    required this.pageCount,
    required this.fileName,
    required this.fileSize,
  });

  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
