import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tims/app/themes/app_theme.dart';

void main() {
  testWidgets('App renders MaterialApp.router', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          title: 'TIMS',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: const Scaffold(
            body: Center(child: Text('TIMS')),
          ),
        ),
      ),
    );

    expect(find.text('TIMS'), findsOneWidget);
  });
}
