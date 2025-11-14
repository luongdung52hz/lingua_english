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
    homeCtrl.loadUserProgress();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const AppBarHome(),
      body: RefreshIndicator(
        onRefresh: () async {
          await homeCtrl.loadUserProgress();
        },
        color: Colors.blue,
        child: StreamBuilder<DocumentSnapshot>(
          stream: firestore.collection('users').doc(homeCtrl.userId).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'Lỗi load data: Kiểm tra kết nối',
                  style: TextStyle(color: Colors.red),
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
            final progressPercent = (data['progress'] ?? 0).toDouble();
            final completedLessons = data['completedLessons'] ?? 0;
            final totalLessons = data['totalLessons'] ?? 5;
            final score = data['score'] ?? 0;
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  // Continue Study Card
                  Transform.translate(
                    offset: const Offset(0, -16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ContinueStudyWidget(
                        onContinueTap: () {
                          context.go(Routes.learn);
                        },
                      ),
                    ),
                  ),
                  // Quick Features Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Tính năng nhanh",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Grid Features
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1,
                          children: [
                            _buildFeatureCard(
                              title: "Flashcard",
                              icon: Icons.style_outlined,
                              color: Colors.orange.shade200,
                              onTap: () => context.go(Routes.flashcards),
                            ),
                            _buildFeatureCard(
                              title: "AI Chat",
                              icon: Icons.mic_rounded,
                              color: Colors.red.shade200,
                              onTap: () => context.go(Routes.profile),
                            ),
                            _buildFeatureCard(
                              title: "4 Skill",
                              icon: Icons.menu_book_rounded,
                              color: Colors.blue.shade200,
                              onTap: () => context.go(Routes.learn),
                            ),
                            _buildFeatureCard(
                              title: "Friend",
                              icon: Icons.chat_rounded,
                              color: Colors.green.shade200,
                              onTap: () => context.go(Routes.chat),
                            ),
                            _buildFeatureCard(
                              title: "Ngữ pháp",
                              icon: Icons.abc_rounded,
                              color: Colors.purple.shade200,
                              onTap: () => context.go(Routes.chat),
                            ),
                            _buildFeatureCard(
                              title: "Quiz",
                              icon: Icons.quiz_rounded,
                              color: Colors.amber.shade200,
                              onTap: () => context.go(Routes.quiz),
                            ),
                            // Thêm: YouTube Feature Card
                            _buildFeatureCard(
                              title: "YouTube",
                              icon: Icons.play_circle_outline,
                              color: Colors.teal.shade200,
                              onTap: () => context.go(Routes.youtubeChannels),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
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

  Widget _buildFeatureCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}