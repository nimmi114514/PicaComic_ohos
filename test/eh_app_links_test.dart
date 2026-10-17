import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/foundation/comic_source/comic_source.dart';
import 'package:pica_comic/pages/comic_page.dart';
import 'package:pica_comic/utils/app_links.dart';

void main() {
  late List<ComicSource> previousSources;
  late GlobalKey<NavigatorState>? previousMainNavigatorKey;

  setUp(() {
    previousSources = ComicSource.sources;
    previousMainNavigatorKey = App.mainNavigatorKey;
    App.mainNavigatorKey = null;
    ComicSource.sources = [
      ComicSource.named(
        name: 'EH test source',
        key: 'ehentai',
        filePath: 'ehentai-test.js',
        comicPageBuilder: (_, id, __) => Scaffold(body: Text(id)),
      ),
    ];
  });

  tearDown(() {
    ComicSource.sources = previousSources;
    App.mainNavigatorKey = previousMainNavigatorKey;
  });

  for (final host in ['e-hentai.org', 'exhentai.org']) {
    for (final suffix in ['', '/', '/?p=2#comments']) {
      testWidgets('opens $host gallery with suffix "$suffix" unchanged',
          (tester) async {
        await tester.pumpWidget(MaterialApp(
          navigatorKey: App.navigatorKey,
          home: const Scaffold(),
        ));

        final url = 'https://$host/g/123456/00aBcD0123$suffix';
        expect(canHandle(url), isTrue);
        // EH IDs are gallery URLs, not IDs to convert using a source's domain.
        // No JS runtime is initialized: this path must use the validated URL.
        expect(
          handleAppLinks(Uri.parse(url), showMessageWhenError: false),
          isTrue,
        );
        await tester.pumpAndSettle();

        final page = tester.widget<ComicPage>(find.byType(ComicPage));
        expect(page.sourceKey, 'ehentai');
        expect(page.id, 'https://$host/g/123456/00aBcD0123/');
        expect(find.text(page.id), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  testWidgets('rejects malformed EH gallery paths without opening a page',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      navigatorKey: App.navigatorKey,
      home: const Scaffold(),
    ));
    for (final path in [
      '/g/123456/',
      '/g/not-a-number/abcdef0123/',
      '/g/123456/abcdef0123/extra',
    ]) {
      expect(
        handleAppLinks(
          Uri.parse('https://exhentai.org$path'),
          showMessageWhenError: false,
        ),
        isFalse,
      );
    }
    await tester.pumpAndSettle();
    expect(find.byType(ComicPage), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
