import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kas_kecil/widgets/loading_widget.dart';

void main() {
  testWidgets('LoadingWidget displays message', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LoadingWidget(message: 'Memuat data...'),
        ),
      ),
    );

    expect(find.text('Memuat data...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
