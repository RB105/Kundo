import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kundo/widgets/ios_ui.dart';

/// A pushed page shaped like the app's screens: a large-title bar over a list.
Widget listPage() {
  return NavBarScrollScope(
    child: CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: <Widget>[
          const CupertinoSliverNavigationBar(largeTitle: Text('Work')),
          SliverList.list(
            children: <Widget>[
              for (int i = 0; i < 40; i++)
                SizedBox(height: 60, child: Text('Task $i')),
            ],
          ),
        ],
      ),
    ),
  );
}

Future<void> openListPage(WidgetTester tester) async {
  // Portrait: the large title (and its snapping) only exists there.
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(CupertinoApp(
    home: Builder(
      builder: (BuildContext context) => CupertinoButton(
        child: const Text('Open'),
        onPressed: () => Navigator.of(context).push(
          CupertinoPageRoute<void>(builder: (_) => listPage()),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

/// Scrolls by 40, into the large title's snap zone (0–52), and lets go at
/// rest, so the bar starts snapping the title shut.
Future<void> releaseHalfCollapsed(WidgetTester tester) async {
  final TestGesture scroll =
      await tester.startGesture(tester.getCenter(find.text('Task 3')));
  await scroll.moveBy(const Offset(0, -20)); // past the touch slop
  await scroll.moveBy(const Offset(0, -40));
  await tester.pump(const Duration(milliseconds: 300));
  await scroll.up();
  await tester.pump();
}

ScrollPosition listPosition(WidgetTester tester) =>
    tester.state<ScrollableState>(find.byType(Scrollable).last).position;

void main() {
  testWidgets('back swipe while the large title snaps does not throw',
      (WidgetTester tester) async {
    await openListPage(tester);
    await releaseHalfCollapsed(tester);
    await tester.pump(const Duration(milliseconds: 16));

    // Mid-snap, swipe back from the left edge. Without NavBarScrollScope this
    // fails Scrollable's '_hold == null' assertion.
    final TestGesture back = await tester.startGesture(const Offset(5, 500));
    await back.moveBy(const Offset(60, 0));
    await back.moveBy(const Offset(60, 0));
    await back.up();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('the large title still snaps when let go half collapsed',
      (WidgetTester tester) async {
    await openListPage(tester);
    await releaseHalfCollapsed(tester);
    await tester.pumpAndSettle();

    expect(listPosition(tester).pixels, moreOrLessEquals(52));
  });
}
