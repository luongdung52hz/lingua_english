import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/feedback/app_feedback.dart';
import 'config/app.theme.dart';
import 'config/app_constants.dart';
import 'localization/app_localizations.dart';

/// The UI root has no Firebase or service-locator initialization.
class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.router});
  final GoRouter router;

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: AppConstants.appName,
    scaffoldMessengerKey: AppFeedback.messengerKey,
    theme: AppTheme.lightTheme,
    locale: const Locale('vi'),
    supportedLocales: const [Locale('en'), Locale('vi')],
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    routerConfig: router,
  );
}
