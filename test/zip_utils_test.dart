import 'dart:io';

import 'package:archive/archive.dart' as archive;
import 'package:flutter_test/flutter_test.dart';
import 'package:pica_comic/utils/zip_utils.dart';

void main() {
  late Directory temporary;

  setUp(() {
    temporary = Directory.systemTemp.createTempSync('pica-archive-test-');
  });

  tearDown(() async {
    await temporary.delete(recursive: true);
  });

  String writeArchive(Map<String, List<int>> files) {
    final contents = archive.Archive();
    for (final entry in files.entries) {
      contents.addFile(
          archive.ArchiveFile(entry.key, entry.value.length, entry.value));
    }
    final input = File('${temporary.path}/input.zip');
    input.writeAsBytesSync(archive.ZipEncoder().encode(contents)!);
    return input.path;
  }

  test('portable writer works without the native zip plugin', () async {
    final source = File('${temporary.path}/page.jpg')
      ..writeAsBytesSync([1, 2, 3]);
    final output = '${temporary.path}/output.zip';
    final writer = createPortableZipWriter(output);
    writer.addFile('chapter/1.jpg', source.path);
    writer.close();

    final contents = archive.ZipDecoder().decodeBytes(
      await File(output).readAsBytes(),
      verify: true,
    );
    expect(contents.single.name, 'chapter/1.jpg');
    expect(contents.single.content, [1, 2, 3]);
  });

  test('script archives flatten images in natural page order', () async {
    final input = writeArchive({
      'chapter/10.jpg': [10],
      'chapter/2.jpg': [2],
      '__MACOSX/._2.jpg': [0],
      'readme.txt': [0],
    });
    final output = '${temporary.path}/pages';
    expect(await extractComicArchive([input, output]), 2);
    expect(await File('$output/0.jpg').readAsBytes(), [2]);
    expect(await File('$output/1.jpg').readAsBytes(), [10]);
  });

  test('script archives reject path traversal before creating output', () async {
    final input = writeArchive({'../outside.jpg': [1]});
    final output = '${temporary.path}/pages';
    await expectLater(
      extractComicArchive([input, output]),
      throwsFormatException,
    );
    expect(Directory(output).existsSync(), isFalse);
  });

  test('script archives reject archives without comic images', () async {
    final input = writeArchive({'readme.txt': [1]});
    await expectLater(
      extractComicArchive([input, '${temporary.path}/pages']),
      throwsFormatException,
    );
  });
}
