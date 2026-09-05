import 'package:flutter/material.dart';
import 'app/app.dart';
import 'app/bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final router = await bootstrap();
    runApp(MyApp(router: router));
  } catch (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(exception: error, stack: stack),
    );
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Không thể khởi động ứng dụng. Vui lòng thử mở lại.'),
          ),
        ),
      ),
    );
  }
}
