import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PDFService {
  /// 🔹 Tách text với layout recognition (giữ nguyên cấu trúc)
  Future<String> extractText(File file) async {
    try {
      final PdfDocument document = PdfDocument(
        inputBytes: await file.readAsBytes(),
      );

      final PdfTextExtractor extractor = PdfTextExtractor(document);

      // ✅ Sử dụng extractTextLines() thay vì extractText()
      final List<TextLine> lines = extractor.extractTextLines();

      // Gộp các dòng thành văn bản hoàn chỉnh
      final StringBuffer buffer = StringBuffer();
      for (final line in lines) {
        buffer.writeln(line.text.trim());
      }

      document.dispose();
      return _normalizeText(buffer.toString());
    } catch (e) {
      throw Exception('❌ Lỗi đọc file PDF: $e');
    }
  }

  /// 🔹 Tách text theo layout với thông tin vị trí
  Future<String> extractTextWithLayout(File file) async {
    try {
      final PdfDocument document = PdfDocument(
        inputBytes: await file.readAsBytes(),
      );

      final StringBuffer buffer = StringBuffer();

      for (int i = 0; i < document.pages.count; i++) {
        final PdfPage page = document.pages[i];

        // ✅ Extract với layout mode
        final String pageText = PdfTextExtractor(document).extractText(
          startPageIndex: i,
          endPageIndex: i,
          layoutText: true, // 🔑 Quan trọng: giữ nguyên layout
        );

        buffer.writeln(pageText);
      }

      document.dispose();
      return _normalizeText(buffer.toString());
    } catch (e) {
      throw Exception('❌ Lỗi đọc file PDF: $e');
    }
  }

  /// 🧹 Chuẩn hóa văn bản
  String _normalizeText(String text) {
    return text
    // Xóa ký tự đặc biệt
        .replaceAll('\u0000', '')
        .replaceAll('\ufeff', '') // BOM
    // Chuẩn hóa line breaks
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
    // Xóa nhiều xuống dòng liên tiếp
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
    // Xóa space thừa trong dòng
       // .replaceAll(RegExp(r'[ \t]+'), ' ')
    // Trim từng dòng
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join('\n')
        .trim();
  }
}
  /// 🔹 Lấy thông tin metadata của file PDF
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
