import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          Image.asset(
            'lib/resources/assets/images/logo_2.png',
            height: 60,
            width: 60,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.image_not_supported, size: 20, color: Colors.white);
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Lingua",
              style: GoogleFonts.concertOne(
                fontSize: 24,
                fontWeight: FontWeight.w400,
                color: Colors.black26,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: actions ?? [ ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: const EdgeInsets.all(8),
        ),
        child: const Icon(Icons.notifications_none, color: Colors.grey,size: 26,),
      ),],
      backgroundColor: Colors.white,
      elevation: 0.5,
      shadowColor: Colors.black26,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}