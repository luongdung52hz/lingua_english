import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';  // Để load assets
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import '../demo/lesson_demo_data.dart';  // Import class của bạn

class AudioUploader extends StatefulWidget {
  @override
  _AudioUploaderState createState() => _AudioUploaderState();
}

class _AudioUploaderState extends State<AudioUploader> {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  List<String> _uploadedUrls = [];  // Lưu URL sau upload
  bool _isUploading = false;

  // Map từ lesson ID sang file name (tùy chỉnh theo naming convention của bạn)
  Map<String, String> get _lessonToFileMap => {
    'a1_listen_greet_01': 'test1.mp3',
    'a1_listen_greet_02': 'test2.mp3',
    'a1_listen_greet_03': 'test2.mp3',
    'a1_listen_family_01': 'test4.mp3',
    'a1_listen_family_02': 'siblings.mp3',
    'a1_listen_daily_01': 'morning.mp3',
    'a1_speak_family_01': 'family_speak.mp3',  // Ví dụ cho speaking
    // Thêm các ID khác tương ứng với file MP3 của bạn
    // Ví dụ: 'a2_listen_shop_01': 'shopping.mp3',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload Audio Batch')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _isUploading ? null : _uploadAllAudios,
            child: Text(_isUploading ? 'Uploading...' : 'Upload All MP3s'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _uploadedUrls.length,
              itemBuilder: (context, index) {
                final entry = _uploadedUrls[index].split('|');
                return ListTile(
                  title: Text('Lesson: ${entry[0]}'),
                  subtitle: Text('URL: ${entry[1]}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadAllAudios() async {
    setState(() => _isUploading = true);
    _uploadedUrls.clear();

    for (final lesson in LessonDemoData.getAllLessons()) {
      if (lesson.content.containsKey('audioUrl') && _lessonToFileMap.containsKey(lesson.id)) {
        final fileName = _lessonToFileMap[lesson.id]!;
        final url = await _uploadSingleFile(fileName, lesson.id);
        if (url != null) {
          _uploadedUrls.add('${lesson.id}|$url');
          print('Uploaded ${lesson.id}: $url');  // Copy từ console
        }
      }
    }

    setState(() => _isUploading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Upload hoàn thành! Check console để copy URL.')),
    );
  }

  Future<String?> _uploadSingleFile(String fileName, String lessonId) async {
    try {
      // Load file từ assets thành bytes
      final ByteData data = await rootBundle.load('lib/resources/assets/audios/$fileName');
      final Uint8List bytes = data.buffer.asUint8List();

      // Tạo file tạm để upload (Firebase cần File hoặc bytes)
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(bytes);

      // Upload
      final storageRef = _storage.ref().child('audios/$lessonId.mp3');  // Tên file = lessonId.mp3 để dễ quản lý
      final uploadTask = storageRef.putFile(tempFile);

      // Theo dõi progress (tùy chọn)
      uploadTask.snapshotEvents.listen((snapshot) {
        print('Progress for $lessonId: ${(snapshot.bytesTransferred / snapshot.totalBytes) * 100}%');
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Xóa file tạm
      await tempFile.delete();

      return downloadUrl;
    } catch (e) {
      print('Lỗi upload $fileName: $e');
      return null;
    }
  }
}