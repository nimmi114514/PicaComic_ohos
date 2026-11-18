import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/network/update.dart';
import 'package:pica_comic/request/config/api_endpoints.dart';

void main() {
  const githubSources =
      'https://raw.githubusercontent.com/ccbkv/pica_configs/refs/heads/master/';
  const codebergSources =
      'https://codeberg.org/ccbkv/pica_configs/raw/branch/master/';

  late List<String> previousSettings;

  setUp(() {
    previousSettings = appdata.settings;
    appdata.settings = List.of(previousSettings);
  });

  tearDown(() => appdata.settings = previousSettings);

  void expectOhosEndpoints() {
    const repo = 'https://github.com/nimmi114514/PicaComic_ohos';
    const releases =
        'https://api.github.com/repos/nimmi114514/PicaComic_ohos/releases';
    expect(kProjectRepoUrl, repo);
    expect(kProjectIssuesUrl, '$repo/issues');
    expect(kProjectReleasesApiUrl, releases);
    expect(kProjectLatestReleaseApiUrl, '$releases/latest');
    expect(kProjectLatestReleaseUrl, '$repo/releases/latest');
    expect(ApiEndpoints.githubOwner, 'nimmi114514');
    expect(ApiEndpoints.githubRepo, 'PicaComic_ohos');
    expect(ApiEndpoints.projectUrl, repo);
    expect(ApiEndpoints.sourceUrl, repo);
    expect(ApiEndpoints.appReleases, releases);
    expect(ApiEndpoints.latestApp, '$releases/latest');
    expect(ApiEndpoints.latestAppMirror, '$releases/latest');
  }

  for (final useCodeberg in [false, true]) {
    test('OHOS updates stay on this fork with Codeberg=$useCodeberg', () {
      appdata.settings[105] = useCodeberg ? '1' : '0';
      expectOhosEndpoints();
      final sources = useCodeberg ? codebergSources : githubSources;
      expect(kComicSourceRepositoryUrl, sources);
      expect(resolveComicSourceUrl('${githubSources}ehentai.js'),
          '${sources}ehentai.js');
      expect(resolveComicSourceUrl('${codebergSources}ehentai.js'),
          '${sources}ehentai.js');
      const customSource = 'https://example.com/my-source.js';
      expect(resolveComicSourceUrl(customSource), customSource);
      final help = Uri.parse(kComicSourceHelpUrl);
      expect(help.host, useCodeberg ? 'codeberg.org' : 'github.com');
      expect(
          help.path,
          useCodeberg
              ? '/ccbkv/PicaComic/src/branch/master/doc/comic_source.md'
              : '/nimmi114514/PicaComic_ohos/blob/master/doc/comic_source.md');
      expect(Uri.parse(kHtApiListUrl).host,
          useCodeberg ? 'codeberg.org' : 'raw.githubusercontent.com');
    });
  }

  test('pre-5.0.5 settings default to GitHub source hosting', () {
    appdata.settings = appdata.settings.take(105).toList();
    expectOhosEndpoints();
    expect(kComicSourceRepositoryUrl, githubSources);
    expect(resolveComicSourceUrl('${codebergSources}ehentai.js'),
        '${githubSources}ehentai.js');
  });

  test('OHOS release versions match and increase the existing build number',
      () {
    final manifest =
        jsonDecode(File('ohos/AppScope/app.json5').readAsStringSync())
            as Map<String, dynamic>;
    final app = manifest['app'] as Map<String, dynamic>;
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(appVersion, '5.1.1');
    expect(ApiEndpoints.version, appVersion);
    expect(app['versionName'], appVersion);
    expect(app['versionCode'], 46322);
    expect(RegExp(r'^version: (.+)$', multiLine: true).firstMatch(pubspec)![1],
        '${app['versionName']}+${app['versionCode']}');
  });
}
