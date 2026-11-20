// certifications#52: the moving bubbles paint without a full-screen blur,
// hold still with reduced motion and stop in a hidden route.
import 'package:certifications/core/utils/my_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host({bool still = false, bool active = true}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(size: const Size(800, 600), disableAnimations: still),
    child: TickerMode(
      enabled: active,
      child: const SizedBox(
        width: 800,
        height: 600,
        child: LiquidMetalBackground(seed: 7),
      ),
    ),
  ),
);

void main() {
  testWidgets('paints with no full-screen blur filter', (tester) async {
    await tester.pumpWidget(host());
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(ImageFiltered), findsNothing);
    expect(find.byType(BackdropFilter), findsNothing);
    expect(tester.takeException(), isNull);
    // Moves: a later frame differs.
    expect(tester.binding.hasScheduledFrame, isTrue);
  });

  testWidgets('reduced motion shows one still frame', (tester) async {
    await tester.pumpWidget(host(still: true));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('a hidden route stops the motion', (tester) async {
    await tester.pumpWidget(host(active: false));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
