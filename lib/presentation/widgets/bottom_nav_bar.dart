import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../app/routes/route_names.dart';
import '../../../resources/styles/colors.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 1,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go(Routes.home);
              break;
            case 1:
              context.go(Routes.learn);
              break;
            case 2:
              context.go(Routes.flashcards);
              break;
            case 3:
              context.go(Routes.chat);
              break;
            case 4:
              context.go(Routes.profile);
              break;
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: _CustomNavIcon(
              index: 0,
              currentIndex: currentIndex,
              svgPath: 'lib/resources/assets/icons/home.svg',
            ),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: _CustomNavIcon(
              index: 1,
              currentIndex: currentIndex,
              svgPath: 'lib/resources/assets/icons/education.svg',
            ),
            label: "Learn",
          ),
          BottomNavigationBarItem(
            icon: _CustomNavIcon(
              index: 2,
              currentIndex: currentIndex,
              svgPath: 'lib/resources/assets/icons/flash-cards.svg',
            ),
            label: "Flashcard",
          ),
          BottomNavigationBarItem(
            icon: _CustomNavIcon(
              index: 3,
              currentIndex: currentIndex,
              svgPath: 'lib/resources/assets/icons/chat.svg',
            ),
            label: "Chat",
          ),
          BottomNavigationBarItem(
            icon: _CustomNavIcon(
              index: 4,
              currentIndex: currentIndex,
              svgPath: 'lib/resources/assets/icons/user.svg',
            ),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}

class _CustomNavIcon extends StatelessWidget {
  final int index;
  final int currentIndex;
  final String svgPath;

  const _CustomNavIcon({
    required this.index,
    required this.currentIndex,
    required this.svgPath,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = index == currentIndex;
    final Color iconColor = isSelected ? AppColors.primary : Colors.grey;
    final Color bgColor = isSelected ? Colors.white : Colors.transparent;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(13),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),  // Bóng nổi dưới
              ),
            ]
                : null,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              svgPath,
              height: 22,
              width: 22,
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
            ),

          ],
        ),
      ],
    );
  }
}