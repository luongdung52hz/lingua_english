import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart'; // Thêm import GetX cho reactive (Obx, Get.find)
import 'package:google_fonts/google_fonts.dart';
import '../../../controllers/home_controller.dart'; // Import HomeController để lấy userName (điều chỉnh đường dẫn nếu cần)
import '../../../../util/string_extensions.dart';
class AppBarHome extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget>? actions;

  const AppBarHome({
    super.key,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final homeCtrl = Get.find<HomeController>(); // Lấy instance từ GetX

    return AppBar(
      title: Obx(() => Row(
        children: [
          Image.asset(
            'lib/resources/assets/images/logo_L_final.png',
            height: 54,
            width: 54,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.image_not_supported, size: 20, color: Colors.white);
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              homeCtrl.userName.value.isEmpty ? "Lingua" : homeCtrl.userName.value.removeVietnameseTones(),
              style: GoogleFonts.concertOne(
                fontSize: 24,
                fontWeight: FontWeight.w400,
                color: Colors.black26,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      )),
      actions: actions ?? [
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            elevation: 0,
            padding: const EdgeInsets.all(8),
          ),
          child: const Icon(Icons.notifications_none, color: Colors.grey,size: 26,),
        ),
      ],
      backgroundColor: Colors.white,
      elevation: 0.5,
      shadowColor: Colors.black26,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}