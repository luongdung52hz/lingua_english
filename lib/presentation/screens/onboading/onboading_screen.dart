import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/routes/route_names.dart';
import '../../widgets/app_button.dart'; // Giả sử bạn có route này
import '../../../resources/styles/colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingContents = [
    {
      'image': 'lib/resources/assets/images/onboarding1.png',
      'title': 'Học ngôn ngữ dễ dàng',
      'description': 'Phương pháp học hiện đại, vui vẻ và \nhiệu quả cao.',
    },
    {
      'image': 'lib/resources/assets/images/onboarding2.png',
      'title': 'Kết nối bạn bè & học cùng nhau',
      'description': 'Chat, chia sẻ tiến độ và động lực \ncùng cộng đồng',
    },
    {
      'image': 'lib/resources/assets/images/onboarding3.png',
      'title': 'Luyện 4 kỹ năng cùng AI',
      'description': 'Nghe, Nói, Đọc, Viết với trợ lý AI thông \nminh',
    },
    {
      'image': 'lib/resources/assets/images/onboarding4.png',
      'title': 'Ôn tập thông minh với Flashcard',
      'description': 'Học từ vựng hiệu quả và thuật toán \nlặp lại ngắt quãng.',
    },
    {
      'image': 'lib/resources/assets/images/onboarding5.png',
      'title': 'Theo dõi tiến độ & Đạt mục \ntiêu',
      'description':
          'Biểu đồ chi tiết, huy hiệu thành tích và \nđộng lực mỗi ngày',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            TextButton(
              onPressed: () => context.go(Routes.login),
              child: const Text('Bỏ qua', style: TextStyle(color: Colors.grey)),
            ),

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _onboardingContents.length,
                itemBuilder: (context, index) {
                  final content = _onboardingContents[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Ảnh
                        Image.asset(
                          content['image']!,
                          height: 240,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 40),
                        // Tiêu đề
                        Text(
                          content['title']!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                        ),
                        const SizedBox(height: 16),
                        // Mô tả
                        Text(
                          content['description']!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.grey),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Dots indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _onboardingContents.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.primary
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Nút chuyển trang hoặc bắt đầu
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      onPressed: _currentPage == _onboardingContents.length - 1
                          ? () => context.go(Routes.login)
                          : () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeIn,
                              );
                            },
                      text: _currentPage == _onboardingContents.length - 1
                          ? 'Bắt đầu '
                          : 'Tiếp tục',
                      // isLoading: false,
                      // height: 50,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
