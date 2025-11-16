import 'dart:typed_data';

import 'package:file_picker_ohos/src/utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:file_picker_ohos/file_picker_ohos.dart';

void main() {
  test('getFilePath', () async {
    final singleFile =
        PlatformFile(name: 'single.txt', path: '/path/to/single.txt', size: 20);
    final multipleFiles = [
      PlatformFile(name: 'one.txt', path: '/path/to/one.txt', size: 50),
      PlatformFile(name: 'two.txt', path: '/path/to/two.txt', size: 60)
    ];
    final singlePick = FilePickerResult([singleFile]);
    final multiPick = FilePickerResult(multipleFiles);
    expect(singlePick.isSinglePick, isTrue);
    expect(multiPick.isSinglePick, isFalse);
  });

  test('should return the correct number of files', () {
    final files = [
      PlatformFile(name: 'one.txt', path: '/path/to/one.txt', size: 60),
      PlatformFile(name: 'two.txt', path: '/path/to/two.txt', size: 60)
    ];
    final result = FilePickerResult(files);
    expect(result.count, equals(2));
  });

  test('should return the correct paths and names', () {
    final files = [
      PlatformFile(name: 'one.txt', path: '/path/to/one.txt', size: 20),
      PlatformFile(name: 'two.txt', path: '/path/to/two.txt', size: 30)
    ];
    final result = FilePickerResult(files);
    expect(result.paths, equals(['/path/to/one.txt', '/path/to/two.txt']));
    expect(result.names, equals(['one.txt', 'two.txt']));
  });

  test('should convert to XFile correctly', () {
    final files = [
      PlatformFile(name: 'one.txt', path: '/path/to/one.txt', size: 20),
      PlatformFile(name: 'two.txt', path: '/path/to/two.txt', size: 30)
    ];
    final result = FilePickerResult(files);
    expect(result.xFiles[0].path, equals('/path/to/one.txt'));
    expect(result.xFiles[1].path, equals('/path/to/two.txt'));
  });


  test('should correctly retrieve path and name', () {
    final file = PlatformFile(
      path: '/path/to/file.txt',
      name: 'file.txt',
      size: 1024,
    );
    expect(file.path, equals('/path/to/file.txt'));
    expect(file.name, equals('file.txt'));
    expect(file.extension, equals('txt'));
  });

  test('should correctly retrieve bytes and size', () {
    final bytes = Uint8List.fromList([1, 2, 3]);
    final file = PlatformFile(
      path: '/path/to/file.txt',
      name: 'file.txt',
      size: 3,
      bytes: bytes,
    );
    expect(file.bytes, equals(bytes));
    expect(file.size, equals(3));
  });

  test('toString should work as expected', () {
    final file = PlatformFile(
      path: '/path/to/file.txt',
      name: 'file.txt',
      size: 1024,
    );
    expect(file.toString(), equals('PlatformFile(path /path/to/file.txt, name: file.txt, bytes: null, readStream: null, size: 1024)'));
  });

  group('filePathsToPlatformFiles()', () {
    test(
        'should transform an empty list of file paths into an empty list of PlatformFiles',
            () async {
          final filePaths = <String>[];

          final platformFiles = await filePathsToPlatformFiles(
            filePaths,
            false,
            false,
          );

          expect(platformFiles.length, equals(filePaths.length));
        });

    test(
        'should tranform a list of file paths containing a path into a list of PlatformFiles',
            () async {
          final filePaths = <String>['test'];

          final platformFiles = await filePathsToPlatformFiles(
            filePaths,
            true,
            false,
          );

          expect(platformFiles.length, equals(filePaths.length));
        });

    test(
        'should transform a list of file paths containing a valid path into a list of PlatformFiles',
            () async {
          final filePaths = <String>['test/test_files/test.pdf'];

          final platformFiles = await filePathsToPlatformFiles(
            filePaths,
            false,
            true,
          );

          expect(platformFiles.length, equals(filePaths.length));
        });
  });

  group('runExecutableWithArguments()', () {
    test('should catch an exception when sending an empty filepath', () async {
      final filepath = '';

      expect(
            () async => await isExecutableOnPath(filepath),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('isAlpha()', () {
    test('should identify alpha chars', () async {
      expect(isAlpha('a'), equals(true));
      expect(isAlpha('A'), equals(true));
      expect(isAlpha('z'), equals(true));
      expect(isAlpha('Z'), equals(true));
      expect(isAlpha('.'), equals(false));
      expect(isAlpha('*'), equals(false));
      expect(isAlpha(' '), equals(false));
    });
  });
}
