import 'dart:io';

bool isOhosPlatform() {
  try {
    final os = Platform.operatingSystem.toLowerCase();
    if (os == 'ohos' || os == 'openharmony') {
      return true;
    }
    final version = Platform.operatingSystemVersion.toLowerCase();
    if (version.contains('openharmony') || version.contains('ohos')) {
      return true;
    }
  } catch (_) {
    // Platform information not available on this runtime.
  }
  return false;
}
