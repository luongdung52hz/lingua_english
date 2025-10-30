import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';

import '../../controllers/pdf_controller.dart';

class PdfUploadPage extends StatefulWidget {
  const PdfUploadPage({super.key});

  @override
  State<PdfUploadPage> createState() => _PdfUploadPageState();
}

class _PdfUploadPageState extends State<PdfUploadPage> {
  final PdfController controller = Get.put(PdfController());
  File? selectedFile;

  // Trong PdfUploadPage.dart, sửa _pickPdfFile()
  Future<void> _pickPdfFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        final path = result.files.first.path ?? '';  // Fallback empty string thay vì null
        if (path.isNotEmpty) {
          setState(() {
            selectedFile = File(path);
          });
        } else {
          Get.snackbar('Lỗi', 'Đường dẫn file không hợp lệ');
        }
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể chọn file: $e');
    }
  }

  Future<void> _createQuiz() async {
    if (selectedFile == null) {
      Get.snackbar('Thông báo', 'Vui lòng chọn file PDF trước');
      return;
    }

    await controller.processPdfFile(selectedFile!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📚 Tạo Quiz từ PDF'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInstructionCard(),
            const SizedBox(height: 20),
            _buildFileSelector(),
            const SizedBox(height: 20),
            Obx(() => _buildProcessingStatus()),
            const SizedBox(height: 20),
            Obx(() => _buildActionButtons()),
            const SizedBox(height: 20),
            Obx(() => _buildQuestionsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Hướng dẫn',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildBulletPoint('Chọn file PDF chứa câu hỏi trắc nghiệm'),
            _buildBulletPoint('Định dạng hỗ trợ: Câu 1:, A., B., C., D.'),
            _buildBulletPoint('Đánh dấu * trước đáp án đúng (ví dụ: *B.)'),
            _buildBulletPoint('AI sẽ tự động bổ sung đáp án nếu thiếu'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.amber.shade700, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Ví dụ: "Câu 1: Java là gì? A. Ngôn ngữ lập trình *B. Cà phê C. Hệ điều hành"',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildFileSelector() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              selectedFile != null ? Icons.picture_as_pdf : Icons.upload_file,
              size: 64,
              color: selectedFile != null ? Colors.red : Colors.grey,
            ),
            const SizedBox(height: 16),
            if (selectedFile != null) ...[
              Text(
                selectedFile!.path.split('/').last,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '${(selectedFile!.lengthSync() / 1024).toStringAsFixed(1)} KB',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              const Text(
                'Chưa chọn file PDF',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton.icon(
              onPressed: controller.isProcessing.value ? null : _pickPdfFile,
              icon: const Icon(Icons.folder_open),
              label: Text(selectedFile != null ? 'Chọn file khác' : 'Chọn file PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingStatus() {
    if (!controller.isProcessing.value && controller.processingStage.value.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    controller.processingStage.value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: controller.progress.value,
                minHeight: 8,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade600),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(controller.progress.value * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (selectedFile != null && !controller.isProcessing.value)
                ? _createQuiz
                : null,
            icon: controller.isProcessing.value
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Icon(Icons.auto_awesome),
            label: Text(
              controller.isProcessing.value
                  ? 'Đang xử lý...'
                  : '🚀 Tạo Quiz từ PDF',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        if (controller.parsedQuestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: controller.isProcessing.value
                  ? null
                  : () {
                setState(() {
                  selectedFile = null;
                });
                controller.clear();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Tạo quiz mới'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuestionsList() {
    if (controller.parsedQuestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '📝 Câu hỏi đã phân tích',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${controller.parsedQuestions.length} câu',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...controller.parsedQuestions.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;
              return _buildQuestionCard(index, question);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int index, question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: question.isComplete ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: question.isComplete ? Colors.green.shade300 : Colors.orange.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: question.isComplete ? Colors.green : Colors.orange,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question.question,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                question.isComplete ? Icons.check_circle : Icons.pending,
                color: question.isComplete ? Colors.green : Colors.orange,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...question.options.asMap().entries.map((e) {
            final isCorrect = e.value == question.correctAnswer;
            return Padding(
              padding: const EdgeInsets.only(left: 32, top: 4),
              child: Row(
                children: [
                  Icon(
                    isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 16,
                    color: isCorrect ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e.value,
                      style: TextStyle(
                        fontSize: 13,
                        color: isCorrect ? Colors.green.shade700 : Colors.black87,
                        fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}