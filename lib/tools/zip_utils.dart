import 'dart:io';

import 'package:archive/archive_io.dart' as archive;
import 'package:zip_flutter/zip_flutter.dart' as zip_flutter;

import '../foundation/platform_utils.dart';

abstract class ZipArchiveWriter {
  void addFile(String archivePath, String sourcePath);
  void close();
}

ZipArchiveWriter createZipWriter(String outputPath) {
  if (PlatformUtils.isOhos) {
    return _ArchiveZipWriter(outputPath);
  }
  return _ZipFlutterWriter(outputPath);
}

Future<void> extractZipFile(String zipFilePath, String destinationDir) async {
  if (PlatformUtils.isOhos) {
    final input = archive.InputFileStream(zipFilePath);
    try {
      final archive.Archive archiveData =
          archive.ZipDecoder().decodeBuffer(input);
      Directory(destinationDir).createSync(recursive: true);
      archive.extractArchiveToDisk(archiveData, destinationDir);
    } finally {
      input.close();
    }
    return;
  }
  zip_flutter.ZipFile.openAndExtract(zipFilePath, destinationDir);
}

class _ZipFlutterWriter implements ZipArchiveWriter {
  final zip_flutter.ZipFile _zipFile;

  _ZipFlutterWriter(String outputPath)
      : _zipFile = zip_flutter.ZipFile.open(outputPath);

  @override
  void addFile(String archivePath, String sourcePath) {
    _zipFile.addFile(archivePath, sourcePath);
  }

  @override
  void close() {
    _zipFile.close();
  }
}

class _ArchiveZipWriter implements ZipArchiveWriter {
  final archive.ZipFileEncoder _encoder = archive.ZipFileEncoder();

  _ArchiveZipWriter(String outputPath) {
    _encoder.create(outputPath);
  }

  @override
  void addFile(String archivePath, String sourcePath) {
    final file = File(sourcePath);
    if (!file.existsSync()) {
      throw FileSystemException("File not found", sourcePath);
    }
    _encoder.addFile(file, archivePath);
  }

  @override
  void close() {
    _encoder.close();
  }
}
