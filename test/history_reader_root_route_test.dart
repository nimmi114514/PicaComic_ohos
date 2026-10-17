import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pica_comic/foundation/app_page_route.dart';

const _homeKey = Key('main-pane');
const _sidebarKey = Key('sidebar');
const _readerKey = Key('fullscreen-reader');

void main() {
  for (final size in [
    const Size(400, 800),
    const Size(800, 1280),
    const Size(1200, 800),
  ]) {
    for (final coldStart in [true, false]) {
      testWidgets('widget reader uses root navigator at $size, cold=$coldStart',
          (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final root = GlobalKey<NavigatorState>();
        final nested = GlobalKey<NavigatorState>();
        final inset = size.width >= 1100
            ? 224.0
            : size.width >= 600
                ? 72.0
                : 0.0;

        await tester.pumpWidget(MaterialApp(
          navigatorKey: root,
          home: Row(
            key: _homeKey,
            children: [
              if (inset > 0) SizedBox(key: _sidebarKey, width: inset),
              Expanded(
                child: RouteDisplayInsets(
                  padding: EdgeInsets.only(left: inset),
                  child: Navigator(
                    key: nested,
                    onGenerateInitialRoutes: (_, __) => [
                      MaterialPageRoute<void>(
                        builder: (_) => const SizedBox(),
                      ),
                      if (coldStart)
                        AppPageRoute<void>(
                          builder: (_) => const _LaunchPage(),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ));
        await tester.pumpAndSettle();
        if (!coldStart) {
          nested.currentState!.push(AppPageRoute<void>(
            builder: (_) => const _LaunchPage(),
          ));
          await tester.pumpAndSettle();
        }

        await tester.tap(find.text('Open reader'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(tester.getRect(find.byKey(_readerKey)),
            Rect.fromLTWH(0, 0, size.width, size.height));
        expect(find.byKey(_sidebarKey), findsNothing);
        expect(find.byKey(_homeKey), findsNothing);
        expect(root.currentState!.canPop(), isTrue);
        expect(nested.currentState!.canPop(), isFalse);
        expect(
          ModalRoute.of(tester.element(find.byKey(_readerKey)))!.settings.name,
          '/ComicReadingPage',
        );

        tester.view.physicalSize = Size(size.height, size.width);
        await tester.pumpAndSettle();
        expect(tester.getRect(find.byKey(_readerKey)),
            Rect.fromLTWH(0, 0, size.height, size.width));

        root.currentState!.pop();
        await tester.pumpAndSettle();
        expect(find.byKey(_homeKey), findsOneWidget);
        expect(find.text('Open reader'), findsNothing);
        expect(nested.currentState!.canPop(), isFalse);
        expect(root.currentState!.canPop(), isFalse);
      });
    }
  }

  testWidgets('launching on root replaces the loader without adding a route',
      (tester) async {
    final root = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: root,
      home: const SizedBox(key: _homeKey),
    ));
    root.currentState!.push(AppPageRoute<void>(
      builder: (_) => const _LaunchPage(),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open reader'));
    await tester.pumpAndSettle();
    expect(find.byKey(_readerKey), findsOneWidget);
    root.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.byKey(_homeKey), findsOneWidget);
    expect(find.text('Open reader'), findsNothing);
    expect(root.currentState!.canPop(), isFalse);
  });
}

class _LaunchPage extends StatelessWidget {
  const _LaunchPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => replaceWithRootPage(
            context,
            (_) => const ColoredBox(key: _readerKey, color: Colors.black),
            settings: const RouteSettings(name: '/ComicReadingPage'),
          ),
          child: const Text('Open reader'),
        ),
      ),
    );
  }
}
