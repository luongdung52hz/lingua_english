import 'package:flutter/material.dart';

class AppBarHome extends StatelessWidget implements PreferredSizeWidget {
  const AppBarHome({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      shadowColor: Colors.black26,
      centerTitle: false,
      titleSpacing: 10,
      title: Image.asset(
        'lib/resources/assets/images/logo_L_final.png',
        height:70,
        width: 70,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.image_not_supported, size: 32, color: Colors.grey);
        },
      ),

    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
