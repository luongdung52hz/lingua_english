import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/custom_appbar.dart';
import '../../../resources/styles/colors.dart';
import 'components/skill_card.dart';
import 'package:go_router/go_router.dart';
import '../../../app/routes/route_names.dart';
import '../../controllers/home_controller.dart';
import 'components/continue_study.dart';
import 'components/appbar_home.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late HomeController homeCtrl;
  final firestore = GetIt.I<FirebaseFirestore>();

  @override
  void initState() {
    super.initState();
    homeCtrl = Get.put(HomeController());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Tự động reload mỗi khi quay lại trang
    homeCtrl.loadUserProgress();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarHome(),
      body: RefreshIndicator(
        onRefresh: () async {
          await homeCtrl.loadUserProgress();
        },
        child: StreamBuilder<DocumentSnapshot>(
          stream: firestore.collection('users').doc(homeCtrl.userId).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Lỗi load data: Kiểm tra kết nối'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // Parse data từ snapshot
            final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
            final progressPercent = (data['progress'] ?? 0).toDouble();
            final completedLessons = data['completedLessons'] ?? 0;
            final totalLessons = data['totalLessons'] ?? 5;
            final score = data['score'] ?? 0;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    "Chào mừng bạn trở lại",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ContinueStudyWidget(
                    onContinueTap: () {
                      context.go(Routes.learn);
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Tính năng nhanh",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 240,
                    child: GridView.count(
                      crossAxisCount: 3,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      children: [
                        SkillCard(
                          title: "Flashcard",
                          icon: Icons.style_outlined,
                          color: Colors.orange,
                          onTap: () {
                            context.go(Routes.flashcards);
                          },
                        ),
                        SkillCard(
                          title: "AI",
                          icon: Icons.mic,
                          color: Colors.redAccent,
                          onTap: () {
                            context.go(Routes.profile);
                          },
                        ),
                        SkillCard(
                          title: "4 Skill",
                          icon: Icons.menu_book,
                          color: Colors.blueAccent,
                          onTap: () {
                            context.go(Routes.learn);
                          },
                        ),
                        SkillCard(
                          title: "Friend",
                          icon: Icons.chat,
                          color: Colors.greenAccent,
                          onTap: () {
                            context.go(Routes.chat);
                          },
                        ),
                        SkillCard(
                          title: "Ngữ pháp",
                          icon: Icons.abc,
                          color: Colors.purple,
                          onTap: () {
                            context.go(Routes.chat);
                          },
                        ),
                        SkillCard(
                          title: "Tài liệu",
                          icon: Icons.book,
                          color: Colors.yellow,
                          onTap: () {
                            context.go(Routes.pdf);
                          },
                        ),
                        SkillCard(
                          title: "Từ vựng",
                          icon: Icons.abc,
                          color: Colors.purple,
                          onTap: () {
                            context.go(Routes.chat);
                          },
                        ),
                        SkillCard(
                          title: "Ngữ pháp",
                          icon: Icons.abc,
                          color: Colors.purple,
                          onTap: () {
                            context.go(Routes.chat);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }
}