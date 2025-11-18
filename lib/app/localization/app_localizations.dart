import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
//import 'l10n/messages_all.dart'; // nếu dùng intl generated

class AppLocalizations {
  static const localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const supportedLocales = [
    Locale('en'),
    Locale('vi'),
  ];
}