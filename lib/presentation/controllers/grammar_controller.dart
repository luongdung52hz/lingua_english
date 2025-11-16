// controllers/grammar_controller.dart
import 'package:get/get.dart';
import '../../data/models/grammar_model.dart';
import 'dart:convert';
import 'package:flutter/services.dart'; // Để load assets

class GrammarController extends GetxController {
  final RxList<GrammarTopic> topics = <GrammarTopic>[].obs;
  final RxString currentTopicId = ''.obs;
  final RxString currentSubTopicId = ''.obs;
  final RxMap<String, bool> completedSections = <String, bool>{}.obs; // Lưu progress

  @override
  void onInit() {
    super.onInit();
    loadGrammarData();
  }

  void loadGrammarData() async {
    try {
      // Load từ assets (cần context, nên dùng trong build hoặc Get.context!)
      final jsonString = await rootBundle.loadString('lib/resources/assets/grammar.json'); // Import flutter/services.dart
      final List<dynamic> jsonList = json.decode(jsonString);

      // ✅ FIX: Ép kiểu explicit với List<GrammarTopic>.from() và map
      topics.value = List<GrammarTopic>.from(
          jsonList.map((dynamic json) => GrammarTopic.fromJson(json as Map<String, dynamic>))
      );
    } catch (e) {
      print('Lỗi load grammar data: $e'); // Debug
      // Fallback: topics.value = []; hoặc load mẫu
    }
  }

  void selectTopic(String topicId) {
    currentTopicId.value = topicId;
  }

  void selectSubTopic(String subTopicId) {
    currentSubTopicId.value = subTopicId;
  }

  void markSectionCompleted(String sectionKey) {
    completedSections[sectionKey] = true;
    // Lưu vào SharedPreferences nếu cần
  }

  GrammarTopic? getCurrentTopic() => topics.firstWhereOrNull((t) => t.id == currentTopicId.value);
  GrammarSubTopic? getCurrentSubTopic() {
    final topic = getCurrentTopic();
    return topic?.subTopics.firstWhereOrNull((s) => s.id == currentSubTopicId.value);
  }
}