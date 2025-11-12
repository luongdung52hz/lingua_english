import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/lesson_model.dart';
import '../../../app/routes/route_names.dart';
import '../../controllers/admin_controller.dart';
import '../../../resources/styles/colors.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late final AdminController controller;
  late final TabController _tabController;

  String _searchQuery = '';
  String? _selectedLevel;
  String? _selectedSkill;

  final List<String> _levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
  final List<String> _skills = ['listening', 'speaking', 'reading', 'writing'];

  @override
  void initState() {
    super.initState();
    controller = AdminController();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    controller.dispose();
    super.dispose();
  }

  List<LessonModel> _filterLessons(List<LessonModel> lessons) {
    return lessons.where((lesson) {
      // Search filter
      final matchesSearch = _searchQuery.isEmpty ||
          lesson.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          lesson.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          lesson.topic.toLowerCase().contains(_searchQuery.toLowerCase());

      // Level filter
      final matchesLevel = _selectedLevel == null || lesson.level == _selectedLevel;

      // Skill filter
      final matchesSkill = _selectedSkill == null || lesson.skill == _selectedSkill;

      return matchesSearch && matchesLevel && matchesSkill;
    }).toList();
  }

  Map<String, List<LessonModel>> _groupByLevel(List<LessonModel> lessons) {
    final Map<String, List<LessonModel>> grouped = {};
    for (var level in _levels) {
      grouped[level] = lessons.where((l) => l.level == level).toList();
    }
    return grouped;
  }

  Map<String, List<LessonModel>> _groupBySkill(List<LessonModel> lessons) {
    final Map<String, List<LessonModel>> grouped = {};
    for (var skill in _skills) {
      grouped[skill] = lessons.where((l) => l.skill == skill).toList();
    }
    return grouped;
  }

  Map<String, List<LessonModel>> _groupByTopic(List<LessonModel> lessons) {
    final Map<String, List<LessonModel>> grouped = {};

    // Nhóm các bài học có cùng topic
    for (var lesson in lessons) {
      final topic = lesson.topic.isEmpty ? 'Chưa có topic' : lesson.topic;
      if (!grouped.containsKey(topic)) {
        grouped[topic] = [];
      }
      grouped[topic]!.add(lesson);
    }

    // Sắp xếp theo tên topic
    final sortedKeys = grouped.keys.toList()..sort();
    final sortedGrouped = <String, List<LessonModel>>{};
    for (var key in sortedKeys) {
      sortedGrouped[key] = grouped[key]!;
    }

    return sortedGrouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quản Lý Bài Học',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => controller.logout(context),
          tooltip: 'Đăng xuất',
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: Colors.white,
            ),
            onSelected: (value) {
              if (value == 'pdf') {
                context.go(Routes.pdf);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, size: 20, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Chuyển đổi dữ liệu'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorWeight: 1,
          labelStyle: const TextStyle(fontSize: 12),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: false,
          tabs: const [
            Tab(icon: Icon(Icons.list, size: 30), text: 'Tất cả'),
            Tab(icon: Icon(Icons.layers), text: 'Level'),
            Tab(icon: Icon(Icons.category), text: 'Skill'),
            Tab(icon: Icon(Icons.topic), text: 'Topic'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: controller.lessonsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allLessons = snapshot.data!.docs
                    .map((doc) => LessonModel.fromJson(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
                    .toList();

                final filteredLessons = _filterLessons(allLessons);

                if (filteredLessons.isEmpty) {
                  return _buildEmptyState();
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAllLessonsTab(filteredLessons),
                    _buildLevelGroupedTab(filteredLessons),
                    _buildSkillGroupedTab(filteredLessons),
                    _buildTopicGroupedTab(filteredLessons),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => controller.showAddDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Thêm bài học'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm bài học...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() => _searchQuery = '');
                },
              )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
          const SizedBox(height: 12),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('Lọc: ', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Level',
                  value: _selectedLevel,
                  options: _levels,
                  onSelected: (value) {
                    setState(() => _selectedLevel = value);
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Skill',
                  value: _selectedSkill,
                  options: _skills.map((e) => e.toUpperCase()).toList(),
                  onSelected: (value) {
                    setState(() => _selectedSkill = value?.toLowerCase());
                  },
                ),
                const SizedBox(width: 8),
                if (_selectedLevel != null || _selectedSkill != null)
                  ActionChip(
                    label: const Text('Xóa bộ lọc'),
                    avatar: const Icon(Icons.clear, size: 16),
                    onPressed: () {
                      setState(() {
                        _selectedLevel = null;
                        _selectedSkill = null;
                      });
                    },
                    backgroundColor: Colors.red[50],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String? value,
    required List<String> options,
    required Function(String?) onSelected,
  }) {
    return PopupMenuButton<String>(
      child: Chip(
        label: Text(value ?? label),
        avatar: Icon(
          value != null ? Icons.check_circle : Icons.filter_list,
          size: 16,
        ),
        backgroundColor: value != null ? Colors.blue[100] : Colors.grey[200],
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: null,
          child: Text('Tất cả $label'),
        ),
        ...options.map((option) => PopupMenuItem(
          value: option,
          child: Text(option),
        )),
      ],
      onSelected: onSelected,
    );
  }

  Widget _buildAllLessonsTab(List<LessonModel> lessons) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lessons.length,
      itemBuilder: (context, index) => _buildLessonCard(lessons[index]),
    );
  }

  Widget _buildLevelGroupedTab(List<LessonModel> lessons) {
    final grouped = _groupByLevel(lessons);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _levels.length,
      itemBuilder: (context, index) {
        final level = _levels[index];
        final levelLessons = grouped[level] ?? [];

        if (levelLessons.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$level (${levelLessons.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...levelLessons.map((lesson) => _buildLessonCard(lesson)),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildSkillGroupedTab(List<LessonModel> lessons) {
    final grouped = _groupBySkill(lessons);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _skills.length,
      itemBuilder: (context, index) {
        final skill = _skills[index];
        final skillLessons = grouped[skill] ?? [];

        if (skillLessons.isEmpty) return const SizedBox.shrink();

        final skillIcons = {
          'listening': Icons.headphones,
          'speaking': Icons.mic,
          'reading': Icons.book,
          'writing': Icons.edit,
        };

        final skillColors = {
          'listening': Colors.blue,
          'speaking': Colors.orange,
          'reading': Colors.green,
          'writing': Colors.purple,
        };

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: skillColors[skill],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(skillIcons[skill], color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '${skill.toUpperCase()} (${skillLessons.length})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ...skillLessons.map((lesson) => _buildLessonCard(lesson)),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildTopicGroupedTab(List<LessonModel> lessons) {
    final grouped = _groupByTopic(lessons);
    final topics = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: topics.length,
      itemBuilder: (context, index) {
        final topic = topics[index];
        final topicLessons = grouped[topic] ?? [];

        if (topicLessons.isEmpty) return const SizedBox.shrink();

        return ExpansionTile(
          initiallyExpanded: false,
          leading: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.topic, color: Colors.white, size: 20),
          ),
          title: Text(
            '$topic (${topicLessons.length})',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: const Text('Nhấn để xem chi tiết', style: TextStyle(fontSize: 12, color: Colors.grey)),
          childrenPadding: const EdgeInsets.only(left: 16, bottom: 16),
          children: [
            ...topicLessons.map((lesson) => _buildLessonCard(lesson)),
          ],
          onExpansionChanged: (expanded) {
            if (expanded) {
              print('Expanded topic: $topic');
            }
          },
        );
      },
    );
  }

  Widget _buildLessonCard(LessonModel lesson) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        title: Text(
          lesson.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (lesson.description.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                lesson.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 4),
            ],
            Wrap(
              spacing: 1,
              runSpacing: 0,
              children: [
                Chip(
                  label: Text(lesson.level, style: const TextStyle(fontSize: 10)),
                  backgroundColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                ),
                Chip(
                  label: Text(lesson.skill.toUpperCase(), style: const TextStyle(fontSize: 10)),
                  backgroundColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                ),
                if (lesson.topic.isNotEmpty)
                  Chip(
                    label: Text(lesson.topic, style: const TextStyle(fontSize: 10)),
                    backgroundColor: Colors.transparent,
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue[400], size: 28),
              onPressed: () => controller.showEditDialog(context, lesson),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red[400], size: 28),
              onPressed: () => controller.deleteLesson(context, lesson.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy bài học',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Thử tìm kiếm hoặc lọc khác',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Lỗi load bài học',
            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}