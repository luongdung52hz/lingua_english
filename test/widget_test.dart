import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:learn_english/app/app.dart';

void main() {
  testWidgets('UI root accepts a router without initializing Firebase', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Lingua ready')),
        ),
      ],
    );
    await tester.pumpWidget(MyApp(router: router));
    await tester.pumpAndSettle();
    expect(find.text('Lingua ready'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
  });
}
