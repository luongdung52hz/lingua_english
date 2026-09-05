import 'package:flutter/material.dart';

/// Uses the app's ScaffoldMessenger, independently of the navigation package.
class AppFeedback {
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  static void show(
    String title,
    String message, {
    Duration duration = const Duration(seconds: 3),
    Color? backgroundColor,
    Color? colorText,
    EdgeInsets? margin,
  }) {
    final messenger = messengerKey.currentState;
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('$title: $message', style: TextStyle(color: colorText)),
        duration: duration,
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: margin,
      ),
    );
  }
}
