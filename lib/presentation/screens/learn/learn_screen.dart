import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:learn_english/presentation/screens/learn/widgets/learn_screen/lesson_list.dart';
import 'package:learn_english/presentation/screens/learn/widgets/learn_screen/skill_filter_bar.dart';
import 'package:learn_english/presentation/screens/learn/widgets/learn_screen/skill_summary_card.dart';
import 'package:learn_english/presentation/screens/learn/widgets/learn_screen/topic_filter_bar.dart';
import '../../../util/skill_untils.dart';
import '../../controllers/lesson_controller.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../../app/routes/route_names.dart';
import '../../../resources/styles/colors.dart';


class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen>
    with TickerProviderStateMixin {
  late TabController _levelController;
  late final LearnController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(LearnController());
    _levelController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _levelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 140,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: AppColors.primary,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.school_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Học Tập',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Chọn cấp độ và kỹ năng',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // IconButton(
                              //   onPressed: () {
                              //
                              //   },
                              //   icon: const Icon(
                              //     Icons.insights_rounded,
                              //     color: Colors.white,
                              //   ),
                              // ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(10),
                child: Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _levelController,

                    onTap: (index) {
                      final level = controller.levels[index];
                      controller.changeLevel(level);
                    },
                    isScrollable: false,
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 3,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: Colors.grey,
                    labelStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                    tabs: const [
                      Tab(text: 'A1'),
                      Tab(text: 'A2'),
                      Tab(text: 'B1'),
                      Tab(text: 'B2'),
                      Tab(text: 'C1'),
                      Tab(text: 'C2'),

                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            SkillFilterBar(controller: controller),
            Expanded(
              child: Obx(() => _buildSkillView(controller.currentSkill.value)),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildSkillView(String skill) {
    final skillColor = SkillUtils.getSkillColor(skill);
    final skillIcon = SkillUtils.getSkillIcon(skill);

    return Column(
      children: [
        SkillSummaryCard(
          skill: skill,
          skillColor: skillColor,
          skillIcon: skillIcon,
          totalLessons: controller.totalLessons.value,
          completedLessons: controller.completedLessons.value,
        ),
        TopicFilterBar(
          controller: controller,
          skillColor: skillColor,
          skill: skill,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LessonList(
            controller: controller,
            onLessonTap: (lesson) {
              controller.startLesson(lesson);
              context.go('/learn/detail/${lesson.id}');
            },
          ),
        ),
      ],
    );
  }
}