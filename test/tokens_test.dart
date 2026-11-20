import 'package:battar_sanjibani/core/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<double> scaledAt(WidgetTester tester, double textScale) async {
    double? result;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Builder(
            builder: (context) {
              result = AppTokens.scaled(context, 40);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    return result!;
  }

  testWidgets('a fixed height grows with the system text scale',
      (tester) async {
    expect(await scaledAt(tester, 1.0), 40);
    expect(await scaledAt(tester, 1.3), closeTo(52, 0.001));
  });

  testWidgets('growth is capped so large fonts cannot break the layout',
      (tester) async {
    expect(await scaledAt(tester, 3.0), 64); // 40 * the 1.6 default cap
  });

  testWidgets('never shrinks below the base height', (tester) async {
    expect(await scaledAt(tester, 0.8), 40);
  });
}
